include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

fn main() {
    println!("Hello, world {:?}!", Doggo {
        breed: 1,
    });
}

