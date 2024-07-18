//! This module provides a custom implmentation for
//! a Singly Linked List.

const std = @import("std");

fn Node(comptime T: type) type {
    return struct {
        key: usize,
        val: T,
    };
}

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        head: Node(T),
        tail: Node(T),
        len: usize = 0,

        pub fn insertHead(key: usize, val: T) !void {
            unreachable;
        }

        pub fn insertTail(key: usize, val: T) !void {
            unreachable;
        }

        pub fn insertAfter(key: usize, val: T, index: usize) !void {
            unreachable;
        }

        pub fn search(key: usize) !void {
            unreachable;
        }

        pub fn deleteHead() !void {
            unreachable;
        }

        pub fn deleteTail() !void {
            unreachable;
        }

        pub fn delete(key: usize) !void {
            unreachable;
        }
    };
}
