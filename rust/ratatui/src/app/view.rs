use ratatui::Frame;
use ratatui::layout::{Constraint, Layout};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Tabs;

use crate::app::{Model, Screen};
use crate::screens::{logs, repl};

pub fn view(model: &mut Model, frame: &mut Frame) {
    let [tabs_area, body] =
        Layout::vertical([Constraint::Length(1), Constraint::Min(0)]).areas(frame.area());

    let titles: Vec<Line> = [Screen::Repl, Screen::Logs]
        .iter()
        .map(|s| {
            Line::from(Span::styled(
                format!(" {} ", s.title()),
                Style::default().fg(Color::Gray),
            ))
        })
        .collect();
    let selected = match model.active {
        Screen::Repl => 0,
        Screen::Logs => 1,
    };
    let tabs = Tabs::new(titles)
        .select(selected)
        .highlight_style(
            Style::default()
                .fg(Color::Black)
                .bg(Color::Cyan)
                .add_modifier(Modifier::BOLD),
        )
        .divider(" ");
    frame.render_widget(tabs, tabs_area);

    match model.active {
        Screen::Repl => repl::view(&mut model.repl, frame, body),
        Screen::Logs => logs::view(&model.logs, frame, body),
    }
}
