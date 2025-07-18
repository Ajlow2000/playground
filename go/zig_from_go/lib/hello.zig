const std = @import("std");

export fn hello_from_zig() [*:0]const u8 {
    return "Hello from Zig!";
}

export fn add_numbers(a: i32, b: i32) i32 {
    return a + b;
}