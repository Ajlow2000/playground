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
            if (self.tail == null) self.tail = n;
            n.next = self.head;
            self.head = n;
        }

        pub fn insertTail(self: *SinglyLinkedList(T), n: *Node) !void {
            try self.validateInvariants();
            defer self.len += 1;
            if (self.tail == null) {
                self.head = n;
                self.tail = n;
            } else {
                self.tail.?.next = n;
                self.tail = n;
            }
        }

        pub fn insertAfter(self: *SinglyLinkedList(T), n: *Node, index: usize) !void {
            try self.validateInvariants();
            if (index >= self.len) return SinglyLinkedListError.IndexOutOfBounds;
            defer self.len += 1;

            var current = self.head;
            var i: usize = 0;
            while (i < self.len) {
                if (i == index) {
                    n.next = current.?.next;
                    current.?.next = n;
                    if (current == self.tail) self.tail = n;
                    return;
                } else {
                    current = current.?.next;
                    i += 1;
                }
            }
        }

        pub fn search(self: *SinglyLinkedList(T), key: T) !?*Node {
            try self.validateInvariants();
            var current = self.head;
            while (current != null) {
                if (current.?.key == key) return current;
                current = current.?.next;
            }
            return null;
        }

        pub fn get(self: *SinglyLinkedList(T), getIndex: usize) !*Node {
            try self.validateInvariants();
            if (getIndex >= self.len) return SinglyLinkedListError.IndexOutOfBounds;

            var current = self.head;
            var i: usize = 0;
            while (i < self.len) {
                if (i == getIndex) return current.?;
                current = current.?.next;
                i += 1;
            }
            unreachable;
        }

        pub fn deleteHead(self: *SinglyLinkedList(T)) !void {
            try self.validateInvariants();
            if (self.head == null) return;
            
            defer self.len -= 1;
            
            if (self.head == self.tail) {
                self.head = null;
                self.tail = null;
            } else {
                self.head = self.head.?.next;
            }
        }
        
        pub fn deleteTail(self: *SinglyLinkedList(T)) !void {
            try self.validateInvariants();
            if (self.tail == null) return;
            
            defer self.len -= 1;
            
            if (self.head == self.tail) {
                self.head = null;
                self.tail = null;
            } else {
                var current = self.head;
                while (current.?.next != self.tail) {
                    current = current.?.next;
                }
                current.?.next = null;
                self.tail = current;
            }
        }
        
        pub fn delete(self: *SinglyLinkedList(T), key: T) !bool {
            try self.validateInvariants();
            if (self.head == null) return false;
            
            if (self.head.?.key == key) {
                try self.deleteHead();
                return true;
            }
            
            var current = self.head;
            while (current.?.next != null) {
                if (current.?.next.?.key == key) {
                    const nodeToDelete = current.?.next;
                    current.?.next = nodeToDelete.?.next;
                    if (nodeToDelete == self.tail) {
                        self.tail = current;
                    }
                    self.len -= 1;
                    return true;
                }
                current = current.?.next;
            }
            return false;
        }

        pub fn format(
            self: SinglyLinkedList(T),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = options;
            
            if (std.mem.eql(u8, fmt, "pretty")) {
                // Pretty format with newlines
                try writer.print("SinglyLinkedList {{\n", .{});
                try writer.print("  len: {}\n", .{self.len});
                try writer.print("  nodes:\n", .{});
                
                var current = self.head;
                var index: usize = 0;
                while (current) |node| {
                    try writer.print("    [{}]: {} -> ", .{ index, node.key });
                    if (node.next) |_| {
                        try writer.print("next\n", .{});
                    } else {
                        try writer.print("null\n", .{});
                    }
                    current = node.next;
                    index += 1;
                }
                try writer.print("}}", .{});
            } else {
                // Default compact format
                try writer.print("SinglyLinkedList(len={}) {{ ", .{self.len});
                
                var current = self.head;
                var first = true;
                while (current) |node| {
                    if (!first) {
                        try writer.print(" -> ", .{});
                    } else {
                        first = false;
                    }
                    try writer.print("{}", .{node.key});
                    current = node.next;
                }
                
                try writer.print(" }}", .{});
            }
        }
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

test "singlyLinkedList - insertTail" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());
    try std.testing.expect(list.tail == null);

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertTail(&first);
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &first);

    try list.insertTail(&second);
    try std.testing.expect(list.len == 2);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &second);

    try list.insertTail(&third);
    try std.testing.expect(list.len == 3);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &third);
}

test "singlyLinkedList - insertAfter" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());
    try std.testing.expect(list.tail == null);

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &first);

    try list.insertAfter(&second, 0);
    try std.testing.expect(list.len == 2);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &second);

    try list.insertAfter(&third, 1);
    try std.testing.expect(list.len == 3);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &third);
}

test "singleLinkedList - get" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try list.insertHead(&second);
    try list.insertHead(&third);

    try std.testing.expect(try list.get(0) == &third);
}

test "singlyLinkedList - search" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try list.insertHead(&second);
    try list.insertHead(&third);

    try std.testing.expect(try list.search(2) == &second);
    try std.testing.expect(try list.search(1) == &first);
    try std.testing.expect(try list.search(3) == &third);
    try std.testing.expect(try list.search(99) == null);
}

test "singlyLinkedList - deleteHead" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try list.insertHead(&second);
    try list.insertHead(&third);

    try std.testing.expect(list.len == 3);
    try std.testing.expect(list.head == &third);

    try list.deleteHead();
    try std.testing.expect(list.len == 2);
    try std.testing.expect(list.head == &second);

    try list.deleteHead();
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &first);

    try list.deleteHead();
    try std.testing.expect(list.len == 0);
    try std.testing.expect(list.head == null);
    try std.testing.expect(list.tail == null);
}

test "singlyLinkedList - deleteTail" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertTail(&first);
    try list.insertTail(&second);
    try list.insertTail(&third);

    try std.testing.expect(list.len == 3);
    try std.testing.expect(list.tail == &third);

    try list.deleteTail();
    try std.testing.expect(list.len == 2);
    try std.testing.expect(list.tail == &second);

    try list.deleteTail();
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.tail == &first);
    try std.testing.expect(list.head == &first);

    try list.deleteTail();
    try std.testing.expect(list.len == 0);
    try std.testing.expect(list.head == null);
    try std.testing.expect(list.tail == null);
}

test "singlyLinkedList - delete" {
    const SinglyLinkedListU8 = SinglyLinkedList(u8);

    var list = SinglyLinkedListU8{};
    try std.testing.expect(try list.isEmpty());

    var first = SinglyLinkedListU8.Node{ .key = 1 };
    var second = SinglyLinkedListU8.Node{ .key = 2 };
    var third = SinglyLinkedListU8.Node{ .key = 3 };

    try list.insertHead(&first);
    try list.insertHead(&second);
    try list.insertHead(&third);

    try std.testing.expect(list.len == 3);
    try std.testing.expect(try list.delete(99) == false);
    try std.testing.expect(list.len == 3);

    try std.testing.expect(try list.delete(2) == true);
    try std.testing.expect(list.len == 2);
    try std.testing.expect(try list.search(2) == null);

    try std.testing.expect(try list.delete(3) == true);
    try std.testing.expect(list.len == 1);
    try std.testing.expect(list.head == &first);
    try std.testing.expect(list.tail == &first);

    try std.testing.expect(try list.delete(1) == true);
    try std.testing.expect(list.len == 0);
    try std.testing.expect(list.head == null);
    try std.testing.expect(list.tail == null);
}
