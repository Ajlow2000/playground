pub mod commands;

use std::collections::VecDeque;

use crossterm::event::KeyEvent;
use ratatui::Frame;
use ratatui::layout::{Constraint, Layout, Rect};
use ratatui::style::{Color, Style};
use ratatui::text::Line;
use ratatui::widgets::{Block, Borders, Paragraph, Wrap};
use ratatui_textarea::{Input, TextArea};

use crate::app::Command;

const SCROLLBACK_CAP: usize = 1000;

pub struct ReplModel {
    pub textarea: TextArea<'static>,
    pub scrollback: VecDeque<Line<'static>>,
    pub scroll_offset: u16,
    pub last_visible_height: u16,
}

impl Default for ReplModel {
    fn default() -> Self {
        let mut textarea = TextArea::default();
        textarea.set_block(Block::default().borders(Borders::ALL).title("input"));
        let mut scrollback = VecDeque::with_capacity(SCROLLBACK_CAP);
        scrollback.push_back(Line::from(
            "Type `help` for available commands. Tab switches to logs.",
        ));
        Self {
            textarea,
            scrollback,
            scroll_offset: 0,
            last_visible_height: 0,
        }
    }
}

pub enum ReplMessage {
    KeyInput(KeyEvent),
    Submit,
    ScrollUp,
    ScrollDown,
}

pub fn update(model: &mut ReplModel, msg: ReplMessage) -> Option<Command> {
    match msg {
        ReplMessage::KeyInput(key) => {
            let input: Input = key.into();
            model.textarea.input(input);
            None
        }
        ReplMessage::Submit => {
            let line = model.textarea.lines().join("");
            push_line(model, Line::from(format!("> {line}")));
            let cmd = if !line.trim().is_empty() {
                let c = commands::dispatch(&line, &mut model.scrollback);
                trim_scrollback(model);
                c
            } else {
                None
            };
            reset_textarea(&mut model.textarea);
            model.scroll_offset = 0;
            cmd
        }
        ReplMessage::ScrollUp => {
            let step = half_page_step(model);
            model.scroll_offset = model.scroll_offset.saturating_add(step);
            None
        }
        ReplMessage::ScrollDown => {
            let step = half_page_step(model);
            model.scroll_offset = model.scroll_offset.saturating_sub(step);
            None
        }
    }
}

fn half_page_step(model: &ReplModel) -> u16 {
    (model.last_visible_height / 2).max(1)
}

fn push_line(model: &mut ReplModel, line: Line<'static>) {
    model.scrollback.push_back(line);
    trim_scrollback(model);
}

fn trim_scrollback(model: &mut ReplModel) {
    while model.scrollback.len() > SCROLLBACK_CAP {
        model.scrollback.pop_front();
    }
}

fn reset_textarea(ta: &mut TextArea<'static>) {
    let mut fresh = TextArea::default();
    fresh.set_block(Block::default().borders(Borders::ALL).title("input"));
    *ta = fresh;
}

pub fn view(model: &mut ReplModel, frame: &mut Frame, area: Rect) {
    let [scrollback_area, input_area] =
        Layout::vertical([Constraint::Min(1), Constraint::Length(3)]).areas(area);

    let lines: Vec<Line> = model.scrollback.iter().cloned().collect();
    let total = lines.len() as u16;
    let visible = scrollback_area.height.saturating_sub(2);
    model.last_visible_height = visible;
    let max_offset = total.saturating_sub(visible);
    model.scroll_offset = model.scroll_offset.min(max_offset);
    let offset = max_offset - model.scroll_offset;

    let scrollback = Paragraph::new(lines)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("scrollback")
                .border_style(Style::default().fg(Color::DarkGray)),
        )
        .wrap(Wrap { trim: false })
        .scroll((offset, 0));
    frame.render_widget(scrollback, scrollback_area);
    frame.render_widget(&model.textarea, input_area);
}
