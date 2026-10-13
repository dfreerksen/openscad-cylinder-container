# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This directory holds OpenSCAD source files for a 3D-printable parametric, threaded, knurled cylinder container. The bottom is a solid block drilled with a pattern of holes (an ammo holder, one cartridge per hole) and the top is a hollow screw-on lid. The `README.md` is still a stub.

- `openscad-cylinder-container.scad` — the actual project (separate top/bottom parts), authored by David Freerksen. This is the file to edit for design changes.
- `caliber/*.scad` — per-caliber presets (`22-lr`, `38-special`, `30-30-win`, `9mm`). Each one defines the size-specific variables; exactly one is `include`d by the main file.
- `threads.scad` — vendored library providing `ScrewThread`, `ScrewHole`, `MetricBolt`, `MetricNut`, etc. (from https://github.com/rcolyer/threads-scad/). Treat as third-party; don't modify unless fixing a vendoring issue.
- `knurled.scad` — vendored library providing `knurled_cylinder` for generating knurled grip surfaces (from https://github.com/smkent/knurled-openscad/). Treat as third-party.
- `*.stl` — exported output, named after the caliber (e.g. `38-special.stl`). Ignored via `.gitignore`.

The main file pulls in the libraries via `use <threads.scad>` / `use <knurled.scad>` and the preset via `include <caliber/...>`, so the relative layout must be kept.

## Rendering / previewing

There is no OpenSCAD CLI on PATH; the only install is the GUI app at `/Applications/OpenSCAD.app`. To render or export from the command line, invoke the binary inside the app bundle:

```bash
/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD openscad-cylinder-container.scad -o 9mm.stl
```

For a quick syntax/geometry check without a full export (fast preview resolution, `$preview` is true):

```bash
/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD openscad-cylinder-container.scad -o preview.png
```

Do not add `--render` for the quick check: it forces a full render (`$preview` is false), so threads and knurling are generated, same as an STL export. Use it only when a PNG of the finished geometry is wanted.

Note: threads and knurling are intentionally skipped when `$preview` is true (see `if (!$preview)` guards) to keep interactive preview fast — they only generate in a full render/export. The hole pattern does render in preview.

The caliber is chosen by which `include` line is uncommented in the main file, not by a CLI flag — switch the include before exporting, and name the STL to match.

## Caliber presets

The size-specific variables are commented out in the main file's Customizer sections and are supplied by the preset instead:

- `internal_diameter` — diameter of the hole field / lid interior
- `hole_diameter`, `hole_count`, `hole_spacing`, `hole_gap`
- `bottom_height` — hole depth (how much of the cartridge sits in the base)
- `top_height` — written as `<cartridge overall length> - bottom_height`, i.e. how far the cartridge sticks out above the base

The `/* Caliber Overrides */` block sits after `module __Customizer_Limit__ () {}`, so these values do not appear in the Customizer; edit the preset file. Only one `include` may be active — with none, those variables are undefined and the `assert`s fail.

To add a caliber: copy an existing file in `caliber/`, set all seven variables, and add a (commented) `include` line for it alongside the others.

## Architecture: `openscad-cylinder-container.scad`

Customizer tabs (`/* [Display] */`, `/* [Properties] */`, `/* [Holes] */`, `/* [Thread] */`, `/* [Knurling] */`, `/* [Bottom] */`, `/* [Top] */`) drive the shared variables at the top (wall, thread, and knurling settings); the preset supplies the rest. Then:

- `container_bottom()` — solid body with external threads at the top (`ScrewThread` with `tolerance = -thread_tolerance`), a knurled grip band below the thread, and a chamfered base. `container_holes()` is subtracted from it. The old hollow-interior cut is left commented out — the bottom is intentionally solid apart from the holes.
- `container_top()` — hollow lid with internal threads (`ScrewThread` subtracted via `difference()`, rotated 180°, with the same `-thread_tolerance` as the bottom, so the male and female threads are cut at the same diameter) and a matching knurled band. Its interior height is `modified_top_height = top_height + thread_height + hole_gap`: the thread engagement plus clearance for the protruding cartridges.
- `container_holes()` — the hole pattern, `bottom_height` deep. Holes are laid out in concentric rings: ring 0 is a single center hole, and ring `k` sits at radius `k * ring_pitch` where `ring_pitch = hole_diameter + hole_gap + hole_spacing`. The helper functions (`hole_ring_angle_step`, `hole_ring_size`, `hole_cum_count`, `hole_cutoff_ring`) size each ring so neighbours are at least one pitch apart (1, 6, 12, 18, …), odd rings are rotated half a step for a staggered look, and the outermost ring is trimmed so the total equals `hole_count`.

`render_part` ("both" / "top" / "bottom") controls what the main rendering logic places, with `render_gap` spacing the two parts apart when both are shown.

Things to preserve when editing:

- `internal_diameter` and `wall_thickness` drive the outer body diameter (`internal_diameter + 3*wall_thickness`) and the thread diameter (`internal_diameter + 2*wall_thickness`) in both `container_bottom()` and `container_top()` — if you change one, check the other module for matching math so the threads still mate.
- `hole_gap` affects spacing math and lid clearance only, not the printed hole diameter (`hole_diameter` is cut as-is).
- Rings are capped at what fits inside `internal_diameter`. If `hole_count` is more than fits, the model silently produces fewer holes rather than erroring — when changing a preset's `hole_count` or `hole_diameter`, check that `internal_diameter` is large enough.
