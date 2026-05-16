use crossterm::event::{Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};

use crate::app::{Message, Model, Screen};
use crate::screens::logs::LogsMessage;
use crate::screens::repl::ReplMessage;

pub fn map_event(event: Event, model: &Model) -> Option<Message> {
    match event {
        Event::Key(key) if key.kind == KeyEventKind::Press => Some(map_key(key, model)?),
        Event::Resize(_, _) => Some(Message::Tick),
        _ => None,
    }
}

fn map_key(key: KeyEvent, model: &Model) -> Option<Message> {
    if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
        return Some(Message::Quit);
    }
    if key.code == KeyCode::Tab {
        return Some(Message::SwitchScreen);
    }
    match model.active {
        Screen::Repl => map_repl_key(key),
        Screen::Logs => map_logs_key(key),
    }
}

fn map_repl_key(key: KeyEvent) -> Option<Message> {
    if key.modifiers.contains(KeyModifiers::CONTROL) {
        match key.code {
            KeyCode::Char('u') => return Some(Message::Repl(ReplMessage::ScrollUp)),
            KeyCode::Char('d') => return Some(Message::Repl(ReplMessage::ScrollDown)),
            _ => {}
        }
    }
    match key.code {
        KeyCode::Enter => Some(Message::Repl(ReplMessage::Submit)),
        _ => Some(Message::Repl(ReplMessage::KeyInput(key))),
    }
}

fn map_logs_key(key: KeyEvent) -> Option<Message> {
    use tui_logger::TuiWidgetEvent::*;
    let evt = match key.code {
        KeyCode::Char('q') => return Some(Message::Quit),
        KeyCode::Up => UpKey,
        KeyCode::Down => DownKey,
        KeyCode::Left => LeftKey,
        KeyCode::Right => RightKey,
        KeyCode::PageUp => PrevPageKey,
        KeyCode::PageDown => NextPageKey,
        KeyCode::Char('+') => PlusKey,
        KeyCode::Char('-') => MinusKey,
        KeyCode::Char(' ') => SpaceKey,
        KeyCode::Char('h') => HideKey,
        KeyCode::Char('f') => FocusKey,
        KeyCode::Esc => EscapeKey,
        _ => return None,
    };
    Some(Message::Logs(LogsMessage::WidgetEvent(evt)))
}
