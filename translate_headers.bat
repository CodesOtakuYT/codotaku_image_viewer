@echo off
mkdir src/gen
zig translate-c -lc headers/raylib.h > src/gen/raylib.zig