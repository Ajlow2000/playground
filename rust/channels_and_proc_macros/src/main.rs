use tokio::sync::mpsc;

use crate::connect::Connect;
use crate::read_data::ReadData;
use crate::task::spawn_task;

#[tokio::main]
async fn main() {
    let (connect_rx, connect_handle) = spawn_task(Connect {
        peripheral_id: "AA:BB:CC:DD:EE:FF".into(),
    });
    print_all(connect_rx).await;

    let connection = match connect_handle.await {
        Ok(Ok(conn)) => conn,
        Ok(Err(e)) => {
            eprintln!("{e}");
            return;
        }
        Err(e) => {
            eprintln!("connect task panicked: {e}");
            return;
        }
    };

    let (read_rx, read_handle) = spawn_task(ReadData::new(connection));
    print_all(read_rx).await;
    let _ = read_handle.await;
}

async fn print_all<M: std::fmt::Display + Send + 'static>(mut rx: mpsc::Receiver<M>) {
    while let Some(msg) = rx.recv().await {
        println!("{msg}");
    }
}

mod task {
    use async_trait::async_trait;
    use tokio::sync::mpsc;
    use tokio::task::JoinHandle;

    #[async_trait]
    pub trait ProgressReporter: Send + Sync + 'static {
        type Message: Send + 'static;
        async fn send(&self, msg: Self::Message);
    }

    #[async_trait]
    pub trait BackgroundTask: Send + 'static {
        type Message: Send + 'static;
        type Output: Send + 'static;
        async fn run<R>(self, reporter: R) -> Self::Output
        where
            R: ProgressReporter<Message = Self::Message>;
    }

    pub struct MpscReporter<M> {
        tx: mpsc::Sender<M>,
    }

    #[async_trait]
    impl<M: Send + 'static> ProgressReporter for MpscReporter<M> {
        type Message = M;
        async fn send(&self, msg: M) {
            let _ = self.tx.send(msg).await;
        }
    }

    pub fn spawn_task<T: BackgroundTask>(
        task: T,
    ) -> (mpsc::Receiver<T::Message>, JoinHandle<T::Output>) {
        let (tx, rx) = mpsc::channel(10);
        let handle = tokio::spawn(task.run(MpscReporter { tx }));
        (rx, handle)
    }
}

mod connect {
    use std::fmt;
    use std::time::Duration;

    use async_trait::async_trait;
    use tokio::time::sleep;

    use crate::task::{BackgroundTask, ProgressReporter};

    pub struct Connection {
        pub peripheral_id: String,
    }

    #[derive(Debug)]
    #[allow(dead_code)]
    pub struct ConnectError(pub String);

    impl fmt::Display for ConnectError {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            write!(f, "connect failed: {}", self.0)
        }
    }

    impl std::error::Error for ConnectError {}

    pub enum ConnectMsg {
        Scanning,
        Found,
        NegotiatingMtu,
        Connected,
    }

    impl fmt::Display for ConnectMsg {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            match self {
                ConnectMsg::Scanning => write!(f, "\tscanning..."),
                ConnectMsg::Found => write!(f, "\tperipheral found"),
                ConnectMsg::NegotiatingMtu => write!(f, "\tnegotiating MTU..."),
                ConnectMsg::Connected => write!(f, "\tconnected"),
            }
        }
    }

    pub struct Connect {
        pub peripheral_id: String,
    }

    #[async_trait]
    impl BackgroundTask for Connect {
        type Message = ConnectMsg;
        type Output = Result<Connection, ConnectError>;

        async fn run<R>(self, reporter: R) -> Self::Output
        where
            R: ProgressReporter<Message = Self::Message>,
        {
            reporter.send(ConnectMsg::Scanning).await;
            sleep(Duration::from_secs(1)).await;
            reporter.send(ConnectMsg::Found).await;
            sleep(Duration::from_secs(1)).await;
            reporter.send(ConnectMsg::NegotiatingMtu).await;
            sleep(Duration::from_millis(500)).await;
            reporter.send(ConnectMsg::Connected).await;
            Ok(Connection {
                peripheral_id: self.peripheral_id,
            })
        }
    }
}

mod read_data {
    use std::fmt;
    use std::time::Duration;

    use async_trait::async_trait;
    use tokio::time::sleep;

    use crate::connect::Connection;
    use crate::task::{BackgroundTask, ProgressReporter};

    pub enum ReadDataMsg {
        Started(String),
        Chunk(Vec<u8>),
        Done,
    }

    impl fmt::Display for ReadDataMsg {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
            match self {
                ReadDataMsg::Started(id) => write!(f, "\treading from {id}"),
                ReadDataMsg::Chunk(bytes) => write!(f, "\tchunk: {bytes:?}"),
                ReadDataMsg::Done => write!(f, "read complete"),
            }
        }
    }

    pub struct ReadData {
        connection: Connection,
    }

    impl ReadData {
        pub fn new(connection: Connection) -> Self {
            Self { connection }
        }
    }

    #[async_trait]
    impl BackgroundTask for ReadData {
        type Message = ReadDataMsg;
        type Output = ();

        async fn run<R>(self, reporter: R) -> Self::Output
        where
            R: ProgressReporter<Message = Self::Message>,
        {
            reporter
                .send(ReadDataMsg::Started(self.connection.peripheral_id))
                .await;
            for i in 0..3u8 {
                sleep(Duration::from_millis(400)).await;
                reporter.send(ReadDataMsg::Chunk(vec![i; 4])).await;
            }
            reporter.send(ReadDataMsg::Done).await;
        }
    }
}
