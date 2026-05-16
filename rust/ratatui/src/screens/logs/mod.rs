use ratatui::Frame;
use ratatui::layout::Rect;
use tui_logger::{TuiLoggerSmartWidget, TuiWidgetEvent, TuiWidgetState};

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
    let widget = TuiLoggerSmartWidget::default().state(&model.widget_state);
    frame.render_widget(widget, area);
}
