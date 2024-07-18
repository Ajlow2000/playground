//! This module provides a custom implmentation for
//! a Singly Linked List.

const std = @import("std");

pub const SinglyLinkedListError = error{
    IndexOutOfBounds,
    HeadOutOfSync,
    TailOutOfSync,
    LengthOutOfSync,
};

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            key: T = undefined,
            next: ?*Node = null,
        };

        head: ?*Node = null,
        tail: ?*Node = null,
        len: usize = 0,

        fn validateInvariants(self: *SinglyLinkedList(T)) !void {
            if ((self.head == null) and (self.tail == null) and (self.len != 0)) return SinglyLinkedListError.LengthOutOfSync;
            if ((self.head == null) and (self.tail != null) and (self.len == 0)) return SinglyLinkedListError.TailOutOfSync;
            if ((self.head != null) and (self.tail == null) and (self.len == 0)) return SinglyLinkedListError.HeadOutOfSync;

            if ((self.head != null) and (self.tail != null) and (self.len == 0)) return SinglyLinkedListError.LengthOutOfSync;
            if ((self.head != null) and (self.tail == null) and (self.len != 0)) return SinglyLinkedListError.TailOutOfSync;
            if ((self.head == null) and (self.tail != null) and (self.len != 0)) return SinglyLinkedListError.HeadOutOfSync;
        }

        pub fn isEmpty(self: *SinglyLinkedList(T)) !bool {
            try self.validateInvariants();
            return self.head == null;
        }

        pub fn insertHead(self: *SinglyLinkedList(T), n: *Node) !void {
            try self.validateInvariants();
            defer self.len += 1;
            if (self.head == null) self.tail = n;
            n.next = self.head;
            self.head = n;
        }

        // pub fn insertTail(self: *SinglyLinkedList, key: usize, val: T) !void {
        //     std.debug.print("Key: {}, Val: {}\n", .{ key, val });
        // }
        //
        // pub fn insertAfter(self: *SinglyLinkedList, key: usize, val: T, index: usize) !void {
        //     std.debug.print("Key: {}, Val: {}, Index: {}\n", .{ key, val, index });
        // }
        //
        // pub fn search(self: *SinglyLinkedList, key: usize) !void {
        //     std.debug.print("Key: {}\n", .{key});
        // }

        pub fn get(self: *SinglyLinkedList(T), getIndex: comptime_int) !*Node {
            try self.validateInvariants();
            if (getIndex > self.len) return SinglyLinkedListError.IndexOutOfBounds;

            var current = self.head;
            var i = 0;
            while (i <= self.len - 1) {
                if (i == getIndex) return &current;
                current = current.next;
                i += 1;
            }
        }

        // pub fn deleteHead(self: *SinglyLinkedList) !void {
        //     unreachable;
        // }
        //
        // pub fn deleteTail(self: *SinglyLinkedList) !void {
        //     unreachable;
        // }
        //
        // pub fn delete(self: *SinglyLinkedList, key: usize) !void {
        //     std.debug.print("Key: {}\n", .{key});
        // }
    };
}

test "singlyLinkedList - validateInvariants" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var node = SinglyLinkedListU8.Node{ .key = 5, .next = null };

    list.head = &node;
    list.tail = null;
    list.len = 0;
    try std.testing.expectError(SinglyLinkedListError.HeadOutOfSync, list.validateInvariants());

    list.head = null;
    list.tail = &node;
    list.len = 5;
    try std.testing.expectError(SinglyLinkedListError.HeadOutOfSync, list.validateInvariants());

    list.head = &node;
    list.tail = null;
    list.len = 1;
    try std.testing.expectError(SinglyLinkedListError.TailOutOfSync, list.validateInvariants());

    list.head = null;
    list.tail = &node;
    list.len = 0;
    try std.testing.expectError(SinglyLinkedListError.TailOutOfSync, list.validateInvariants());

    list.head = null;
    list.tail = null;
    list.len = 7;
    try std.testing.expectError(SinglyLinkedListError.LengthOutOfSync, list.validateInvariants());

    list.head = &node;
    list.tail = &node;
    list.len = 0;
    try std.testing.expectError(SinglyLinkedListError.LengthOutOfSync, list.validateInvariants());
}

test "singlyLinkedList - insertHead" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());
    try std.testing.expect(list.tail == null);

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.tail == &first);

    try list.insertHead(&second);
    try std.testing.expect(list.len == 2);
    try std.testing.expect(list.tail == &first);

    try list.insertHead(&third);
    try std.testing.expect(list.len == 3);
    try std.testing.expect(list.tail == &first);
}

// test "singleLinkedList - get" {
//     const SinglyLinkedListU8 = SinglyLinkedList(u8);
//
//     var list = SinglyLinkedListU8{};
//     try std.testing.expect(try list.isEmpty());
//
//     var first = SinglyLinkedListU8.Node{ .key = 1 };
//     var second = SinglyLinkedListU8.Node{ .key = 2 };
//     var third = SinglyLinkedListU8.Node{ .key = 3 };
//
//     try list.insertHead(&first);
//     try list.insertHead(&second);
//     try list.insertHead(&third);
//
//     try std.testing.expect(list.get(2) == third);
// }
