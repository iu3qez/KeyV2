include <includes.scad>

/* Full keycap set for a Planck 40% (4x12 ortholinear, MIT bottom row with a 2u
   spacebar), G20 profile, with QWERTY lettering.

   Built on the existing planck_default layout (src/layouts/planck/default.scad):
   a 13-column grid with a center gap in rows 0-2 and, in the bottom row, a 2u
   key in the center for the spacebar (rendered via the layout engine's 2u
   special-key path). "se esiste usa quello" — we reuse that layout array.

   Legends: planck_default_legends in the source is 12 wide and does NOT account
   for the center 0-gap column, so it misaligns after the gap. Here we use a
   gap-aware 13-column array (blank "" at every gap and at the 2u spacebar).

   Flush multimaterial legends (same idea as examples/g20_flush_multimaterial):
   - EXPORT_PART = "keys"    -> keycap bodies with the 0.8mm legend recess (material 1)
   - EXPORT_PART = "legends" -> flush legend plugs only               (material 2)
   - EXPORT_PART = "both"    -> two-colour preview (NOT for slicing: OpenSCAD
                               unions it into one mesh; export the two parts
                               separately and combine them in the slicer).
   The legend plugs are produced board-wide by  (smooth board) - (recessed board),
   which cancels everything except the recess volumes = exactly the plugs.
*/

EXPORT_PART = "keys";   // "keys" | "legends" | "both"

// --- shared settings -------------------------------------------------------
$stem_support_type = "disable";   // no tines (the cross-bars under the stem)
$inset_legend_depth = 0.8;        // 0.8mm flush legend
$outset_legends = false;

$primary_color   = [0.20, 0.55, 1.00];   // keycap bodies
$secondary_color = [0.20, 0.55, 1.00];
$tertiary_color  = [0.95, 0.95, 0.95];   // legends (second material)

PROFILE = "g20";
SCULPT  = "2hands";   // "2hands" | "1hand" | "cresting_wave"  (hand-split bowl)

// --- gap-aware legends (13 columns, "" at gaps and on the 2u spacebar) ------
planck_g20_legends = [
  ["⇥",  "Q",   "W",   "E",   "R",   "T", "", "Y",   "U", "I", "O", "P", "⌫"],
  ["Esc","A",   "S",   "D",   "F",   "G", "", "H",   "J", "K", "L", ";", "⏎"],
  ["⇧",  "Z",   "X",   "C",   "V",   "B", "", "N",   "M", ",", ".", "/", "⇧"],
  ["Fn", "Ctl", "Alt", "Cmd", "Lwr", "",  "", "",    "Rse","←", "↓", "↑", "→"]
];

// recessed board (bodies with the legend pocket carved in)
module planck_recessed()
  layout(planck_default_layout, PROFILE, legends=planck_g20_legends,
         row_sculpting_offset=1, column_sculpt_profile=SCULPT);

// smooth board (identical, no legends) — used to cut the plugs
module planck_smooth()
  layout(planck_default_layout, PROFILE,
         row_sculpting_offset=1, column_sculpt_profile=SCULPT);

// --- output ----------------------------------------------------------------
if (EXPORT_PART == "keys" || EXPORT_PART == "both")
  planck_recessed();

if (EXPORT_PART == "legends" || EXPORT_PART == "both")
  color($tertiary_color) difference() {
    planck_smooth();
    planck_recessed();
  }
