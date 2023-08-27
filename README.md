# Zig + BGFX Example Project
A small example project that shows how to use BGFX from Zig, based on Ziggy (https://github.com/heretique/ziggy)

## Notes
- Building will build BGFX's shader compiler called `shaderc` alongside the app.
- Precompiled shaders have been included for OpenGL/OSX - these are the .bin files under assets/shaders/cubes.
  - To run on other platforms, replace these files with your own compiled shaders.

### TODO
- Maybe there could be a build step that compiles shaders?
