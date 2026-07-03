include <includes.scad>

/* Full keycap set for a Planck 40% (4x12 ortholinear, MIT bottom row with a 2u
   spacebar), G20 profile, with QWERTY lettering.

   Built on the existing planck_default_layout (src/layouts/planck/default.scad):
   a 13-column grid with a center gap in rows 0-2 and, in the bottom row, a 2u
   key in the center for the spacebar. We render it with our own loop (not the
   layout() engine) because the engine only places ONE default-size legend per
   key, and we want per-key sizes plus stacked dual legends.

   Legends:
   - single char (letters, symbols, arrows): centered, BASE_SIZE
   - word legends (Esc, Ctl, Alt, Cmd, Lwr, Rse, Fn): centered, smaller WORD_SIZE
   - punctuation keys get the ANSI shifted char STACKED ABOVE the base:
       ;:   ,<   .>   /?      (base low, shifted high)
   The center 0-gap columns and the 2u spacebar carry no legend.

   Flush multimaterial legends (0.8mm), same idea as examples/g20_flush_*:
   - EXPORT_PART = "keys"    -> keycap bodies with the recess (material 1)
   - EXPORT_PART = "legends" -> flush legend plugs only        (material 2)
   - EXPORT_PART = "both"    -> two-colour preview (NOT for slicing: OpenSCAD
                               unions it into one mesh; export the two parts
                               separately and combine them in the slicer).
   The plugs are produced board-wide by (smooth board) - (recessed board).
*/

EXPORT_PART = "keys";   // "keys" | "legends" | "both"

// --- shared settings -------------------------------------------------------
$stem_support_type = "disable";   // no tines (cross-bars under the stem)
$inset_legend_depth = 0.8;        // 0.8mm flush legend
$outset_legends = false;

$primary_color   = [0.20, 0.55, 1.00];   // keycap bodies
$secondary_color = [0.20, 0.55, 1.00];
$tertiary_color  = [0.95, 0.95, 0.95];   // legends (second material)

PROFILE = "g20";
SCULPT  = "2hands";   // "2hands" | "1hand" | "cresting_wave"

// Hybrid legend fonts: a nice sans for text, DejaVu only for the keyboard
// glyphs (⇥ ⌫ ⏎ ⇧) that most sans fonts lack. Arrows render fine everywhere.
MAIN_FONT   = "Nimbus Sans";
SYMBOL_FONT = "DejaVu Sans Mono:style=Book";
function pl_font(t) = (t=="⇥"||t=="⌫"||t=="⏎"||t=="⇧") ? SYMBOL_FONT : MAIN_FONT;

// legend sizes (mm) / stacking offset (normalized: 1 ~ top_height/3.5)
BASE_SIZE = 5.5;   // single char
WORD_SIZE = 3.5;   // Esc / Ctl / ...
DUAL_SIZE = 4;     // each char of a stacked pair
DUAL_DY   = 0.55;  // vertical offset of the stacked pair

// --- gap-aware base legends (13 columns, "" at gaps and on the 2u spacebar) --
planck_g20_legends = [
  ["⇥",  "Q",   "W",   "E",   "R",   "T", "", "Y",   "U", "I", "O", "P", "⌫"],
  ["Esc","A",   "S",   "D",   "F",   "G", "", "H",   "J", "K", "L", ";", "⏎"],
  ["⇧",  "Z",   "X",   "C",   "V",   "B", "", "N",   "M", ",", ".", "/", "⇧"],
  ["Fn", "Ctl", "Alt", "Cmd", "Lwr", "",  "", "",    "Rse","←", "↓", "↑", "→"]
];

// ANSI shifted partner for the punctuation keys ("" = no dual legend)
function pl_shift(t) = t == ";" ? ":" :
                       t == "," ? "<" :
                       t == "." ? ">" :
                       t == "/" ? "?" : "";

function pl_is_word(t) = t=="Esc"||t=="Ctl"||t=="Alt"||t=="Cmd"||
                         t=="Lwr"||t=="Rse"||t=="Fn";

// build the $legends array ([text, position, size, font]) for one base char
function pl_legends(t) =
  t == "" ? [] :
  pl_shift(t) != "" ?
    [ [t,           [0,  DUAL_DY], DUAL_SIZE, pl_font(t)],            // base low
      [pl_shift(t), [0, -DUAL_DY], DUAL_SIZE, pl_font(pl_shift(t))] ] :  // shift high
  pl_is_word(t) ?
    [ [t, [0, 0], WORD_SIZE, pl_font(t)] ] :
    [ [t, [0, 0], BASE_SIZE, pl_font(t)] ];

// --- board -----------------------------------------------------------------
// One keycap. carve=true -> legend recess carved; carve=false -> smooth.
module pl_keycap(key_length, prof_row, column_value, carve, base, r, c) {
  $legends = carve ? pl_legends(base) : [];
  $front_legends = [];
  key_profile(PROFILE, prof_row, column_value) u(key_length) cherry() {
    $row = r;
    $column = c;
    if (key_length == 2) backspace() { key(); }   // 2u spacebar
    else key();
  }
}

// One flush legend plug = (smooth cap) INTERSECT (the exact cutter key() uses
// to carve the pocket: legends($inset_legend_depth)). A single intersection,
// so there is no coincident dished-top surface being differenced against
// itself — which is what left sliver shards in the (smooth - recessed) version.
module pl_plug(key_length, prof_row, column_value, base, r, c) {
  key_profile(PROFILE, prof_row, column_value) u(key_length) {
    $row = r;
    $column = c;
    $front_legends = [];
    intersection() {
      let($legends = [])
        cherry() { if (key_length == 2) backspace() { key(); } else key(); }
      let($legends = pl_legends(base))
        legends($inset_legend_depth);
    }
  }
}

// part: "keys" -> recessed bodies;  "legends" -> flush plugs.
module planck_board(part) {
  list = planck_default_layout;
  for (row = [0:len(list)-1]) {
    row_length = len(list[row]);
    for (column = [0:len(list[row])-1]) {
      key_length = list[row][column];
      if (key_length >= 1) {
        cv = double_sculpted_column(column, row_length, SCULPT);
        cd = abs_sum([for (x = [0:column]) list[row][x]]);
        base = planck_g20_legends[row][column];
        translate_u(cd - key_length/2, -row) {
          if (part == "keys")
            pl_keycap(key_length, row + 1, cv, true, base, row, column);
          else if (base != "")                       // skip blank keys / spacebar
            color($tertiary_color)
              pl_plug(key_length, row + 1, cv, base, row, column);
        }
      }
    }
  }
}

// --- output ----------------------------------------------------------------
if (EXPORT_PART == "keys" || EXPORT_PART == "both")
  planck_board("keys");

if (EXPORT_PART == "legends" || EXPORT_PART == "both")
  planck_board("legends");
