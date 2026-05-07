#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_nrf::gpio::{Level, Output, OutputDrive};
use embassy_time::Timer;
use {defmt_rtt as _, panic_probe as _};

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());
    // LED1 = P0.13, active-low: Level::High = off at startup
    let mut led = Output::new(p.P0_13, Level::High, OutputDrive::Standard);

    loop {
        led.set_low(); // on
        Timer::after_millis(500).await;
        led.set_high(); // off
        Timer::after_millis(500).await;
    }
}
