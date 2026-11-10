// Parametric finger-joint box for laser cutting
// ------------------------------------------------
// Render (F6) and export as SVG or DXF.
// Open Window > Customizer for sliders, or from the command line:
//   openscad -o box.svg -D length=150 -D thickness=6 box.scad
//
// Joint scheme: Front/Back own the corners, Front/Back tabs go into
// Left/Right, and the Bottom/Top fit inside all four walls.
// Finger counts are always odd, so every edge ends symmetrically.

/* [Box size (mm)] */
length = 100;           // X
width  = 70;            // Y
height = 50;            // Z
dims_are_inner = true;  // true = interior dimensions, false = outer
open_top = false;

/* [Material] */
thickness = 3;
// Laser beam width. Increase for a tighter fit, decrease if it's too tight.
kerf = 0.15;

/* [Fingers] */
// Target finger width. The real width is adjusted to fit evenly.
finger_width = 10;

/* [Layout] */
gap = 5;
part = "all"; // [all, bottom, top, front, back, left, right]

/* [Hidden] */
t     = thickness;
t_top = open_top ? 0 : t;
L = dims_are_inner ? length + 2*t       : length;
W = dims_are_inner ? width  + 2*t       : width;
H = dims_are_inner ? height + t + t_top : height;

ENDS = 1; MIDDLES = 0; NONE = -1;

function fingers(span) =
    let(k = max(3, floor(span / finger_width))) k % 2 == 0 ? k - 1 : k;

nX = fingers(L - 2*t);
nY = fingers(W - 2*t);
nZ = fingers(H - t - t_top);

echo(str("Outer size: ", L, " x ", W, " x ", H, " mm"));
echo(str("Fingers X/Y/Z: ", nX, " / ", nY, " / ", nZ));

// One row of fingers along an edge, t deep.
// mode ENDS: keep the odd-position segments (both ends included).
// mode MIDDLES: keep the complementary segments.
module strip(len, n, mode, vertical = false) {
    s = len / n;
    for (i = [0 : n - 1])
        if ((i % 2 == 0) == (mode == ENDS)) {
            if (vertical) translate([0, i*s]) square([t, s]);
            else          translate([i*s, 0]) square([s, t]);
        }
}

// a x b panel. m_bot/m_top: horizontal edges, m_side: both vertical edges.
module panel(a, b, nu, nv, m_bot, m_top, m_side, corners) {
    top_t = (m_top == NONE) ? 0 : t;
    vlen  = b - t - top_t;
    offset(delta = kerf / 2) union() {
        translate([t, t]) square([a - 2*t, vlen]);
        translate([t, 0]) strip(a - 2*t, nu, m_bot);
        if (m_top != NONE) translate([t, b - t]) strip(a - 2*t, nu, m_top);
        translate([0,     t]) strip(vlen, nv, m_side, true);
        translate([a - t, t]) strip(vlen, nv, m_side, true);
        if (corners) {
            square([t, t]);
            translate([a - t, 0]) square([t, t]);
            if (m_top != NONE) {
                translate([0,     b - t]) square([t, t]);
                translate([a - t, b - t]) square([t, t]);
            }
        }
    }
}

wall_top = open_top ? NONE : ENDS;

module bottom_panel() panel(L, W, nX, nY, MIDDLES, MIDDLES, MIDDLES, false);
module front_panel()  panel(L, H, nX, nZ, ENDS, wall_top, ENDS, true);
module side_panel()   panel(W, H, nY, nZ, ENDS, wall_top, MIDDLES, false);

module layout() {
    bottom_panel();
    if (!open_top) translate([L + gap, 0]) bottom_panel();          // top
    translate([0,       W + gap]) front_panel();                    // front
    translate([L + gap, W + gap]) front_panel();                    // back
    translate([0,       W + H + 2*gap]) side_panel();               // left
    translate([W + gap, W + H + 2*gap]) side_panel();               // right
}

if      (part == "all")                     layout();
else if (part == "bottom" || part == "top") bottom_panel();
else if (part == "front"  || part == "back") front_panel();
else if (part == "left"   || part == "right") side_panel();
