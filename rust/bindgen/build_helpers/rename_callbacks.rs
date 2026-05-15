// Strips the first underscore-delimited segment (the prefix) and converts to PascalCase.
// "COMPASS_NORTH" -> "North", "COMPASS_INVALID" -> "Invalid"
fn rename_variant(original: &str) -> Option<String> {
    let renamed: String = original
        .split('_')
        .skip(1)
        .map(|part| {
            let mut chars = part.chars();
            match chars.next() {
                None => String::new(),
                Some(first) => first.to_uppercase().collect::<String>() + &chars.as_str().to_lowercase(),
            }
        })
        .collect();
    Some(renamed)
}

// Maps C type names to idiomatic Rust names.
fn rename_type(original: &str) -> Option<String> {
    match original {
        "compass_dir_t"        => Some("CompassDir".to_string()),
        "compass_reading_t"    => Some("CompassReading".to_string()),
        "compass_flags_t"      => Some("CompassFlags".to_string()),
        "compass_raw_u"        => Some("CompassRaw".to_string()),
        "compass_reading_cb_t" => Some("CompassReadingCb".to_string()),
        _                      => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn variant_strips_prefix_and_title_cases() {
        assert_eq!(rename_variant("COMPASS_NORTH"),   Some("North".to_string()));
        assert_eq!(rename_variant("COMPASS_EAST"),    Some("East".to_string()));
        assert_eq!(rename_variant("COMPASS_SOUTH"),   Some("South".to_string()));
        assert_eq!(rename_variant("COMPASS_WEST"),    Some("West".to_string()));
        assert_eq!(rename_variant("COMPASS_INVALID"), Some("Invalid".to_string()));
    }

    #[test]
    fn type_rename_maps_known_c_names() {
        assert_eq!(rename_type("compass_dir_t"),        Some("CompassDir".to_string()));
        assert_eq!(rename_type("compass_reading_t"),    Some("CompassReading".to_string()));
        assert_eq!(rename_type("compass_flags_t"),      Some("CompassFlags".to_string()));
        assert_eq!(rename_type("compass_raw_u"),        Some("CompassRaw".to_string()));
        assert_eq!(rename_type("compass_reading_cb_t"), Some("CompassReadingCb".to_string()));
    }

    #[test]
    fn type_rename_passes_through_unknown_names() {
        assert_eq!(rename_type("some_other_t"), None);
    }
}
