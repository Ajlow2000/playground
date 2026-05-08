#![no_std]
#![no_main]

use defmt::*;
use embassy_executor::Spawner;
use embassy_futures::join::join4;
use embassy_futures::select::{select, Either};
use embassy_nrf::gpio::{Level, Output, OutputDrive, Pull};
use embassy_nrf::gpiote::{InputChannel, InputChannelPolarity};
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::signal::Signal;
use embassy_time::Timer;
use {defmt_rtt as _, panic_probe as _};

#[derive(Clone, Copy, Format)]
#[repr(u8)]
enum BlinkState {
    Heartbeat = 0, // steady 500ms pulse
    Frenzy = 1,    // rapid 100ms flash
    Drowsy = 2,    // slow 1000ms throb
}

impl BlinkState {
    fn delay_ms(self) -> u64 {
        match self {
            Self::Heartbeat => 500,
            Self::Frenzy => 100,
            Self::Drowsy => 1000,
        }
    }
}

static STATE_SIGNAL: Signal<CriticalSectionRawMutex, BlinkState> = Signal::new();

async fn blink_led(led: &mut Output<'_>) {
    let mut state = BlinkState::Heartbeat;
    loop {
        led.set_low();
        match select(Timer::after_millis(state.delay_ms()), STATE_SIGNAL.wait()).await {
            Either::First(_) => {}
            Either::Second(new_state) => {
                led.set_high();
                state = new_state;
                continue;
            }
        }
        led.set_high();
        match select(Timer::after_millis(state.delay_ms()), STATE_SIGNAL.wait()).await {
            Either::First(_) => {}
            Either::Second(new_state) => {
                state = new_state;
                continue;
            }
        }
    }
}

async fn watch_button_state(
    mut btn: InputChannel<'_>,
    led: &mut Output<'_>,
    id: u8,
    state: BlinkState,
) {
    loop {
        btn.wait_for_low().await;
        info!("Button {} pressed -> {}", id, state);
        STATE_SIGNAL.signal(state);
        led.set_low();
        btn.wait_for_high().await;
        debug!("Button {} released", id);
        led.set_high();
    }
}

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());

    // led1 exclusively owned by blink_led — btn1 dropped
    let mut led1 = Output::new(p.P0_13, Level::High, OutputDrive::Standard);
    let mut led2 = Output::new(p.P0_14, Level::High, OutputDrive::Standard);
    let mut led3 = Output::new(p.P0_15, Level::High, OutputDrive::Standard);
    let mut led4 = Output::new(p.P0_16, Level::High, OutputDrive::Standard);

    let btn2 = InputChannel::new(p.GPIOTE_CH1, p.P0_12, Pull::Up, InputChannelPolarity::Toggle);
    let btn3 = InputChannel::new(p.GPIOTE_CH2, p.P0_24, Pull::Up, InputChannelPolarity::Toggle);
    let btn4 = InputChannel::new(p.GPIOTE_CH3, p.P0_25, Pull::Up, InputChannelPolarity::Toggle);

    info!("Application Ready -- Launching...");

    join4(
        blink_led(&mut led1),
        watch_button_state(btn2, &mut led2, 2, BlinkState::Frenzy),
        watch_button_state(btn3, &mut led3, 3, BlinkState::Drowsy),
        watch_button_state(btn4, &mut led4, 4, BlinkState::Heartbeat),
    )
    .await;
}
