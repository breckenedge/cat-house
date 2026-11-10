// Parametric laser-cut cat house (open bottom, glue-up)
// ----------------------------------------------------
// Sits over a cardboard scratcher. The door openings start at
// scratcher_height, so the cardboard stays in and cats step up onto it.
//
// 6 parts: 2 gable walls (front/back, with door holes),
//          2 side walls (with window holes), 2 roof panels.
// - Wall corners use finger joints. The gables own the end fingers.
// - Gable slopes have tabs that go through slots in the roof panels.
// - Roof panel A overlaps panel B at the ridge. The lengths are worked
//   out from the pitch and the material thickness.
// All sizes are OUTER dimensions in mm.
//
// mode = "flat"      -> 2D cut layout. Render (F6), then export SVG/DXF.
// mode = "assembled" -> 3D preview of the finished house (not for cutting).
//
// CLI: openscad.com -o house.svg -D mode=\"flat\" house.scad

/* [Mode] */
mode = "flat"; // [flat, assembled]

/* [Scratcher] */
// When true, the walls are sized to fit around the scratcher
// and house_width/house_depth are ignored.
fit_to_scratcher    = true;
scratcher_width     = 361.95;  // 14.25 in, across the doors
scratcher_depth     = 361.95;  // 14.25 in, along the side walls
scratcher_clearance = 2;       // total slack per direction, so it drops in
// Thickness of the cardboard scratcher. Door openings start above it.
scratcher_height = 40;

/* [House size] */
house_width = 400;   // gable (front/back) wall width, outer
house_depth = 500;   // side wall length, outer
wall_height = 300;   // height to the eaves
roof_angle  = 40;    // [15:1:60]

/* [Roof] */
eave_overhang   = 20;  // past the side walls, down the slope
gable_overhang  = 20;  // past the front/back walls
roof_tabs       = 2;   // tabs per slope
roof_tab_length = 40;  // max tab length

/* [Doors] */
front_door  = true;
back_door   = true;
door_width  = 180;
door_height = 230;   // opening height, measured from the sill
door_arched = true;

/* [Windows] */
windows_per_side = 2;
window_width     = 100;
window_height    = 100;
window_sill      = 150;  // height of the window bottom above the ground
window_arched    = true;

/* [Material] */
thickness = 6;
kerf      = 0.2;  // raise for a tighter fit, lower if too tight

/* [Fingers] */
finger_width = 40;

/* [Layout] */
gap  = 10;
part = "all"; // [all, front, back, side, roof_a, roof_b]

/* [Hidden] */
$fn = 96;
eps = 0.01;
t  = thickness;
W  = fit_to_scratcher ? scratcher_width + scratcher_clearance + 2 * t : house_width;
D  = fit_to_scratcher ? scratcher_depth + scratcher_clearance + 2 * t : house_depth;
H  = wall_height;
a  = roof_angle;
k  = mode == "assembled" ? 0 : kerf;   // no kerf offset in the 3D preview

S  = (W / 2) / cos(a);           // slope length, eave corner to peak
Hp = H + (W / 2) * tan(a);       // peak height

// Ridge geometry: panel B is shortened so its end butts under panel A,
// and panel A is extended to cover B's top edge.
ridge_cut = a < 45 ? t / tan(2 * a) : 0;
ridge_ext = ridge_cut * cos(2 * a) + t * sin(2 * a);
roofA_len = eave_overhang + S + ridge_ext;
roofB_len = eave_overhang + S - ridge_cut;
roof_d    = D + 2 * gable_overhang;

function fingers(span) =
    let(n = max(3, floor(span / finger_width))) n % 2 == 0 ? n - 1 : n;
nZ = fingers(H);

tab_len = min(roof_tab_length, S / (2 * roof_tabs));
tab_pos = [for (i = [0 : roof_tabs - 1]) S * (i + 0.5) / roof_tabs - tab_len / 2];

echo(str("Peak height: ", Hp, " mm"));
echo(str("House footprint (outer): ", W, " x ", D, " mm"));
echo(str("Inside footprint: ", W - 2 * t, " x ", D - 2 * t, " mm"));
echo(str("Part sizes: gable ", W, " x ", Hp, ", side ", D, " x ", H,
         ", roof A ", roofA_len, " x ", roof_d, ", roof B ", roofB_len, " x ", roof_d));
if (scratcher_height + door_height >= Hp - t) echo("WARNING: door is taller than the gable");
if (window_sill + window_height >= H) echo("WARNING: windows extend past the wall top");
if (window_sill <= scratcher_height) echo("WARNING: windows start below the scratcher top");
if (windows_per_side * window_width >= D - 2 * t) echo("WARNING: windows don't fit along the side");

