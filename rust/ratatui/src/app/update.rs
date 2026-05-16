use crate::app::{Command, Message, Model};
use crate::screens::{logs, repl};

pub fn update(model: &mut Model, msg: Message) -> Option<Command> {
    let cmd = match msg {
        Message::Quit => Some(Command::Quit),
        Message::SwitchScreen => {
            model.active = model.active.toggle();
            None
        }
        Message::Tick => None,
        Message::Repl(m) => repl::update(&mut model.repl, m),
        Message::Logs(m) => {
            logs::update(&mut model.logs, m);
            None
        }
    };
    if let Some(Command::Quit) = cmd {
        model.should_quit = true;
    }
    cmd
}
