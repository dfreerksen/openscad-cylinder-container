/*
Author: David Freerksen, dfreerksen@gmail.com
Created: 01/24/2026
Last Updated: 01/24/2026
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
internal_diameter = 40; // [10:255]

// Wall thickness (mm)
wall_thickness = 4; // [2:10]

// Rounded edges
rounded_edge = true; // [true, false]

/* [Holes] */

// Base has cylintrical holes
render_holes = false; // [true, false]

// Diameter of single hole (mm)
hole_diameter = 9; // [1:50]

// Number of holes
hole_count = 5; // [3:10]

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

// Render knurling (only in final render)
render_knurling = true; // [true, false]

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

/* [Top] */

// Height of lid (mm)
top_height = 20; // [10:255]

/* [Bottom] */

// Height of base (mm)
bottom_height = 30; // [10:255]

module __Customizer_Limit__ () {}

$fn = $preview ? 32 : 128;

// Main rendering logic
if (render_part == "both") {
    container_bottom();
    translate([(internal_diameter + ((2 * 2) * wall_thickness)) + render_gap, 0, 0])
        container_top();
} else if (render_part == "bottom") {
    container_bottom();
} else if (render_part == "top") {
    container_top();
}

// Container Bottom with Recessed Threads
module container_bottom () {
    // Container
    union () {
        translate([0, 0, wall_thickness])
            difference () {
                // Outer cylinder
                cylinder(h=bottom_height, d=(internal_diameter + ((2 * 2) * wall_thickness)));

                // Internal thread cutout
                translate([0, 0, (bottom_height - thread_height)])
                    difference () {
                        cylinder(h=thread_height, d=(internal_diameter + ((2 * 2) * wall_thickness)));

                        ScrewThread(
                            outer_diam=(internal_diameter + (2 * wall_thickness)),
                            height=thread_height,
                            pitch=thread_pitch,
                            tooth_angle=thread_angle,
                            tolerance=(thread_tolerance * -1)
                        );
                    }

                // Cylinder holes
                if (render_holes) {
                    union () {
                        // Partial internal cavity
                        translate([0, 0, bottom_height - thread_height + wall_thickness])
                            cylinder(h=thread_height, d=internal_diameter);

                        // Holes in base
                        for (i = [0 : hole_count - 1]) {
                            angle = i * (360 / hole_count);
                            x_pos = ((internal_diameter / 2) - hole_diameter) * cos(angle);
                            y_pos = ((internal_diameter / 2) - hole_diameter) * sin(angle);
                            translate([x_pos, y_pos, wall_thickness])
                                cylinder(h=bottom_height, d=hole_diameter);
                        }
                    }
                }
                // Internal cavity. No holes
                else {
                    cylinder(h=(bottom_height + wall_thickness), d=internal_diameter);
                }
            }

        // Rounded edges
        _container_rounded_base();
    }

    // Knurling
    if (!$preview && render_knurling) {
        // Inner cylinder for knurling
        translate([0, 0, wall_thickness])
            difference () {
                // Knurling
                knurled_cylinder(
                    height=(bottom_height - thread_height),
                    diameter=(internal_diameter + ((2 * 2) * wall_thickness)),
                    knurl_width=knurling_width,
                    knurl_height=knurling_height,
                    knurl_depth=knurling_depth,
                    bevel=knurling_bevel,
                    smooth=knurling_smooth
                );

                // Inner cavity cutout
                cylinder(h=(bottom_height - thread_height), d=(internal_diameter + (2 * wall_thickness)));
            }
    }
}

// Container Lid with Internal Threads
module container_top () {
    // Container
    union () {
        translate([0, 0, wall_thickness])
            difference () {
                difference () {
                    // Outer cylinder
                    cylinder(h=(top_height), d=(internal_diameter + ((2 * 2) * wall_thickness)));

                    // Internal threads
                    translate([0, 0, (top_height - thread_height)])
                        rotate(180)
                        ScrewThread(
                            outer_diam=(internal_diameter + (2 * wall_thickness)),
                            height=thread_height,
                            pitch=thread_pitch,
                            tooth_angle=thread_angle,
                            tolerance=thread_tolerance
                        );
                }

                // Internal cavity
                cylinder(h=top_height, d=internal_diameter);
            }

        // Rounded edges
        _container_rounded_base();
    }

    // Knurling
    if (!$preview && render_knurling) {
        // Inner cylinder for knurling
        translate([0, 0, wall_thickness])
            difference () {
                // Knurling
                knurled_cylinder(
                    height=top_height,
                    diameter=(internal_diameter + ((2 * 2) * wall_thickness)),
                    knurl_width=knurling_width,
                    knurl_height=knurling_height,
                    knurl_depth=knurling_depth,
                    bevel=knurling_bevel,
                    smooth=knurling_smooth
                );

                // Inner cavity cutout
                cylinder(h=top_height, d=(internal_diameter + (2 * wall_thickness)));
            }
    }
}


module _container_rounded_base () {
    // Rounded edges
    unrounded_edges = (internal_diameter + ((2 * 2) * wall_thickness));
    rounded_edges = (internal_diameter + (2 * wall_thickness));
    if (rounded_edge == true) {
        cylinder(h=wall_thickness, d1=rounded_edges, d2=unrounded_edges);
    } else { 
        cylinder(h=wall_thickness, d1=unrounded_edges, d2=unrounded_edges);
    }
}

