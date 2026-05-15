use crate::bindings::{self, CompassFlags, CompassRaw};
pub use crate::bindings::{CompassDir, CompassReading};
use std::ffi::CStr;

pub fn dir_from_degrees(degrees: u32) -> CompassDir {
    unsafe { bindings::compass_dir_from_degrees(degrees) }
}

pub fn dir_is_cardinal(dir: CompassDir) -> bool {
    unsafe { bindings::compass_dir_is_cardinal(dir) }
}

// Returns a &'static str because the C function returns string literals.
pub fn dir_name(dir: CompassDir) -> &'static str {
    unsafe { CStr::from_ptr(bindings::compass_dir_name(dir)).to_str().unwrap_or("?") }
}

pub fn flags_get(dir: CompassDir) -> CompassFlags {
    unsafe { bindings::compass_flags_get(dir) }
}

pub fn dir_as_raw(dir: CompassDir) -> u32 {
    unsafe { CompassRaw { dir }.raw }
}

pub fn dir_from_raw(raw: u32) -> Option<CompassDir> {
    match raw {
        0   => Some(CompassDir::North),
        90  => Some(CompassDir::East),
        180 => Some(CompassDir::South),
        270 => Some(CompassDir::West),
        255 => Some(CompassDir::Invalid),
        _   => None,
    }
}

// Wraps the C callback pattern with a Rust closure. The trampoline converts
// the void* user_data back to the closure and calls it. Safe because
// compass_reading_process calls the callback synchronously before returning,
// so the closure reference is valid for the entire call.
pub fn reading_process<F: Fn(CompassReading)>(reading: CompassReading, cb: F) {
    unsafe extern "C" fn trampoline<F: Fn(CompassReading)>(
        reading: CompassReading,
        user_data: *mut std::ffi::c_void,
    ) {
        let cb = &*(user_data as *const F);
        cb(reading);
    }
    unsafe {
        bindings::compass_reading_process(
            reading,
            Some(trampoline::<F>),
            &cb as *const F as *mut std::ffi::c_void,
        );
    }
}
