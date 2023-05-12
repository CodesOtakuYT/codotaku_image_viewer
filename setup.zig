const std = @import("std");

// TODO: Optimize (eg. allocations) and cleanup
fn translate_headers(child_allocator: std.mem.Allocator) !void {
    const current_working_directory = std.fs.cwd();
    try current_working_directory.makePath("src/gen");

    var headers_iterable_directory = try current_working_directory.openIterableDir("headers", .{});
    defer headers_iterable_directory.close();

    var headers_iterator = headers_iterable_directory.iterate();
    while (try headers_iterator.next()) |entry| {
        if (entry.kind != .File) continue;
        const input_path = try std.fs.path.join(child_allocator, &.{ "headers", entry.name });
        defer child_allocator.free(input_path);
        const output_name = try std.fmt.allocPrint(child_allocator, "{s}{s}", .{ std.fs.path.stem(input_path), ".zig" });
        defer child_allocator.free(output_name);

        const output_path = try std.fs.path.join(child_allocator, &.{ "src/gen", output_name });
        defer child_allocator.free(output_path);

        const result = try std.ChildProcess.exec(.{
            .allocator = child_allocator,
            .argv = &.{ "zig", "translate-c", "-lc", input_path },
            .max_output_bytes = std.math.maxInt(usize),
        });
        defer {
            child_allocator.free(result.stdout);
            child_allocator.free(result.stderr);
        }

        if (result.stderr.len > 0) {
            std.debug.panic("Error: {s}", .{result.stderr});
        }

        const file = try current_working_directory.createFile(output_path, .{});
        defer file.close();

        try file.writeAll(result.stdout);
    }
}

pub fn main() !void {
    var allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(allocator.deinit() == .ok);

    var child_allocator = allocator.allocator();
    try translate_headers(child_allocator);
}
