# Parley brand

## The mark

Two half-discs facing each other across a gap, the left one a step higher. Two parties at the
table, taking turns to speak; together they still make one round whole. That is what a parley
is, and what the app does: you and Claude, turn by turn.

Built on a 256 grid: both halves have radius 80, the gap is 16 and the step is 24.
`brand/kit/parley-symbol.svg` is the master; `lib/core/widgets/parley_mark.dart` draws the same
geometry in the app.

## Colours

| Name | Hex | Use |
| --- | --- | --- |
| Green | `#1F6F54` | left half on light backgrounds, app accent in light mode |
| Mint | `#5CC79C` | right half everywhere, app accent in dark mode |
| Deep | `#14503D` | app icon and social preview background |
| Paper | `#F3EFE6` | left half on dark and green backgrounds |
| Ink | `#15130F` | wordmark on light |
| Night | `#0F0E0C` | dark backgrounds |

One-colour versions (`-black`, `-white`) are for print, stamps and anywhere colour is not
available. Never recolour the halves to anything outside this table.

## Type

The wordmark is "parley" in lowercase, Bricolage Grotesque SemiBold (SIL Open Font License,
`brand/fonts/OFL.txt`), outlined in every file so no font needs to be installed.

## Files

| File | What it is |
| --- | --- |
| `kit/parley-symbol*.svg` | the mark: colour, dark, black, white |
| `kit/parley-lockup*.svg` | mark + wordmark, horizontal |
| `kit/parley-wordmark*.svg` | wordmark alone |
| `kit/parley-app-icon.svg`, `kit/png/app-icon-1024.png` | iOS icon master |
| `kit/parley-adaptive-*.svg`, `kit/png/adaptive-*.png` | Android adaptive and monochrome layers |
| `banner.svg`, `banner-dark.svg` | animated README header (still under reduced motion) |
| `banner.png` | social preview, 1280 x 640 |

## Rebuilding

```bash
python3 brand/generate.py           # every SVG and PNG above (needs fontTools and Chrome)
dart run flutter_launcher_icons      # iOS and Android app icons from kit/png
```

Clear space around the mark: at least half its width. Smallest size: 16 px for the symbol,
96 px wide for the lockup.
