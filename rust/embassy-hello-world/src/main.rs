#![no_std]
#![no_main]

esp_bootloader_esp_idf::esp_app_desc!();

use embassy_executor::Spawner;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{
    gpio::{Level, Output},
    timer::timg::TimerGroup,
};
use log::info;

#[esp_hal_embassy::main]
async fn main(_spawner: Spawner) {
    let peripherals = esp_hal::init(esp_hal::Config::default());

    esp_println::logger::init_logger_from_env();

    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    let mut led = Output::new(peripherals.GPIO15, Level::High, esp_hal::gpio::OutputConfig::default());

    loop {
        info!("Hello, World!");
        led.toggle();
        Timer::after(Duration::from_millis(1000)).await;
    }
}
