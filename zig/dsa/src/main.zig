const std = @import("std");
const sll = @import("singlyLinkedList");

const SinglyLinkedListU8 = sll.SinglyLinkedList(u8);

pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});

    var list = SinglyLinkedListU8{};

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try list.insertHead(&second);
    try list.insertHead(&third);
    std.debug.print("list - {pretty}\n", .{list});
}
