// copied from https://github.com/deviceplug/btleplug/blob/master/examples/event_driven_discovery.rs
use btleplug::api::{
    Central, CentralEvent, Manager as _, ScanFilter,
};
use btleplug::platform::{Adapter, Manager};
use futures::stream::StreamExt;

async fn get_central(manager: &Manager) -> Adapter {
    let adapters = manager.adapters().await.unwrap();
    adapters.into_iter().nth(0).unwrap()
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    pretty_env_logger::init();

    let manager = Manager::new().await?;

    let central = get_central(&manager).await;

    let central_state = central.adapter_state().await.unwrap();
    println!("CentralState: {:?}", central_state);

    let mut events = central.events().await?;

    central.start_scan(ScanFilter::default()).await?;

    while let Some(event) = events.next().await {
        match event {
            CentralEvent::DeviceDiscovered(id) => {
                println!("DeviceDiscovered: {}", id.to_string());
            }
            _ => {}
        }
    }
    Ok(())
}
