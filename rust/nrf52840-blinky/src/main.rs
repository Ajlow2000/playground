#![no_std]
#![no_main]

use defmt::*;
use embassy_executor::Spawner;
use embassy_futures::join::join4;
use embassy_nrf::gpio::{Level, Output, OutputDrive, Pull};
use embassy_nrf::gpiote::{InputChannel, InputChannelPolarity};
use {defmt_rtt as _, panic_probe as _};

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

#[embassy_executor::main]
async fn main(_spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());

    let mut led1 = Output::new(p.P0_13, Level::High, OutputDrive::Standard);
    let mut led2 = Output::new(p.P0_14, Level::High, OutputDrive::Standard);
    let mut led3 = Output::new(p.P0_15, Level::High, OutputDrive::Standard);
    let mut led4 = Output::new(p.P0_16, Level::High, OutputDrive::Standard);

    let btn1 = InputChannel::new(p.GPIOTE_CH0, p.P0_11, Pull::Up, InputChannelPolarity::Toggle);
    let btn2 = InputChannel::new(p.GPIOTE_CH1, p.P0_12, Pull::Up, InputChannelPolarity::Toggle);
    let btn3 = InputChannel::new(p.GPIOTE_CH2, p.P0_24, Pull::Up, InputChannelPolarity::Toggle);
    let btn4 = InputChannel::new(p.GPIOTE_CH3, p.P0_25, Pull::Up, InputChannelPolarity::Toggle);

    info!("Application Ready -- Launching...");

    join4(
        watch_button(btn1, &mut led1, 1),
        watch_button(btn2, &mut led2, 2),
        watch_button(btn3, &mut led3, 3),
        watch_button(btn4, &mut led4, 4),
    )
    .await;
}
