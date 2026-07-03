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

## Headless rendering & PNG previews (this container)

OpenSCAD 2021.01 is installed at `/usr/bin/openscad`. Generating a **PNG preview**
needs an OpenGL context, which this headless box lacks — a bare
`openscad --preview -o out.png ...` dies with `Can't create OpenGL OffscreenView`.
Wrap it in a virtual framebuffer (`xvfb-run` is available):

```bash
xvfb-run -a -s "-screen 0 1400x800x24" openscad --preview \
  --imgsize=1400,800 --colorscheme=Cornfield --projection=o \
  --camera=<tx>,<ty>,<tz>,<rx>,<ry>,<rz>,<dist> \
  -o out.png file.scad
```

Camera / framing gotchas learned the hard way:
- `--camera=tx,ty,tz,rx,ry,rz,dist` is the **gimbal** form (look-at point + euler
  angles + distance). `rx=0` looks straight **down** (top view); `rx≈90` is a side
  elevation; `rx≈55` gives a 3/4 view.
- `--viewall` does **not** frame things well here (it leaves the model tiny), so set
  an explicit `dist` and point the look-at `tx,ty` at the model centre yourself.
  A single 1u keycap is ~18mm; the whole Planck row is ~230mm — pick `dist` to match.
- `--projection=o` = orthographic (clean flat-on shots), `p` = perspective (nicer 3/4).
- STL export (`-o out.stl`) needs **no** GL and no Xvfb; only PNG preview does.

## `use` vs `include` — the special-variable propagation bug (READ THIS)

This bit us hard and is the single most important gotcha in this repo on the
installed OpenSCAD (2021.01).

**Symptom:** every profile produced the *same* keycap and `legend()` drew nothing.
Measuring exported STL heights, `dcs_row(3)`, `sa_row(3)`, `g20_row(3)` all came out
identical (~12mm) instead of their real heights, and legended keys had smooth tops.

**Root cause:** KeyV2 profile/modifier functions (`g20_row`, `legend`, …) work by
setting special (`$`) variables that `key()` reads. On OpenSCAD 2021.01 a module
imported with **`use`** does **not** see `$` variables set by the caller (they'd have
to be passed as parameters); only **`include`** propagates them. The stock
`includes.scad` did `use <src/key.scad>`, so none of the profile/legend settings
reached `key()` — everything collapsed to `settings.scad` defaults. This is a
documented, version-sensitive behaviour: OpenSCAD [#3881] and [#5924] (it changed
between 2021.01 and recent nightlies), and KeyV2 [#213]. A newer OpenSCAD *dev
snapshot* (which the README recommends) behaves differently.

**Fix applied here:** `includes.scad` now `include`s `src/key.scad` instead of
`use`-ing it, with `$using_customizer = true` to suppress key.scad's auto
`example_key()`. After this, profiles differentiate correctly (SA ~12.5, OEM ~9.5,
DSA ~8.1, G20 ~7.1, DCS ~6.8 mm) and `legend()` / `front_legend()` work normally —
no `keytext()` workarounds needed. If you ever see all-identical keys or missing
legends again, check that this `include` is intact.

[#3881]: https://github.com/openscad/openscad/issues/3881
[#5924]: https://github.com/openscad/openscad/issues/5924
[#213]:  https://github.com/rsheldiii/KeyV2/issues/213

## Legend / text notes

- `legend(text, position=[0,0], size, font)` and `front_legend(...)` set the legend
  via the `$legends` / `$front_legends` special variables; `$inset_legend_depth`
  (default 0.2) is how deep an inset legend is cut, `$outset_legends=true` raises it
  instead. Chain the modifier before `key()`: `legend("Q") g20_row(3) key();`.
- **Multimaterial / separate-body legends** (e.g. flush legends in a second colour):
  render the two aligned bodies under the same `legend()`+profile —
  `key(true)` (body with the pocket) and `dished(){ legends($inset_legend_depth); }`
  (the plug that fills it). Export each with `-D 'EXPORT_PART="keys"'` /
  `"legends"`. See `examples/g20_flush_multimaterial_legend.scad`.
- **Fonts** are fine — `DejaVu Sans Mono:style=Book` is installed (`fc-list` for the
  rest).
- **Colours**: `key()` / `keytext()` wrap output in `color($primary_color)` /
  `color($secondary_color)` / `color($tertiary_color)`. Those inner `color()` calls
  override any outer `color(...)`, so recolour by setting the `$*_color` variables.
- **Flush geometry z-fights in the optical preview** (a legend exactly level with the
  surface can look faint/patchy on screen) — the STL is still correct. Keep legends
  flush for slicing; only nudge them ~0.1mm proud if you specifically need a clean
  screenshot.

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
