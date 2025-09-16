const std = @import("std");
const raylib = @import("raylib");

pub fn main() !void {
    std.debug.print("foo\n", .{});
    // const screenWidth = 800;
    // const screenHeight = 450;
    //
    // raylib.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window");
    // defer raylib.CloseWindow();
    //
    // raylib.SetTargetFPS(60);
    //
    // while (!raylib.WindowShouldClose()) {
    //     raylib.BeginDrawing();
    //     defer raylib.EndDrawing();
    //
    //     raylib.ClearBackground(raylib.RAYWHITE);
    //     raylib.DrawText("Congrats! You created your first window!", 190, 200, 20, raylib.LIGHTGRAY);
    // }
}
