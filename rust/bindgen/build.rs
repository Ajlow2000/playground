extern crate bindgen;

use bindgen::callbacks::{EnumVariantValue, ItemInfo, ParseCallbacks};
use std::env;
use std::path::PathBuf;

#[derive(Debug)]
struct RenameEnumVariants;

impl ParseCallbacks for RenameEnumVariants {
    fn item_name(&self, item: ItemInfo<'_>) -> Option<String> {
        match item.name {
            "compass_dir_t" => Some("CompassDir".to_string()),
            _ => None,
        }
    }

    fn enum_variant_name(
        &self,
        _enum_name: Option<&str>,
        original_variant_name: &str,
        _variant_value: EnumVariantValue,
    ) -> Option<String> {
        // Strip the "COMPASS_" prefix and convert to PascalCase: "COMPASS_NORTH" -> "North"
        let rustified_variant_name = original_variant_name
            .split('_')
            .skip(1) // drop "COMPASS"
            .map(|part| {
                let mut chars = part.chars();
                match chars.next() {
                    None => String::new(),
                    Some(first) => first.to_uppercase().collect::<String>() + &chars.as_str().to_lowercase(),
                }
            })
            .collect::<String>();
        Some(rustified_variant_name)
    }
}

fn main() {
    println!("cargo:rerun-if-changed=compass_dir.h");
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
