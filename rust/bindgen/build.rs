extern crate bindgen;

use bindgen::callbacks::{EnumVariantValue, ItemInfo, ParseCallbacks};
use std::env;
use std::path::PathBuf;

include!("build_helpers/rename_callbacks.rs");

#[derive(Debug)]
struct RenameEnumVariants;

impl ParseCallbacks for RenameEnumVariants {
    fn item_name(&self, item: ItemInfo<'_>) -> Option<String> {
        rename_type(item.name)
    }

    fn enum_variant_name(
        &self,
        _enum_name: Option<&str>,
        original_variant_name: &str,
        _variant_value: EnumVariantValue,
    ) -> Option<String> {
        rename_variant(original_variant_name)
    }
}

fn main() {
    println!("cargo:rerun-if-changed=compass_dir.h");
    println!("cargo:rerun-if-changed=compass_dir.c");
    cc::Build::new().file("compass_dir.c").opt_level(1).compile("compass_dir");
    let bindings = bindgen::Builder::default()
        .header("compass_dir.h")
        .rustified_enum("compass_dir_t")
        .parse_callbacks(Box::new(RenameEnumVariants))
        .generate_comments(false)
        .generate()
        .expect("Unable to generate bindings");
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
