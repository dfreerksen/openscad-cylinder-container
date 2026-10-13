/*
Author: David Freerksen, dfreerksen@gmail.com
Created: 10/06/2026
Last Updated: 10/13/2026
*/

use <threads.scad> // https://github.com/rcolyer/threads-scad/
use <knurled.scad> // https://github.com/smkent/knurled-openscad/

/* [Display] */

// Parts to render
render_part = "both"; // [both, top, bottom]

// Gap between rendered parts (mm)
render_gap = 10; // [5:20]

/* [Properties] */

// Inner diameter of container (mm)
// internal_diameter = 50; // [10:255]

// Wall thickness (mm)
wall_thickness = 4; // [2:10]

/* [Holes] */

// Diameter of single hole (mm)
// hole_diameter = 11.96; // [1:50]

// Number of holes
// hole_count = 7; // [3:10]

// Hole spacing (mm)
// hole_spacing = 5; // [0:20]

// Hole gap (mm)
// hole_gap = 0.3; // [0.01:1]

/* [Thread] */

// Height of threaded section (mm)
thread_height = 10; // [10:50]

// Thread pitch
thread_pitch = 3.5; // [3:0.5:6]

// Tolerance for fit (mm)
thread_tolerance = 0.2; // [0.1:0.1:1.0]

// Angle of thread tooth (degrees)
thread_angle = 30; // [25:5:90]

/* [Knurling] */

// Knurling gap
knurling_gap = 4; // [2:0.5:5]

// Knurling width
knurling_width = 3; // [2:0.5:5]

// Knurling height
knurling_height = 4; // [2:0.5:6]

// Knurling depth
knurling_depth = 1.5; // [0.5:0.1:3]

// Knurling bevel
knurling_bevel = 2; // [0:0.1:3]

// Knurling smooth
knurling_smooth = 20; // [0:1:100]

/* [Bottom] */

// Height of the inside of the base (mm)
// bottom_height = 51.2; // [10:255]

/* [Top] */

// Height of the inside of the lid (mm)
// top_height = 19.9; // [10:255]

module __Customizer_Limit__ () {}

$fn = $preview ? 32 : 128;

/* Caliber Overrides */
// include <caliber/22-lr.scad>
// include <caliber/38-special.scad>
// include <caliber/30-30-win.scad>
include <caliber/9mm.scad>

// Main rendering logic
if (render_part == "both") {
    container_bottom();
    translate([(internal_diameter + (3 * wall_thickness)) + render_gap, 0, 0])
        container_top();
} else if (render_part == "bottom") {
    container_bottom();
} else if (render_part == "top") {
    container_top();
}

// Container Bottom with Recessed Threads
module container_bottom () {
    assert(bottom_height >= thread_height, "Bottom height must be greater than or equal to thread height");

    union () {
        difference () {
            union () {
                difference () {
                    // Body
                    translate([0, 0, wall_thickness])
                        cylinder(h = bottom_height, d = (internal_diameter + (3 * wall_thickness)), center = false);

                    // Thread cutout
                    translate([0, 0, (bottom_height + wall_thickness - thread_height)])
                        difference () {
                            cylinder(h = thread_height, d = (internal_diameter + (3 * wall_thickness)), center = false);

                            cylinder(h = thread_height, d = (internal_diameter + wall_thickness), center = false);
                        }
                }

                // Thread
                if (!$preview) {
                    translate([0, 0, (bottom_height + wall_thickness - thread_height)])
                        ScrewThread(outer_diam = (internal_diameter + (2 * wall_thickness)),
                                    height = thread_height,
                                    pitch = thread_pitch,
                                    tooth_angle = thread_angle,
                                    tolerance = (thread_tolerance * -1));
                }

                // Knurling
                if (!$preview) {
                    translate([0, 0, wall_thickness])
                        knurled_cylinder(height = (bottom_height - thread_height - knurling_gap),
                                        diameter = (internal_diameter + (3 * wall_thickness)),
                                        knurl_width = knurling_width,
                                        knurl_height = knurling_height,
                                        knurl_depth = knurling_depth,
                                        bevel = knurling_bevel,
                                        smooth = knurling_smooth);
                }
            }

            // Holes
            translate([0, 0, wall_thickness])
                color("red")
                container_holes();

            // // Internal
            // translate([0, 0, wall_thickness])
            //     cylinder(h = bottom_height, d = internal_diameter, center = false);
        }

