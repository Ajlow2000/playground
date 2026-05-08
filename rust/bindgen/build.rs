extern crate bindgen;

use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=compass_dir.h");
    let bindings = bindgen::Builder::default()
        .header("compass_dir.h")
        .rustified_enum("compass_dir_t")
        .generate_comments(false)
        .generate()
        .expect("Unable to generate bindings");
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
