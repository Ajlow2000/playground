#![no_std]
#![no_main]

use core::sync::atomic::{AtomicU8, Ordering};
use defmt::*;
use embassy_executor::Spawner;
use embassy_futures::join::{join, join4};
use embassy_futures::select::select;
use embassy_nrf::gpio::{Level, Output, OutputDrive, Pull};
use embassy_nrf::gpiote::{InputChannel, InputChannelPolarity};
use embassy_nrf::mode::Async;
use embassy_nrf::peripherals::RNG;
use embassy_nrf::{bind_interrupts, rng};
use embassy_time::Timer;
use nrf_sdc::mpsl::MultiprotocolServiceLayer;
use nrf_sdc::{self as sdc, mpsl};
use static_cell::StaticCell;
use trouble_host::prelude::*;
use {defmt_rtt as _, panic_probe as _};

// ---------- Blink state ----------

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

// ---------- Interrupt bindings ----------

bind_interrupts!(struct Irqs {
    RNG        => rng::InterruptHandler<RNG>;
    EGU0_SWI0  => nrf_sdc::mpsl::LowPrioInterruptHandler;
    CLOCK_POWER => nrf_sdc::mpsl::ClockInterruptHandler;
    RADIO      => nrf_sdc::mpsl::HighPrioInterruptHandler;
    TIMER0     => nrf_sdc::mpsl::HighPrioInterruptHandler;
    RTC0       => nrf_sdc::mpsl::HighPrioInterruptHandler;
});

// ---------- GATT server ----------
//
// Service UUID:        12345678-1234-5678-1234-56789abc0001
// Characteristic UUID: 12345678-1234-5678-1234-56789abc0002
//   - read:  returns current BlinkState (0=Heartbeat, 1=Frenzy, 2=Drowsy)
//   - write: sets BlinkState (same encoding)
//   - notify: sent whenever the state changes (via button or BLE write)

#[gatt_service(uuid = "12345678-1234-5678-1234-56789abc0001")]
struct BlinkService {
    #[characteristic(uuid = "12345678-1234-5678-1234-56789abc0002", read, write, notify)]
    state: u8,
}

#[gatt_server]
struct Server {
    blink: BlinkService,
}

// ---------- LED / button tasks ----------

async fn blink_led(led: &mut Output<'_>) {
    loop {
        let delay_ms = BlinkState::from(BLINK_STATE.load(Ordering::Relaxed)).delay_ms();
        led.set_low();
        Timer::after_millis(delay_ms).await;
        led.set_high();
        Timer::after_millis(delay_ms).await;
    }
}

async fn watch_button_state(mut btn: InputChannel<'_>, led: &mut Output<'_>, id: u8, state: BlinkState) {
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

// ---------- MPSL task ----------

#[embassy_executor::task]
async fn mpsl_task(mpsl: &'static MultiprotocolServiceLayer<'static>) -> ! {
    mpsl.run().await
}

// ---------- SDC setup ----------

const L2CAP_TXQ: u8 = 3;
const L2CAP_RXQ: u8 = 3;

fn build_sdc<'d, const N: usize>(
    p: sdc::Peripherals<'d>,
    rng: &'d mut rng::Rng<Async>,
    mpsl: &'d MultiprotocolServiceLayer,
    mem: &'d mut sdc::Mem<N>,
) -> Result<sdc::SoftdeviceController<'d>, sdc::Error> {
    sdc::Builder::new()?
        .support_adv()
        .support_peripheral()
        .peripheral_count(1)?
        .buffer_cfg(
            DefaultPacketPool::MTU as u16,
            DefaultPacketPool::MTU as u16,
            L2CAP_TXQ,
            L2CAP_RXQ,
        )?
        .build(p, rng, mpsl, mem)
}

// ---------- BLE tasks ----------

async fn run_ble(controller: impl Controller) {
    let address = Address::random([0xff, 0x8f, 0x1a, 0x05, 0xe4, 0xff]);
    info!("BLE address = {:?}", address);

    let mut resources: HostResources<_, DefaultPacketPool, 1, 2> = HostResources::new();
    let stack = trouble_host::new(controller, &mut resources)
        .set_random_address(address)
        .build();
    let runner = stack.runner();
    let mut peripheral = stack.peripheral();

    let server = Server::new_with_config(GapConfig::Peripheral(PeripheralConfig {
        name: "nRF52840",
        appearance: &appearance::UNKNOWN,
    }))
    .unwrap();

    join(ble_runner(runner), async {
        loop {
            match advertise(&mut peripheral, &server).await {
                Ok(conn) => {
                    select(gatt_task(&server, &conn), notify_task(&server, &conn)).await;
                }
                Err(e) => {
                    warn!("[ble] advertise error: {:?}", defmt::Debug2Format(&e));
                }
            }
        }
    })
    .await;
}

async fn ble_runner<C: Controller, P: PacketPool>(mut runner: Runner<'_, C, P>) {
    loop {
        if let Err(e) = runner.run().await {
            warn!("[ble_runner] error: {:?}", defmt::Debug2Format(&e));
        }
    }
}

