use std::time::{Duration, Instant};

use futures::future::join_all;
use tokio::time::sleep;

async fn preheat_oven(id: u64) -> u64 {
    let t = 5;
    println!("started: preheat_oven {:?}", id);
    sleep(Duration::from_secs(t)).await;
    println!("finished: preheat_oven {:?}", id);
    t
}

async fn cook_thing_in_oven(id: u64) -> u64 {
    let t = 10;
    println!("started: cook_thing_in_oven {:?}", id);
    sleep(Duration::from_secs(t)).await;
    println!("finished: cook_thing_in_oven {:?}", id);
    t
}

async fn perform_oven_operations_in_order(id: u64) -> u64 {
    preheat_oven(id).await + cook_thing_in_oven(id).await

}

#[tokio::main]
async fn main() {
    let start_time = Instant::now();

    let tasks = vec![
        perform_oven_operations_in_order(1),
        perform_oven_operations_in_order(2),
    ];
    
    let results = join_all(tasks).await;
    let t: u64 = results.iter().sum();

    let elapsed_time = start_time.elapsed();
    println!("");
    println!("Aggregate individual time: {:?}", Duration::from_secs(t));
    println!("Main actual elapsed time:  {:?}", elapsed_time);
}
