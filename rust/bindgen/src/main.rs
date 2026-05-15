#[allow(non_camel_case_types, dead_code)]
mod bindings {
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}
use bindings::compass_dir_t as CompassDir;

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
    let dir = CompassDir::North;
    println!("direction: {:?} ({})", dir, describe(dir));

    println!("raw value: {}", dir as u32);

    let raw: u32 = 180;
    let from_raw: CompassDir = unsafe { std::mem::transmute(raw) };
    println!("raw {} => {:?}", raw, from_raw);
}
