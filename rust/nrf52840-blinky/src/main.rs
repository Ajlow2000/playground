#![no_std]
#![no_main]

use defmt::*;
use embassy_executor::Spawner;
use embassy_nrf::gpio::{Input, Level, Output, OutputDrive, Pull};
use embassy_time::Timer;
use {defmt_rtt as _, panic_probe as _};

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());

    let mut led1 = Output::new(p.P0_13, Level::High, OutputDrive::Standard);
    let mut led2 = Output::new(p.P0_14, Level::High, OutputDrive::Standard);
    let mut led3 = Output::new(p.P0_15, Level::High, OutputDrive::Standard);
    let mut led4 = Output::new(p.P0_16, Level::High, OutputDrive::Standard);

    let btn1 = Input::new(p.P0_11, Pull::Up);
    let btn2 = Input::new(p.P0_12, Pull::Up);
    let btn3 = Input::new(p.P0_24, Pull::Up);
    let btn4 = Input::new(p.P0_25, Pull::Up);

    info!("Ready");

    let mut prev = [false; 4];
    loop {
        let curr = [btn1.is_low(), btn2.is_low(), btn3.is_low(), btn4.is_low()];

        for i in 0..4 {
            if curr[i] != prev[i] {
                if curr[i] {
                    info!("Button {} pressed", i + 1);
                } else {
                    debug!("Button {} released", i + 1);
                }
            }
        }
        prev = curr;

        led1.set_level(if curr[0] { Level::Low } else { Level::High });
        led2.set_level(if curr[1] { Level::Low } else { Level::High });
        led3.set_level(if curr[2] { Level::Low } else { Level::High });
        led4.set_level(if curr[3] { Level::Low } else { Level::High });
        Timer::after_millis(10).await;
    }
}