async fn advertise<'values, 'server, C: Controller>(
    peripheral: &mut Peripheral<'values, C, DefaultPacketPool>,
    server: &'server Server<'values>,
) -> Result<GattConnection<'values, 'server, DefaultPacketPool>, BleHostError<C::Error>> {
    let mut adv_data = [0u8; 31];
    let len = AdStructure::encode_slice(
        &[
            AdStructure::Flags(LE_GENERAL_DISCOVERABLE | BR_EDR_NOT_SUPPORTED),
            AdStructure::CompleteLocalName(b"AJL 3333"),
        ],
        &mut adv_data[..],
    )?;
    let advertiser = peripheral
        .advertise(
            &Default::default(),
            Advertisement::ConnectableScannableUndirected {
                adv_data: &adv_data[..len],
                scan_data: &[],
            },
        )
        .await?;
    info!("[ble] advertising...");
    let conn = advertiser.accept().await?.with_attribute_server(server)?;
    info!("[ble] connected");
    Ok(conn)
}

// Handles GATT read/write events. A write to the state characteristic updates BLINK_STATE.
async fn gatt_task<P: PacketPool>(server: &Server<'_>, conn: &GattConnection<'_, '_, P>) -> Result<(), Error> {
    let state_handle = server.blink.state.handle;
    loop {
        match conn.next().await {
            GattConnectionEvent::Disconnected { reason } => {
                info!("[ble] disconnected: {:?}", reason);
                break Ok(());
            }
            GattConnectionEvent::Gatt { event } => {
                if let GattEvent::Write(e) = &event {
                    if e.handle() == state_handle {
                        if let Some(&val) = e.data().first() {
                            BLINK_STATE.store(val, Ordering::Relaxed);
                            info!("[ble] blink state -> {}", val);
                        }
                    }
                }
                if let Ok(reply) = event.accept() {
                    reply.send().await;
                }
            }
            _ => {}
        }
    }
}

// Sends a BLE notification whenever BLINK_STATE changes (e.g. from a button press).
async fn notify_task<P: PacketPool>(server: &Server<'_>, conn: &GattConnection<'_, '_, P>) {
    let mut last = BLINK_STATE.load(Ordering::Relaxed);
    loop {
        Timer::after_millis(100).await;
        let current = BLINK_STATE.load(Ordering::Relaxed);
        if current != last {
            last = current;
            if server.blink.state.notify(conn, &current).await.is_err() {
                break;
            }
        }
    }
}

// ---------- Main ----------

#[embassy_executor::main]
async fn main(spawner: Spawner) {
    let p = embassy_nrf::init(Default::default());

    // MPSL (Multiprotocol Service Layer) — takes RTC0, TIMER0, TEMP
    let mpsl_p = mpsl::Peripherals::new(p.RTC0, p.TIMER0, p.TEMP, p.PPI_CH19, p.PPI_CH30, p.PPI_CH31);
    let lfclk_cfg = mpsl::raw::mpsl_clock_lfclk_cfg_t {
        source: mpsl::raw::MPSL_CLOCK_LF_SRC_RC as u8,
        rc_ctiv: mpsl::raw::MPSL_RECOMMENDED_RC_CTIV as u8,
        rc_temp_ctiv: mpsl::raw::MPSL_RECOMMENDED_RC_TEMP_CTIV as u8,
        accuracy_ppm: mpsl::raw::MPSL_DEFAULT_CLOCK_ACCURACY_PPM as u16,
        skip_wait_lfclk_started: mpsl::raw::MPSL_DEFAULT_SKIP_WAIT_LFCLK_STARTED != 0,
    };
    static MPSL: StaticCell<MultiprotocolServiceLayer> = StaticCell::new();
    let mpsl = MPSL.init(unwrap!(mpsl::MultiprotocolServiceLayer::new(mpsl_p, Irqs, lfclk_cfg)));
    spawner.spawn(mpsl_task(&*mpsl).unwrap());

    // SoftDevice Controller — takes PPI channels for BLE radio scheduling
    let sdc_p = sdc::Peripherals::new(
        p.PPI_CH17, p.PPI_CH18, p.PPI_CH20, p.PPI_CH21, p.PPI_CH22, p.PPI_CH23,
        p.PPI_CH24, p.PPI_CH25, p.PPI_CH26, p.PPI_CH27, p.PPI_CH28, p.PPI_CH29,
    );
    let mut rng = rng::Rng::new(p.RNG, Irqs);
    let mut sdc_mem = sdc::Mem::<4720>::new();
    let sdc = unwrap!(build_sdc(sdc_p, &mut rng, mpsl, &mut sdc_mem));

    // LEDs and buttons
    let mut led1 = Output::new(p.P0_13, Level::High, OutputDrive::Standard);
    let mut led2 = Output::new(p.P0_14, Level::High, OutputDrive::Standard);
    let mut led3 = Output::new(p.P0_15, Level::High, OutputDrive::Standard);
    let mut led4 = Output::new(p.P0_16, Level::High, OutputDrive::Standard);

    let btn2 = InputChannel::new(p.GPIOTE_CH1, p.P0_12, Pull::Up, InputChannelPolarity::Toggle);
    let btn3 = InputChannel::new(p.GPIOTE_CH2, p.P0_24, Pull::Up, InputChannelPolarity::Toggle);
    let btn4 = InputChannel::new(p.GPIOTE_CH3, p.P0_25, Pull::Up, InputChannelPolarity::Toggle);

    info!("Application Ready -- Launching...");

    join(
        run_ble(sdc),
        join4(
            blink_led(&mut led1),
            watch_button_state(btn2, &mut led2, 2, BlinkState::Frenzy),
            watch_button_state(btn3, &mut led3, 3, BlinkState::Drowsy),
            watch_button_state(btn4, &mut led4, 4, BlinkState::Heartbeat),
        ),
    )
    .await;
}
