use crate::screens::logs::LogsMessage;
use crate::screens::repl::ReplMessage;

pub enum Message {
    Quit,
    SwitchScreen,
    Tick,
    Repl(ReplMessage),
    Logs(LogsMessage),
}

pub enum Command {
    Quit,
}
