const std = @import("std");
const raylib = @import("gen/raylib.zig");

const Texture2DArrayList = std.ArrayList(raylib.Texture2D);

const title = "Codotaku Image Viewer";
const cycle_filter_key = raylib.KEY_P;
const clear_textures_key = raylib.KEY_BACKSPACE;
const toggle_fullscreen_key = raylib.KEY_F;
const zoom_increment = 0.1;
const vector2_zero = raylib.Vector2Zero();
const rotation_increment = 15;
const rotation_duration = 0.2;
const zoom_duration = 0.2;

fn focusCamera(camera: *raylib.Camera2D, screen_position: raylib.Vector2) void {
    camera.*.target = raylib.GetScreenToWorld2D(screen_position, camera.*);
    camera.*.offset = screen_position;
}

fn add_texture(fileName: [*c]const u8, textures: *Texture2DArrayList, texture_filter: c_int) error{OutOfMemory}!void {
    var texture = raylib.LoadTexture(fileName);
    if (texture.id == 0) return;
    raylib.GenTextureMipmaps(&texture);
    if (texture.mipmaps == 1) {
        std.debug.print("{s}", .{"Mipmaps failed to generate!\n"});
    }
    raylib.SetTextureFilter(texture, texture_filter);
    try textures.append(texture);
}

pub fn main() error{ OutOfMemory, Overflow }!void {
    raylib.SetConfigFlags(raylib.FLAG_WINDOW_RESIZABLE | raylib.FLAG_VSYNC_HINT);
    raylib.InitWindow(800, 600, title);
    defer raylib.CloseWindow();

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var textures = Texture2DArrayList.init(allocator);
    defer {
        for (textures.items) |texture| {
            raylib.UnloadTexture(texture);
        }
        textures.deinit();
    }

    var texture_filter = raylib.TEXTURE_FILTER_TRILINEAR;
    var target_zoom: f32 = 1;
    var target_rotation: f32 = 0;

    var camera = raylib.Camera2D{
        .offset = vector2_zero,
        .target = vector2_zero,
        .rotation = 0,
        .zoom = 1,
    };

    const args = try std.process.argsAlloc(std.heap.c_allocator);
    for (args[1..]) |arg| {
        try add_texture(arg, &textures, texture_filter);
    }
    std.process.argsFree(std.heap.c_allocator, args);

    while (!raylib.WindowShouldClose()) {
        if (raylib.IsKeyPressed(toggle_fullscreen_key)) {
            raylib.ToggleFullscreen();
        }

        if (raylib.IsKeyPressed(clear_textures_key)) {
            for (textures.items) |texture| {
                raylib.UnloadTexture(texture);
            }
            textures.clearRetainingCapacity();
        }

        const mouse_wheel_move = raylib.GetMouseWheelMove();
        const mouse_position = raylib.GetMousePosition();

        if (mouse_wheel_move != 0) {
            if (raylib.IsKeyDown(raylib.KEY_LEFT_SHIFT)) {
                target_rotation += mouse_wheel_move * rotation_increment;
                focusCamera(&camera, mouse_position);
            } else {
                target_zoom = std.math.max(target_zoom + mouse_wheel_move * zoom_increment, zoom_increment);
                focusCamera(&camera, mouse_position);
            }
        }

        if (raylib.IsMouseButtonDown(raylib.MOUSE_MIDDLE_BUTTON)) {
            focusCamera(&camera, mouse_position);
            target_zoom = 1;
        }

        const frame_time = raylib.GetFrameTime();
        camera.zoom *= std.math.pow(f32, target_zoom / camera.zoom, frame_time / zoom_duration);
        camera.rotation = raylib.Lerp(camera.rotation, target_rotation, frame_time / rotation_duration);

        if (raylib.IsMouseButtonDown(raylib.MOUSE_LEFT_BUTTON)) {
            const translation = raylib.Vector2Scale(raylib.GetMouseDelta(), -1 / target_zoom);
            camera.target = raylib.Vector2Add(camera.target, raylib.Vector2Rotate(translation, -camera.rotation * raylib.DEG2RAD));
        }

        if (raylib.IsKeyPressed(cycle_filter_key)) {
            texture_filter = @mod(texture_filter + 1, 3);
            for (textures.items) |texture| {
                raylib.SetTextureFilter(texture, texture_filter);
            }
        }

        if (raylib.IsFileDropped()) {
            const dropped_files = raylib.LoadDroppedFiles();
            defer raylib.UnloadDroppedFiles(dropped_files);

            for (dropped_files.paths[0..dropped_files.count]) |dropped_file_path| {
                try add_texture(dropped_file_path, &textures, texture_filter);
            }
        }

        { // Drawing
            raylib.BeginDrawing();
            defer raylib.EndDrawing();

            raylib.ClearBackground(raylib.WHITE);

            var x: i32 = 0;

            { // Camera 2D
                raylib.BeginMode2D(camera);
                defer raylib.EndMode2D();

                for (textures.items) |texture| {
                    raylib.DrawTexture(texture, x, 0, raylib.WHITE);
                    x += texture.width;
                }
            }
        }
    }
}
