use crate::background_thing::Message;


#[tokio::main]
async fn main() {
    let mut rx = background_thing::spawn_background_thing().await;

    while let Some(msg) = rx.recv().await {
        match msg {
            Message::ProgressUpdate(id) => println!("\tupdate msg from task {id}"),
            Message::Complete => println!("task complete"),
        }
    }

}

mod background_thing {
    use std::sync::atomic::{AtomicU64, Ordering};
    use std::time::Duration;

    use tokio::sync::mpsc;
    use tokio::time::sleep;

    static NEXT_TASK_ID: AtomicU64 = AtomicU64::new(0);

    pub enum Message {
        ProgressUpdate(u64),
        Complete,
    }

    pub async fn spawn_background_thing() -> mpsc::Receiver<Message>{
        let (tx, rx) = mpsc::channel(10);
        let task_id = NEXT_TASK_ID.fetch_add(1, Ordering::Relaxed);

        tokio::spawn(do_background_thing(task_id, tx));

        rx
    }

    async fn do_background_thing(task_id: u64, tx: mpsc::Sender<Message>) {
        let inner_tx = tx.clone();
        let _ = tokio::time::timeout(Duration::from_secs(10), async move {
            loop {
                let _ = inner_tx.send(Message::ProgressUpdate(task_id)).await;
                sleep(Duration::from_secs(1)).await;
                continue
            }
        })
        .await;

        let _ = tx.send(Message::Complete).await;
    }
}

