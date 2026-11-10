# Laser-cut cat house

A parametric cat house for laser cutting, made in [OpenSCAD](https://openscad.org/). Change the sizes, material thickness or kerf, then export SVG/DXF for your laser.

![Assembled cat house](images/house-assembled.png)

A gable-roof cat house with an open bottom that sits over a cardboard scratcher.

- 6 parts: front and back walls with arched doors, two side walls with windows, and two roof panels
- Finger-jointed corners, and roof tabs that go through slots in the roof panels. Everything is glued together.
- The roof panels overlap at the ridge, with lengths worked out from the pitch and material thickness
- Sized to fit a 14.25" × 14.25" scratcher by default. The walls are calculated from `scratcher_width`/`scratcher_depth` plus `scratcher_clearance`. Set `fit_to_scratcher = false` to use `house_width`/`house_depth` instead.
- The doors start at `scratcher_height`, so the cardboard stays in and cats step up onto it
- **Two modes:** `flat` (cut layout) and `assembled` (3D preview)

![Flat cut layout](images/house-flat.png)

## Usage

1. Open `house.scad` in OpenSCAD and turn on **Window → Customizer**.
2. Set your dimensions (all in **inches**), `thickness` (measure your real sheet) and `kerf`.
3. Render with **F6**, then use **File → Export → SVG** or **DXF**.

From the command line (on Windows, use `openscad.com` to get console output):

```sh
openscad -o house.svg -D thickness=0.22 house.scad
openscad -o house.png -D 'mode="assembled"' house.scad
```

Settings are in inches, but exports are scaled to millimeters (what SVG/DXF and laser software expect), so parts import at the correct real-world size.

Use `part` to export a single panel when the full layout won't fit your laser bed.

## Tips

- **Kerf:** start at 0.004–0.008" and cut a test corner first. Raise it if the joints are loose, lower it if they're too tight.
- **Thickness:** nominal 1/4" plywood is often ~0.22". Measure it with calipers.
- **Scratcher:** the console prints the inside footprint to cut the cardboard to, plus each part's size and any fit warnings.
