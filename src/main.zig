const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Texture2DArrayList = std.ArrayList(c.Texture2D);

const title = "Codotaku Image Viewer";
const cycle_filter_key = c.KEY_P;
const clear_textures_key = c.KEY_BACKSPACE;
const toggle_fullscreen_key = c.KEY_F;
const zoom_increment = 0.1;
const vector2_zero = c.Vector2Zero();
const rotation_increment = 15;
const rotation_duration = 0.2;
const zoom_duration = 0.2;

fn focusCamera(camera: *c.Camera2D, screen_position: c.Vector2) void {
    camera.*.target = c.GetScreenToWorld2D(screen_position, camera.*);
    camera.*.offset = screen_position;
}

pub fn main() error{OutOfMemory}!void {
    c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE | c.FLAG_VSYNC_HINT);
    c.InitWindow(800, 600, title);
    defer c.CloseWindow();

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var textures = Texture2DArrayList.init(allocator);
    defer {
        for (textures.items) |texture| {
            c.UnloadTexture(texture);
        }
        textures.deinit();
    }

    var texture_filter = c.TEXTURE_FILTER_TRILINEAR;
    var target_zoom: f32 = 1;
    var target_rotation: f32 = 0;

    var camera = c.Camera2D{
        .offset = vector2_zero,
        .target = vector2_zero,
        .rotation = 0,
        .zoom = 1,
    };

    while (!c.WindowShouldClose()) {
        if (c.IsKeyPressed(toggle_fullscreen_key)) {
            c.ToggleFullscreen();
        }

        if (c.IsKeyPressed(clear_textures_key)) {
            for (textures.items) |texture| {
                c.UnloadTexture(texture);
            }
            textures.clearRetainingCapacity();
        }

        const mouse_wheel_move = c.GetMouseWheelMove();
        const mouse_position = c.GetMousePosition();

        if (mouse_wheel_move != 0) {
            if (c.IsKeyDown(c.KEY_LEFT_SHIFT)) {
                target_rotation += mouse_wheel_move * rotation_increment;
                focusCamera(&camera, mouse_position);
            } else {
                target_zoom = std.math.max(target_zoom + mouse_wheel_move * zoom_increment, zoom_increment);
                focusCamera(&camera, mouse_position);
            }
        }

        if (c.IsMouseButtonDown(c.MOUSE_MIDDLE_BUTTON)) {
            focusCamera(&camera, mouse_position);
            target_zoom = 1;
        }

        const frame_time = c.GetFrameTime();
        camera.zoom *= std.math.pow(f32, target_zoom / camera.zoom, frame_time / zoom_duration);
        camera.rotation = c.Lerp(camera.rotation, target_rotation, frame_time / rotation_duration);

        if (c.IsMouseButtonDown(c.MOUSE_LEFT_BUTTON)) {
            const translation = c.Vector2Negate(c.Vector2Scale(c.GetMouseDelta(), 1 / target_zoom));
            camera.target = c.Vector2Add(camera.target, c.Vector2Rotate(translation, -camera.rotation * c.DEG2RAD));
        }

        if (c.IsKeyPressed(cycle_filter_key)) {
            texture_filter = @mod(texture_filter + 1, 3);
            for (textures.items) |texture| {
                c.SetTextureFilter(texture, texture_filter);
            }
        }

        if (c.IsFileDropped()) {
            const dropped_files = c.LoadDroppedFiles();
            defer c.UnloadDroppedFiles(dropped_files);

            for (dropped_files.paths[0..dropped_files.count]) |dropped_file_path| {
                var texture = c.LoadTexture(dropped_file_path);
                if (texture.id == 0) continue;
                c.GenTextureMipmaps(&texture);
                if (texture.mipmaps == 1) {
                    std.debug.print("{s}", .{"Mipmaps failed to generate!\n"});
                }
                c.SetTextureFilter(texture, texture_filter);
                try textures.append(texture);
            }
        }

        { // Drawing
            c.BeginDrawing();
            defer c.EndDrawing();

            c.ClearBackground(c.WHITE);

            var x: i32 = 0;

            { // Camera 2D
                c.BeginMode2D(camera);
                defer c.EndMode2D();

                for (textures.items) |texture| {
                    c.DrawTexture(texture, x, 0, c.WHITE);
                    x += texture.width;
                }
            }
        }
    }
}
