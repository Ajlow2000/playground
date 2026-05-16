use crate::screens::logs::LogsModel;
use crate::screens::repl::ReplModel;

#[derive(Default)]
pub struct Model {
    pub active: Screen,
    pub repl: ReplModel,
    pub logs: LogsModel,
    pub should_quit: bool,
}

#[derive(Default, Clone, Copy, PartialEq, Eq)]
pub enum Screen {
    #[default]
    Repl,
    Logs,
}

impl Screen {
    pub fn toggle(self) -> Self {
        match self {
            Screen::Repl => Screen::Logs,
            Screen::Logs => Screen::Repl,
        }
    }

    pub fn title(self) -> &'static str {
        match self {
            Screen::Repl => "repl",
            Screen::Logs => "logs",
        }
    }
}
