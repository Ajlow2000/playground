#![no_std]
#![no_main]

use core::sync::atomic::{AtomicU8, Ordering};
use defmt::*;
use embassy_executor::Spawner;
use embassy_futures::join::join4;
use embassy_nrf::gpio::{Level, Output, OutputDrive, Pull};
use embassy_nrf::gpiote::{InputChannel, InputChannelPolarity};
use embassy_time::Timer;
use {defmt_rtt as _, panic_probe as _};

#[derive(Clone, Copy, Format)]
#[repr(u8)]
enum BlinkState {
    Heartbeat = 0,
    Frenzy = 1,
    Drowsy = 2,
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

impl From<u8> for BlinkState {
    fn from(v: u8) -> Self {
        match v {
            1 => Self::Frenzy,
            2 => Self::Drowsy,
            _ => Self::Heartbeat,
        }
    }
}

static BLINK_STATE: AtomicU8 = AtomicU8::new(BlinkState::Heartbeat as u8);

async fn blink_led(led: &mut Output<'_>) {
    loop {
        let delay_ms = BlinkState::from(BLINK_STATE.load(Ordering::Relaxed)).delay_ms();
        led.set_low();
        Timer::after_millis(delay_ms).await;
        led.set_high();
        Timer::after_millis(delay_ms).await;
    }
}

async fn watch_button(mut btn: InputChannel<'_>, led: &mut Output<'_>, id: u8) {
    loop {
        btn.wait_for_low().await;
        info!("Button {} pressed", id);
        led.set_low();
        btn.wait_for_high().await;
        debug!("Button {} released", id);
        led.set_high();
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
        BLINK_STATE.store(state as u8, Ordering::Relaxed);
        led.set_low();
        btn.wait_for_high().await;
        debug!("Button {} released", id);
        led.set_high();
    }
}

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());

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
