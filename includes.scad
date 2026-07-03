// NOTE: key.scad is brought in with `include`, NOT `use`.
//
// KeyV2 relies on profile/modifier functions (dcs_row, g20_row, legend, ...)
// setting special ($) variables that must be visible inside key(). On the
// OpenSCAD installed here (2021.01) that propagation only happens with
// `include`: a module imported with `use` does NOT see the caller's $variables
// (they can only be passed as parameters). With `use` every profile collapsed
// to the default shape and legend() drew nothing.
// See openscad#3881 and openscad#5924 (the behaviour changed between 2021.01 and
// recent nightlies) and KeyV2 issue #213.
//
// $using_customizer = true suppresses the auto example_key() at the bottom of
// key.scad (its only effect), so `include <includes.scad>` on its own renders
// nothing until you call key() yourself.
$using_customizer = true;
include <src/key.scad>

include <src/settings.scad>
include <src/key_sizes.scad>
include <src/key_profiles.scad>
include <src/key_types.scad>
include <src/key_transformations.scad>
include <src/key_helpers.scad>
include <src/key_layouts.scad>
