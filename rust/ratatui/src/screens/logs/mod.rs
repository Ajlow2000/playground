use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Color, Style};
use tui_logger::{TuiLoggerLevelOutput, TuiLoggerSmartWidget, TuiWidgetEvent, TuiWidgetState};

pub struct LogsModel {
    pub widget_state: TuiWidgetState,
}

impl Default for LogsModel {
    fn default() -> Self {
        Self {
            widget_state: TuiWidgetState::new().set_default_display_level(log::LevelFilter::Trace),
        }
    }
}

pub enum LogsMessage {
    WidgetEvent(TuiWidgetEvent),
}

pub fn update(model: &mut LogsModel, msg: LogsMessage) {
    match msg {
        LogsMessage::WidgetEvent(evt) => model.widget_state.transition(evt),
    }
}

pub fn view(model: &LogsModel, frame: &mut Frame, area: Rect) {
    let widget = TuiLoggerSmartWidget::default()
        .state(&model.widget_state)
        .output_separator('·')
        .output_timestamp(Some("%H:%M:%S%.3f".to_string()))
        .output_level(Some(TuiLoggerLevelOutput::Long))
        .output_target(true)
        .output_file(false)
        .output_line(false)
        .style_error(Style::default().fg(Color::Red))
        .style_warn(Style::default().fg(Color::Yellow))
        .style_info(Style::default().fg(Color::Cyan))
        .style_debug(Style::default().fg(Color::Green))
        .style_trace(Style::default().fg(Color::Magenta));
    frame.render_widget(widget, area);
}
