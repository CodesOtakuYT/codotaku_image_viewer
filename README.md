## Codotaku Image Viewer 0.1.0
A tiny fast simple cross platform open source image viewer made using Ziglang and Raylib.
No GUI, so you can focus on viewing the images!
Around 1 mb executable with support for most popular image formats even PSD!
- import multiple images by dropping them into the window
- toggle image texturing filter (NEAREST, BILINEAR, TRILINEAR) by pressing `P`
- unload and clear all the imported textures by pressing `Backspace`.
- toggle fullscreen by pressing `F`
- move around by holding down `left mouse button` anywhere in the window and drag.
- zoom towards the mouse and outwards from it by using the `Mouse Wheel`
- hold `Left Shift Key` to rotate instead of zoom around the mouse.
- easily cross compile to any platform, thanks to Zig build system.

Make sure to clone the repo recursively with the submodule(s).
```sh
git clone --recursive https://github.com/CodesOtakuYT/codotaku_image_viewer
```
Run this in the root directory of the repo to build a fast release binary
You need zig!
```sh
zig build run -Doptimize=ReleaseFast
```
This open source project is open to contributions!
