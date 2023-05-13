## Codotaku Image Viewer 0.1.0
A tiny fast simple cross platform open source image viewer made using Ziglang and Raylib.
No GUI, so you can focus on viewing the images!
Around 1 mb executable with support for most popular image formats even PSD!
- import multiple images or directories recursively by dropping them into the window or in the command line arguments.
- If numbers are included in the command line arguments, it will switch the max recursions for the next arguments and drops.
- toggle image texturing filter (NEAREST, BILINEAR, TRILINEAR) by pressing `P`
- unload and clear all the imported textures by pressing `Backspace`.
- toggle fullscreen by pressing `F`
- move around by holding down `left mouse button` anywhere in the window and drag.
- zoom towards the mouse and outwards from it by using the `Mouse Wheel`
- go back to 1:1 zoom by pressing `middle mouse button` (mouse wheel)
- hold `Left Shift Key` to rotate instead of zoom around the mouse.
- easily cross compile to any platform, thanks to Zig build system.
- 0.1.0 fully created in a youtube video tutorial! https://www.youtube.com/watch?v=DMURJbpo94g

1 - Make sure to clone the repo recursively with the submodule(s), cd into the directory.

2 - Setup project dependencies like translating C header files.

You need zig installed in your system and available in the environment variables!

3 - Run this in the root directory of the repo to build a fast release binary.

4 - Enjoy!

This open source project is open to contributions!
```sh
git clone --recursive https://github.com/CodesOtakuYT/codotaku_image_viewer
cd codotaku_image_viewer
zig run setup.zig
zig build run -Doptimize=ReleaseFast
```
