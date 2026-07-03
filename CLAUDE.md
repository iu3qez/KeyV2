# CLAUDE.md

Guidance for working in this repository. **Project goal for this workspace: generate a full keycap layout for a Planck keyboard** (a 4×12 ortholinear 40% board) using KeyV2.

## What this repo is

KeyV2 is a parametric mechanical **keycap** library written in **OpenSCAD**. It builds
single keycaps or whole keyboard layouts as 3D-printable models. There is no compiler
step and no runtime other than OpenSCAD itself — you write a `.scad` file that includes
the library and describes what to render, then render it to `.stl`.

- Language: OpenSCAD (`.scad`). Helper build scripts are Ruby (`*.rb`) and Node/gulp (`gulpfile.js`), but they are optional.
- OpenSCAD is installed here at `/usr/bin/openscad` (version 2021.01).

## How the code is structured

- `includes.scad` — the single include that pulls in the whole library. **Every top-level `.scad` you write should start with `include <includes.scad>`** (path is relative to your file, and your file must live at the repo root for that relative path to resolve — see "Rendering" below).
- `keys.scad` — the default entry point / scratch file. Shows the DSL: `dcs_row(5) legend("⇪", size=9) key();`
- `src/key.scad` — the actual key geometry pipeline (note: no "s"). Loaded with `use <>`, not `include <>`.
- `src/settings.scad` — every tunable (~40+ `$`-prefixed special variables): dimensions, dish type, stem type, fonts, wall thickness, tilt, etc. Read this before changing behavior.
- `src/key_profiles/` — sculpted profiles: `dcs`, `oem`, `dsa`, `sa`, `dss`, `asa`, `g20`, `hipro`, `mt3`, `grid`, `cherry`, `typewriter`, `hex`. Exposed as `<profile>_row(row, column)` modules and dispatched by `key_profile(type, row, column)`.
- `src/key_types.scad` — named special keys: `spacebar()`, `lshift()`, `rshift()`, `backspace()`, `enter()`, `iso_enter()`, numpad keys, etc.
- `src/key_sizes.scad` — unit-size modifiers like `u(n)`, `1u()`, `2u()`, `2uh()`.
- `src/key_transformations.scad` — most modifier functions: `legend()`, `front_legend()`, `translate_u()`, `stabilized()`, `sideways()`, stem/dish overrides, etc.
- `src/stems/`, `src/dishes/`, `src/shapes/`, `src/supports/`, `src/hulls/` — pluggable geometry pieces, each with a "selector" module in the parent `.scad`.
- `src/layouts/` — full-keyboard layouts. **This is the important directory for the Planck goal.**

## The DSL (how keys are described)

Keys are built by chaining modifier modules that set `$` variables, terminated by `key()`.
Modifiers are applied left-to-right; the rightmost thing is `key()` (or `children()` for artisans):

```
u(1.25) oem_row(3) legend("ctrl", size=4.5) key();
```

You can also set settings directly as special variables before the call:

```
$stem_inset = 1;
sa_row(2) 2u() key();
```

## Layouts (the Planck goal)

Layouts live in `src/layouts/<board>/` and are wired into the build via
`src/key_layouts.scad` (which `includes.scad` pulls in). A layout is a 2D array of key
lengths (in units; `0` = empty slot, negative = gap) plus a `module <name>(profile, ...)`
that calls the shared `layout(...)` engine in `src/layouts/layout.scad`.

**Planck layouts already exist:**
- `src/layouts/planck/default.scad` → module `planck_default(profile, column_sculpt_profile="2hands")`. A 4-row grid with a center gap in rows 0–2 and a `2`-unit (2u) key in the bottom row for the spacebar. Ships with `planck_default_legends` (QWERTY + Fn/Lower/Raise).
- `src/layouts/planck/mit.scad` → module `planck_mit(profile)`. Plain 4×12 grid, all 1u (the "MIT" bottom-row variant uses a 2u spacebar via key length; here it's uniform 1u).

Render the whole Planck keycap set with, e.g.:

```
include <includes.scad>
planck_default("dsa") key();
```

The `layout()` engine (`src/layouts/layout.scad`) handles per-row sculpting, double-axis
column sculpting (`column_sculpt_profile`: `"2hands"`, `"1hand"`, `"cresting_wave"`),
key placement via `translate_u()`, and auto-selecting special key modules (spacebar at
6.25u, backspace at 2u, shifts at 2.25/2.75u). Profiles like DSA/G20/grid are uniform
(non-sculpted) and are the natural choice for an ortholinear board like the Planck;
sculpted profiles (DCS/OEM/SA/DSS/Cherry) will slope across rows.

To generate legends per key, pass `legends=` (and optionally `front_legends=`) 2D arrays
to `layout()`, matching the shape of the layout array — see how `default.scad` defines
`planck_default_legends` (note the engine indexes `legends[row][column]`).

## Rendering / running

There is no test suite. "Building" means rendering a `.scad` to `.stl` with OpenSCAD.

**Important:** OpenSCAD resolves `include`/`use` paths relative to the `.scad` file, so a
file that does `include <includes.scad>` must sit at the **repo root**. Put scratch render
files at the repo root (they match `*.scad.stl` / `models/*` in `.gitignore`, but the
`.scad` itself does not — clean up temporary `.scad` files or name them so they aren't committed).

```bash
# single key — renders in a few seconds
openscad -o out.stl your_file.scad

# a full 48-key Planck layout is heavy — allow several minutes and raise any timeout
openscad -o planck.stl planck_render.scad
```

Notes:
- A full layout renders all 48 keycaps as one CGAL solid and can take minutes. For iteration, render a single row or key first.
- Preview (F5 in the GUI) is fast; a full CGAL render (`-o file.stl`, F6) is slow.
- `gulpfile.js` provides `gulp compile` to auto-render changed root `*.scad` files (needs `yarn install`); optional, not required.
- `models.rb` / `openscad.rb` batch-render individual keycaps across profiles/rows/sizes into `./models/`.

## Customizer

`customizer.scad` is a large **auto-generated** single-file bundle for the OpenSCAD/Thingiverse
Customizer GUI. Do not hand-edit it — it is expanded from the `src/` files (`expand.rb`,
`customizer_base.scad`). Edit the real sources under `src/` instead.

## Conventions when adding/altering layouts

- Match the existing style: a layout file `use`s/`include`s `../layout.scad`, defines a
  `*_layout` array (and optional `*_legends`), and exposes one `module <name>(profile, ...)`.
- Register new layout files in `src/key_layouts.scad` so `includes.scad` picks them up.
- Keep the 2D legend arrays index-aligned with the layout array (`[row][column]`), accounting
  for any `0` gap columns in the layout that the engine skips.
- Prefer editing `src/` sources over the generated `customizer.scad`.
