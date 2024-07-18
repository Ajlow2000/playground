const std = @import("std");
const sll = @import("singlyLinkedList");

const singlyLinkedListU16 = sll.SinglyLinkedList(u16);

pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});
}
