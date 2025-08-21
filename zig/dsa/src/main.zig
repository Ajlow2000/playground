const std = @import("std");
const sll = @import("singlyLinkedList");

const SinglyLinkedListU8 = sll.SinglyLinkedList(u8);

pub fn main() !void {
    std.debug.print("Stress testing SinglyLinkedListU8\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const n = 10000;

    var list = SinglyLinkedListU8{};

    for (0..n) |i| {
        std.debug.print("Inserting node {}.\n", .{i});
        const node = try alloc.create(SinglyLinkedListU8.Node);
        node.* = SinglyLinkedListU8.Node{ .key = std.crypto.random.int(u8) };
        try list.insertHead(node);
    }

    std.debug.print("list - {pretty}\n", .{list});

    // Cleanup: iterate through list nodes and call alloc.destroy()
    var current = list.head;
    while (current) |node| {
        const next = node.next;
        alloc.destroy(node);
        current = next;
    }
}
