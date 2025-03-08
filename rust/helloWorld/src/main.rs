fn main() {
    println!("Hello, world!");
    let (a, b) = (4, 5);
    dbg!(a);
    dbg!(b);
    struct Thing(i32);
    let Thing(c) = Thing(39);
    dbg!(c);
}
