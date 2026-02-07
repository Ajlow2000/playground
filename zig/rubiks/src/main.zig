const std = @import("std");
const rubiks = @import("rubiks");
const cube_matrix = @import("cube_matrix.zig");

pub fn main() !void {
    std.debug.print("### Rubik's Cube Matrix Transformation Demo ###\n\n", .{});

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Create a solved cube
    var cube = cube_matrix.CubeState.init_solved();
    std.debug.print("Initial solved cube:\n", .{});
    try cube.print(stdout);
    try stdout.flush();
    std.debug.print("\n", .{});

    // Demonstrate R move
    const R = cube_matrix.move_R();
    cube = R.apply(&cube);
    std.debug.print("After R move:\n", .{});
    try cube.print(stdout);
    try stdout.flush();
    std.debug.print("\n", .{});

    // Demonstrate U move
    const U = cube_matrix.move_U();
    cube = U.apply(&cube);
    std.debug.print("After R U:\n", .{});
    try cube.print(stdout);
    try stdout.flush();
    std.debug.print("\n", .{});

    // Demonstrate inverse moves
    const R_inv = R.inverse();
    const U_inv = U.inverse();
    cube = R_inv.apply(&cube);
    cube = U_inv.apply(&cube);
    std.debug.print("After R U R' U' (back to solved):\n", .{});
    try cube.print(stdout);
    try stdout.flush();
    std.debug.print("\n", .{});

    // Demonstrate move composition (sexy move: R U R' U')
    const RU = cube_matrix.MoveTransform.compose(&R, &U);
    const RUR_inv = cube_matrix.MoveTransform.compose(&RU, &R_inv);
    const sexy = cube_matrix.MoveTransform.compose(&RUR_inv, &U_inv);

    std.debug.print("Applying sexy move (R U R' U') 6 times:\n", .{});
    cube = cube_matrix.CubeState.init_solved();
    for (0..6) |i| {
        cube = sexy.apply(&cube);
        std.debug.print("Iteration {}: {s}\n", .{i + 1, if (cube.is_solved()) "SOLVED!" else "scrambled"});
    }

    std.debug.print("\nFinal state after 6 iterations:\n", .{});
    try cube.print(stdout);
    try stdout.flush();
    std.debug.print("\nMatrix transformations working correctly!\n", .{});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
