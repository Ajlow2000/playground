mod app;
mod screens;

use std::time::Duration;

use crossterm::event;
use ratatui::DefaultTerminal;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

use crate::app::{Message, Model, input, update, view};

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    tui_logger::init_logger(log::LevelFilter::Trace).expect("tui-logger init");
    tui_logger::set_default_level(log::LevelFilter::Trace);
    tracing_subscriber::registry()
        .with(tui_logger::TuiTracingSubscriberLayer)
        .init();

    tracing::info!("starting ratatui playground");

    let result = ratatui::run(run_app);
    Ok(result?)
}

fn run_app(terminal: &mut DefaultTerminal) -> std::io::Result<()> {
    let mut model = Model::default();
    while !model.should_quit {
        terminal.draw(|f| view(&mut model, f))?;
        if event::poll(Duration::from_millis(100))? {
            if let Some(msg) = input::map_event(event::read()?, &model) {
                update(&mut model, msg);
            }
        } else {
            update(&mut model, Message::Tick);
        }
    }
    Ok(())
}
