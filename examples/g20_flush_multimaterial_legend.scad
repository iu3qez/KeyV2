include <../includes.scad>

/* G20 keycaps with truly FLUSH ("a filo") legends, 0.8mm thick, as a SEPARATE
   BODY so the legend can be printed in a different material / colour.

   Works because includes.scad brings key.scad in with `include` (not `use`),
   so the profile/legend special variables reach key(). See includes.scad.

   Getting the legend *flush* (top level with the surface), not engraved:
   the stock `dished(){ legends() }` plug sits ~0.8mm below the surface on G20
   (its top is clipped by the dish), so it only fills the bottom of the pocket
   and looks carved. Instead, build the plug as the EXACT pocket volume:

       plug = (smooth keycap)  MINUS  (keycap with the legend recess)

   That difference is precisely the material key(true) removed, so the plug
   fills the pocket completely and its top is flush with the keycap surface.

   Two-material export:
   - EXPORT_PART = "keys"    -> keycap bodies only (material 1)
   - EXPORT_PART = "legends" -> flush legend plugs (material 2)
   - EXPORT_PART = "both"    -> two-colour preview
   Perfectly flush faces z-fight in the optical preview (legends look faint) —
   the STL is correct; keep it flush for slicing.
*/

EXPORT_PART = "both";

// 0.8mm legend, inset (flush-fill), not raised
$inset_legend_depth = 0.8;
$outset_legends = false;

// Underside: drop the "tines" stem supports — the thin cross-bars radiating from
// the stem read as artifacts under the cap and aren't wanted here.
// ($support_type is left at its "flared" default. Note it produces nothing on a
//  low profile like G20: the flare height is $total_depth - $stem_throw, which is
//  ~0 here, so there's no vertical room for a flare to form. See src/key.scad:99.)
$stem_support_type = "disable";

// preview colours (each printed body is one material). key()/keytext() colour
// themselves via these special variables, so set them rather than wrapping color().
$primary_color   = [0.20, 0.55, 1.00];   // keycap body walls
$secondary_color = [0.20, 0.55, 1.00];   // keycap body top
$tertiary_color  = [0.95, 0.95, 0.95];   // legend ("corpo diverso")

legends = ["Q", "W", "E", "R", "T"];

for (x = [0:len(legends)-1]) {
  translate_u(x, 0) {
    // keycap body: G20 with the 0.8mm legend recess carved in
    if (EXPORT_PART == "keys" || EXPORT_PART == "both") {
      legend(legends[x], size=9) g20_row(3, 0) key();
    }
    // legend plug: exactly the pocket volume -> sits flush with the surface
    if (EXPORT_PART == "legends" || EXPORT_PART == "both") {
      color($tertiary_color) difference() {
        g20_row(3, 0) key();                              // smooth keycap
        legend(legends[x], size=9) g20_row(3, 0) key();   // recessed keycap
      }
    }
  }
}
