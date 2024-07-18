const std = @import("std");
const sll = @import("singlyLinkedList");

pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});
    try sll.foo();
}
