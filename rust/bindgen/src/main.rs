#[allow(non_camel_case_types, dead_code, non_upper_case_globals)]
mod bindings {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

mod compass;
use compass::{CompassDir, CompassReading};

fn describe(dir: CompassDir) -> &'static str {
    match dir {
        CompassDir::North   => "north",
        CompassDir::East    => "east",
        CompassDir::South   => "south",
        CompassDir::West    => "west",
        CompassDir::Invalid => "invalid",
    }
}

fn main() {
    let dir = compass::dir_from_degrees(45);
    println!("45 degrees => {:?} ({})", dir, describe(dir));

    println!("North is cardinal: {}", compass::dir_is_cardinal(CompassDir::North));

    println!("dir_name(South) => {}", compass::dir_name(CompassDir::South));

    let reading = CompassReading { latitude: 51.5, longitude: -0.1, heading: CompassDir::North };
    println!("reading heading: {:?}", reading.heading);

    let flags = compass::flags_get(CompassDir::North);
    println!("North flags: is_cardinal={} is_valid={}", flags.is_cardinal(), flags.is_valid());

    let flags = compass::flags_get(CompassDir::Invalid);
    println!("Invalid flags: is_cardinal={} is_valid={}", flags.is_cardinal(), flags.is_valid());

    println!("South as raw u32: {}", compass::dir_as_raw(CompassDir::South));
    println!("raw 180 => {:?}", compass::dir_from_raw(180));
    println!("raw 42  => {:?}", compass::dir_from_raw(42));

    compass::reading_process(reading, |r| {
        println!("callback: {:?} at ({:.1}, {:.1})", r.heading, r.latitude, r.longitude);
    });
}

#[cfg(test)]
include!("../build_helpers/rename_callbacks.rs");