// Finger segments along a vertical edge (x in [0,t], z in [0,len]).
// ends=true selects the even segments (both ends), false the odd ones.
// Slightly oversized so it cuts cleanly when subtracted.
module segs(len, n, ends) {
    s = len / n;
    for (i = [0 : n - 1])
        if ((i % 2 == 0) == ends) {
            lo = i == 0     ? eps : 0;
            hi = i == n - 1 ? eps : 0;
            translate([-eps, i * s - lo]) square([t + 2 * eps, s + lo + hi]);
        }
}

module edge_cuts(width, ends) {
    segs(H, nZ, ends);
    translate([width - t, 0]) segs(H, nZ, ends);
}

module arch_hole(w, h, arched) {
    if (arched && h > w / 2) {
        translate([-w / 2, 0]) square([w, h - w / 2]);
        translate([0, h - w / 2]) circle(d = w);
    } else {
        translate([-w / 2, 0]) square([w, h]);
    }
}

// Tabs on the left slope. They stick out perpendicular to the slope
// by one material thickness to go through the roof slots.
module left_slope_tabs() {
    u = [cos(a), sin(a)];
    n = [-sin(a), cos(a)];
    o = [0, H];
    for (p = tab_pos) {
        A = o + p * u - 0.05 * n;
        B = o + (p + tab_len) * u - 0.05 * n;
        polygon([A, B, B + (t + 0.05) * n, A + (t + 0.05) * n]);
    }
}

// ---------- 2D parts ----------

module gable(door) {
    offset(delta = k / 2) difference() {
        union() {
            polygon([[0, 0], [W, 0], [W, H], [W / 2, Hp], [0, H]]);
            left_slope_tabs();
            translate([W, 0]) mirror([1, 0]) left_slope_tabs();
        }
        edge_cuts(W, false);        // gable keeps the end fingers
        if (door)
            translate([W / 2, scratcher_height]) arch_hole(door_width, door_height, door_arched);
    }
}

module side_wall() {
    offset(delta = k / 2) difference() {
        square([D, H]);
        edge_cuts(D, true);         // side walls keep the middle fingers
        for (i = [0 : windows_per_side - 1])
            translate([t + (D - 2 * t) * (i + 0.5) / windows_per_side, window_sill])
                arch_hole(window_width, window_height, window_arched);
    }
}

module roof_panel(len) {
    offset(delta = k / 2) difference() {
        square([len, roof_d]);
        for (p = tab_pos, v = [gable_overhang, gable_overhang + D - t])
            translate([eave_overhang + p, v]) square([tab_len, t]);
    }
}

// ---------- flat cut layout ----------

module layout() {
    gable(front_door);
    translate([W + gap, 0]) gable(back_door);
    translate([0,       Hp + gap]) side_wall();
    translate([D + gap, Hp + gap]) side_wall();
    translate([0,               Hp + H + 2 * gap]) roof_panel(roofA_len);
    translate([roofA_len + gap, Hp + H + 2 * gap]) roof_panel(roofB_len);
}

// ---------- assembled 3D preview ----------
// X = width, Y = depth, Z = up

module slab() linear_extrude(t) children();

module assembled() {
    wall = "BurlyWood";
    roof = "SaddleBrown";
    // front (y = 0..t) and back (y = D-t..D)
    color(wall) translate([0, t, 0]) rotate([90, 0, 0]) slab() gable(front_door);
    color(wall) translate([0, D, 0]) rotate([90, 0, 0]) slab() gable(back_door);
    // sides (x = 0..t and W-t..W)
    color(wall) rotate([90, 0, 90]) slab() side_wall();
    color(wall) translate([W - t, 0, 0]) rotate([90, 0, 90]) slab() side_wall();
    // roof A on the left slope, roof B on the right slope
    c = cos(a); s = sin(a);
    color(roof)
        multmatrix([[c, 0, -s, -eave_overhang * c],
                    [0, 1,  0, -gable_overhang],
                    [s, 0,  c, H - eave_overhang * s],
                    [0, 0,  0, 1]])
            slab() roof_panel(roofA_len);
    color(roof)
        multmatrix([[-c, 0, s, W + eave_overhang * c],
                    [ 0, 1, 0, -gable_overhang],
                    [ s, 0, c, H - eave_overhang * s],
                    [ 0, 0, 0, 1]])
            slab() roof_panel(roofB_len);
    // scratcher footprint (preview only)
    %translate([t, t, 0]) cube([W - 2 * t, D - 2 * t, scratcher_height]);
}

// ---------- output ----------

if (mode == "assembled") assembled();
else if (part == "all")    layout();
else if (part == "front")  gable(front_door);
else if (part == "back")   gable(back_door);
else if (part == "side")   side_wall();
else if (part == "roof_a") roof_panel(roofA_len);
else if (part == "roof_b") roof_panel(roofB_len);
