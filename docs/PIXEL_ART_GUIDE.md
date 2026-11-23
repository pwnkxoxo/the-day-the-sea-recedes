# Pixel-Art & Character Pipeline Guide
**Project:** *The Day the Sea Recedes*  
**Engine:** Godot Engine 4.7.2 stable official  
**Resolution Standard:** 320×180 Viewport (16:9 Retro Aspect Ratio)  
**Established:** Milestone 20

---

## 1. Overview & Aesthetic Philosophy

*The Day the Sea Recedes* employs a classic Game Boy Advance (GBA) top-down coastal aesthetic. The visual tone is atmospheric, subdued, and evocative—featuring weathered wood docks, muted tidal sand, deep oceanic teal waters, and historic stone ruins.

All visuals adhere strictly to non-antialiased nearest-neighbor rendering with pixel-perfect coordinate snapping.

---

## 2. Core Display & Rendering Standards

| Parameter | Specification | Project Configuration Path |
| :--- | :--- | :--- |
| **Native Base Viewport** | 320 × 180 pixels | `display/window/size/viewport_width=320`<br>`display/window/size/viewport_height=180` |
| **Window Override (4x Scale)** | 1280 × 720 pixels | `display/window/size/window_width_override=1280`<br>`display/window/size/window_height_override=720` |
| **Stretch Mode** | `viewport` (Aspect: `keep`) | `display/window/stretch/mode="viewport"` |
| **Default Texture Filter** | Nearest Neighbor (`0`) | `rendering/textures/canvas_textures/default_texture_filter=0` |
| **Transform Pixel Snap** | Enabled (`true`) | `rendering/2d/snap/snap_2d_transforms_to_pixel=true` |
| **Vertex Pixel Snap** | Enabled (`true`) | `rendering/2d/snap/snap_2d_vertices_to_pixel=true` |

---

## 3. Grid & Dimension Standards

### 3.1 Base Grid
- **Tile Grid:** 16 × 16 pixels.
- All environmental terrain (ground, paths, cliffs, water boundaries) aligns to 16×16 tile boundaries.

### 3.2 Humanoid Characters (Sens & NPCs)
- **Sprite Dimensions:** 16 × 24 pixels (1 tile wide, 1.5 tiles tall).
- **Collision Boundary:** 12 × 14 pixels rectangle, centered at `(0, 0)` on the bottom half of the character body.
- **Visual Origin:** The feet touch the bottom tile baseline. In node local coordinates, the `Sprite2D` is offset to `Vector2(0, -5)` relative to the root `CharacterBody2D`, ensuring proper foot-level collision and depth sorting.
- **Interaction Radius:** 20.0 pixels circle around the character base.

### 3.3 Props and Interactive Objects
- **Small Objects (Shells, Conch, Books):** 16 × 16 pixels.
- **Medium Objects (Chests, Crates, Wagons):** 32 × 16 or 32 × 32 pixels.
- **Large Landmarks (Shipwreck, Town Hall):** Integer tile multiples (e.g. Shipwreck: 160 × 64 pixels; Town Hall: 112 × 72 pixels).

---

## 4. Directional & Naming Conventions

All character sprites adhere to strict 4-direction cardinal orientation.

### 4.1 Asset Filenames
```text
art/
├── sens/
│   ├── sens_down.png   (16x24, facing South / Down - Default)
│   ├── sens_up.png     (16x24, facing North / Up)
│   ├── sens_left.png   (16x24, facing West / Left)
│   └── sens_right.png  (16x24, facing East / Right)
└── npcs/
    ├── elder_cael.png  (16x24, baseline down / front)
    ├── villager.png    (16x24, baseline down / front)
    └── <name>_<dir>.png (directional variations)
```

### 4.2 Standard Animation States
Every character controller implements the canonical 8-state cardinal animation layout:

| State Key | Direction | Movement | Visual Behavior |
| :--- | :--- | :--- | :--- |
| `idle_down` | `Vector2.DOWN` | None | Static 16×24 down texture |
| `idle_up` | `Vector2.UP` | None | Static 16×24 up texture |
| `idle_left` | `Vector2.LEFT` | None | Static 16×24 left texture |
| `idle_right` | `Vector2.RIGHT` | None | Static 16×24 right texture |
| `walk_down` | `Vector2.DOWN` | `(0, speed)` | Down texture + 1px step bobbing |
| `walk_up` | `Vector2.UP` | `(0, -speed)` | Up texture + 1px step bobbing |
| `walk_left` | `Vector2.LEFT` | `(-speed, 0)` | Left texture + 1px step bobbing |
| `walk_right` | `Vector2.RIGHT` | `(speed, 0)` | Right texture + 1px step bobbing |

---

## 5. Palette & Color Standards

Textures must maintain crisp pixel borders without anti-aliasing or alpha bleed:

- **Shore & Silt:** Subdued yellows, driftwood tans, weathered sand tones (`#564c38`, `#948566`, `#baad87`).
- **Coastal Ocean:** Deep marine teal, calm slate blue, foamy sea-green crests (`#1d3840`, `#2b5361`, `#4e8294`).
- **Settlement & Architecture:** Muted timber brown, oxidized clay, gray cliff stone (`#3f2e22`, `#594231`, `#735640`, `#40484a`).
- **Vegetation:** Earthy olive and sea moss green (`#385938`, `#4b734b`).

---

## 6. Texture Import Settings (.import)

All 2D textures must use Godot's lossless pixel-art import profile:

```ini
[params]
compress/mode=0              ; Lossless PNG compression
compress/high_quality=false
mipmaps/generate=false       ; No mipmaps (prevents blurry subpixel sampling)
process/fix_alpha_border=true
```

---

## 7. Reusability for Future NPC Pipelines

Future NPC entities (e.g. in Milestone 23 & 25) will inherit or share this pipeline:
1. Provide 16×24 pixel sprites named `<npc>_<dir>.png`.
2. Connect to the 8 standard animation states (`idle_*` and `walk_*`).
3. Maintain collision origin at `(0, 0)` with `Sprite2D` offset at `(0, -5)`.
4. Use `TEXTURE_FILTER_NEAREST` to guarantee pixel-sharp visual consistency across all zoom and display scales.