        // Base
        cylinder(h = wall_thickness, d1 = (internal_diameter + wall_thickness), d2 = (internal_diameter + (3 * wall_thickness)), center = false);
    }
}

// Container Lid with Internal Threads
module container_top () {
    modified_top_height = top_height + thread_height + hole_gap;

    assert(modified_top_height >= thread_height, "Top height must be greater than or equal to thread height");

    difference () {
        union () {
            // Body
            translate([0, 0, wall_thickness])
                cylinder(h = modified_top_height, d = (internal_diameter + (3 * wall_thickness)), center = false);

            // Knurling
            if (!$preview) {
                translate([0, 0, wall_thickness])
                    knurled_cylinder(height = (modified_top_height - knurling_gap),
                                    diameter = (internal_diameter + (3 * wall_thickness)),
                                    knurl_width = knurling_width,
                                    knurl_height = knurling_height,
                                    knurl_depth = knurling_depth,
                                    bevel = knurling_bevel,
                                    smooth = knurling_smooth);
            }

            // Base
            cylinder(h = wall_thickness, d1 = (internal_diameter + wall_thickness), d2 = (internal_diameter + (3 * wall_thickness)), center = false);
        }

        // Thread
        if (!$preview) {
            translate([0, 0, (modified_top_height + wall_thickness - thread_height)])
                rotate(180)
                ScrewThread(outer_diam=(internal_diameter + (2 * wall_thickness)),
                            height=thread_height,
                            pitch=thread_pitch,
                            tooth_angle=thread_angle,
                            tolerance=thread_tolerance * -1);
        }

        // Internal
        translate([0, 0, wall_thickness])
            cylinder(h = modified_top_height, d = internal_diameter, center = false);
    }
}

// Full size of ring k, spaced so center-to-center chord equals hole_diameter + hole_gap + hole_spacing (ring 0 is the center hole).
function hole_ring_angle_step (k) = 2 * asin(1 / (2 * k));
function hole_ring_size (k) = (k == 0) ? 1 : floor(360 / hole_ring_angle_step(k));

// Running total of holes through ring k at full size.
function hole_cum_count (k) = (k == 0) ? 1 : hole_cum_count(k - 1) + hole_ring_size(k);

// First ring index whose running total reaches hole_count, capped at max_ring.
function hole_cutoff_ring (k, max_ring) =
    (hole_cum_count(k) >= hole_count || k >= max_ring) ? k : hole_cutoff_ring(k + 1, max_ring);

module container_holes () {
    // hole_gap nudges the diameter used for spacing math only (not the printed hole size),
    // giving fine control over how tight or loose the packing is on top of hole_spacing.
    spacing_diameter = hole_diameter + hole_gap;

    field_radius = internal_diameter / 2;
    ring_pitch = spacing_diameter + hole_spacing;
    max_center_radius = field_radius - (spacing_diameter / 2);

    if (max_center_radius >= 0) {
        max_ring = floor(max_center_radius / ring_pitch);
        cutoff_ring = hole_cutoff_ring(0, max_ring);

        // Holes still wanted by the time the outermost (cutoff) ring is reached, clamped to what that ring
        // can actually hold — trims the last ring down so the total matches hole_count exactly.
        prev_cum = (cutoff_ring == 0) ? 0 : hole_cum_count(cutoff_ring - 1);
        cutoff_ring_size = max(0, min(hole_count - prev_cum, hole_ring_size(cutoff_ring)));

        // Concentric rings, each successive ring rotated half a step from the last for the staggered look.
        for (k = [0 : cutoff_ring]) {
            ring_size = (k == cutoff_ring) ? cutoff_ring_size : hole_ring_size(k);

            if (ring_size > 0) {
                if (k == 0) {
                    cylinder(h = bottom_height, d = hole_diameter, center = false);
                } else {
                    angle_offset = (k % 2 == 1) ? (180 / ring_size) : 0;

                    for (j = [0 : ring_size - 1]) {
                        angle = (j * (360 / ring_size)) + angle_offset;
                        translate([k * ring_pitch * cos(angle), k * ring_pitch * sin(angle), 0])
                            cylinder(h = bottom_height, d = hole_diameter, center = false);
                    }
                }
            }
        }
    }
}
