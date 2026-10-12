# COLRHO — Column Reinforcement Ratio for AutoCAD

AutoLISP command that calculates the longitudinal reinforcement ratio of a concrete column:

```
rho_g = As / Ag
```

Enter the column size and the rebar (e.g. `8-#8`); the command reports Ag, As, rho_g and checks it against the 1% – 8% limits.

## Install

1. Download `COLRHO_EN.lsp`.
2. In AutoCAD, run `APPLOAD` and load the file (or drag it into the drawing window).
   If AutoCAD shows a security warning, choose **Load**.
3. To load it automatically every session, add it to **Startup Suite** in `APPLOAD`.

## Usage

Type `COLRHO`, then answer the prompts:

| Prompt | Input |
|---|---|
| Section shape | `R` rectangular / `C` circular |
| Size (cm) | `b`, `h` — or diameter `D` |
| Rebar | `8-#8`, `8#8`, `8-D25`, `12-#10+4-#8` (case and spaces ignored) |
| Text placement | Pick a point to write an MTEXT result into the drawing, or press Enter to skip |

Previous inputs are remembered as defaults for the next run.

### Example

```
Section: 60x60cm
Ag    = 3600 cm2
Rebar: 8-#8
As    = 40.54 cm2
rho_g = 1.126 %
Check: OK  (1% <= rho_g <= 8%)
```

## Check rules

| rho_g | Result |
|---|---|
| < 1% | NG — below minimum |
| 1% – 4% | OK |
| 4% – 8% | OK, with a warning about congestion at lap splices |
| > 8% | NG — above maximum |

## Bar areas

Nominal areas follow CNS 560 (Taiwan). `#n` and `Dxx` designations are both accepted.

| Bar | D | Area (cm²) |
|---|---|---|
| #3 | D10 | 0.7133 |
| #4 | D13 | 1.267 |
| #5 | D16 | 1.986 |
| #6 | D19 | 2.865 |
| #7 | D22 | 3.871 |
| #8 | D25 | 5.067 |
| #9 | D29 | 6.469 |
| #10 | D32 | 8.143 |
| #11 | D36 | 10.07 |
| #14 | D43 | 14.52 |
| #18 | D57 | 25.79 |

ASTM nominal areas differ slightly (e.g. ASTM #8 = 5.10 cm²). Edit `*colrho-bars*` at the top of the file to use another standard.

## Compatibility

The file is plain ASCII, so it loads in any AutoCAD version with AutoLISP. Tested on AutoCAD 2026.
