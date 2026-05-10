# Scythe

Scythe is a dynamic map loader for Garry's Mod. Instead of depending on the Source engine, Scythe completely re-implements a massive chunk of the engine in pure Lua.

`gallery`

## How it Works
Players load a bare bones `empty.bsp` map. This is what the engine operates on. From the Lua environment, Scythe kicks in and decodes the desired [BSP file](https://developer.valvesoftware.com/wiki/BSP_(Source)), doing things notionally similar to what the engine does.

Rendering is accomplished through the [mesh](https://wiki.facepunch.com/gmod/mesh) library (a wrapper around `CMeshBuilder`.) A rendering hook is then used to indicate which meshes are to be rendered during the frame.

Level geometry collisions are performed through the [TestCollision](https://wiki.facepunch.com/gmod/ENTITY:TestCollision) hook on a single, invisible entity. Traces are calculated from scratch and the result is overridden through the hook.

## Why
The beloved Source engine, for all its achievements, has a long list of weaknesses and arbitrary constraints. Since the source code is off-limits, modders have long been subjected to putting up with certain technical limitations. Scythe is an exercise in circumnavigating the engine and its limitations and, thus, it is a love letter to the Source engine modding community.

## Possibilities
### Maximum Map Size
The Hammer editor imposes a maximum map size of 65535 units in each cardinal axis. While the editor can be hacked to work around this, maps larger than this are increasingly likely to run into other limitations that require direct engine modifications.

The Garry's Mod branch of the engine clamps entity positions in the range of `[-131072, 131071]`. Scythe can potentially load maps up to this size for a total of a 400% size increase.

### Maximum Faces / Brushes / Vertices / Textures
Almost every component of a BSP map file is hard capped at more or less arbitrary values. The line had to fall somewhere after all. Many of these maximum values can be seen [here](https://github.com/ValveSoftware/source-sdk-2013/blob/3300848d8a25ef6403c91f82a4cd97d6daefbc06/src/public/bspfile.h#L60-L102).

Since Scythe circumnavigates the engine, these limitations may be redefined to allow for maps which are otherwise incompatible with the engine.

### Simultaneously-Loaded Maps
The engine was only ever intended to load one map at a time. With Scythe, we can make use of out-of-bounds space to concurrently load an entirely different map. It's possible to load up to 64 conventionally maximum-sized maps at a time. Potentially even more, as long as they're smaller.

### Rendering Improvements
We're already re-implementing the world rendering pipeline. Why not extend upon it and fix some graphical bugs along the way? Players may be allowed to choose between legacy rendering and any number of experimental overhauls.

### Beyond
The list of possibilities is truly massive and certainly beyond what I've listed so far. For just the rest of my imagination:
- Multiple skyboxes
- In-game, real-time, collaborative map editor
- Parallax-corrected cubemaps
- Manipulating static surface overlay textures
- Multiple simultaneously-visible reflecting surfaces
- Pak filesystem "overlay" for overriding embedded resources
- Compatibility with off-branch games (e.g. Portal, CS:GO)
- Water volume manipulation
- Static prop manipulation

## Contributing
Check out the [roadmap](ROADMAP.md) to see what's planned.

### Building
Scythe is written in [Teal](https://teal-language.org/) and compiles to Lua using the [Cyan](https://github.com/teal-language/cyan) build system.

1. Install [LuaRocks](https://luarocks.org/)
2. `luarocks install cyan`
3. `cyan build`

The repository includes a utility script for automatic recompilation of modified source files. You can run it with `make live` or directly with `./auto_build.sh`.

### Recommended Extensions
- [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
- [GLua API Definitions](https://github.com/luttje/glua-api-snippets#visual-studio-code)
- [Teal](https://open-vsx.org/vscode/item?itemName=pdesaulniers.vscode-teal)
- [EditorConfig](https://open-vsx.org/vscode/item?itemName=EditorConfig.EditorConfig)
