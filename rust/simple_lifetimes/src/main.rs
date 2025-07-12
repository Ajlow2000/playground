// fn between(input: &str, start_boundary: &str, end_boundary: &str) -> &str {
//     let Some(mut start) = input.find(start_boundary) else { return "" };
//     start += start_boundary.len();
//     let Some(mut end) = input.find(end_boundary) else { return "" };
//     end += end_boundary.len();
//     &input[start..end]
// }

fn between<'a, 'b>(input: &'a str, start_boundary: &'b str, end_boundary: &'b str) -> &'a str {
    let Some(mut start) = input.find(start_boundary) else { return "" };
    start += start_boundary.len();
    let Some(end) = input[start..].find(end_boundary) else { return "" };
    &input[start..start + end]
}

fn main() {
    let example1 = "the quick <p>brown fox jumps </p>over the lazy dog";
    let between1 = between(example1, "<p>", "</p>");
    println!("Example 1: {between1}\n");

    let example2 = String::from("xxxxxxx this (or that) yyyyyyyyyyy");
    let between2 = between(&example2, "(", ")");
    // drop(example2); // this throws compiler error now that we helped by specifying lifetimes
    println!("Example 2: {between2}\n");
}
