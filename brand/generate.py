"""Builds every Parley brand file from one place: the mark, lockups, wordmark, app icon masters,
the animated README banners and the social preview. Text is outlined from the bundled fonts
(brand/fonts, SIL Open Font License), so no file depends on a font being installed.

Run from the repo root:  python3 brand/generate.py
PNG exports need headless Chrome; the icon PNGs feed flutter_launcher_icons.yaml.
"""
import pathlib
import shutil
import subprocess

from textpath import font, glyph_bounds, text_path

ROOT = pathlib.Path(__file__).resolve().parents[1]
KIT = ROOT / 'brand' / 'kit'
PNG = KIT / 'png'

# Palette (matches lib/core/theme/parley_colors.dart).
GREEN, MINT, INK, PAPER, DEEP, NIGHT, MUTED = (
    '#1F6F54', '#5CC79C', '#15130F', '#F3EFE6', '#14503D', '#0F0E0C', '#6B675F')

# The mark: two half-discs facing across a gap, the left one a step higher. Two parties at the
# table, taking turns; together they still make one round whole. 256 grid, 16 unit gap, 24 step.
LEFT = 'M120 36A80 80 0 0 0 120 196Z'
RIGHT = 'M136 60A80 80 0 0 1 136 220Z'

WORD = font('BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf', wght=600, opsz=48, wdth=100)
BODY = font('BricolageGrotesque%5Bopsz,wdth,wght%5D.ttf', wght=400, opsz=14, wdth=100)


def svg(w, h, body, extra=''):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"{extra}>{body}</svg>'


def mark(left, right, scale=1.0, dx=0.0, dy=0.0):
    t = f'translate({dx} {dy}) translate(128 128) scale({scale}) translate(-128 -128)'
    return f'<g transform="{t}"><path fill="{left}" d="{LEFT}"/><path fill="{right}" d="{RIGHT}"/></g>'


def write(name, text):
    (KIT / name).write_text(text)


def symbols():
    write('parley-symbol.svg', svg(256, 256, mark(GREEN, MINT)))
    write('parley-symbol-dark.svg', svg(256, 256, mark(PAPER, MINT)))
    write('parley-symbol-black.svg', svg(256, 256, mark('#000', '#000')))
    write('parley-symbol-white.svg', svg(256, 256, mark('#fff', '#fff')))
    write('parley-app-icon.svg', svg(256, 256, f'<rect width="256" height="256" fill="{DEEP}"/>' + mark(PAPER, MINT, 0.78)))
    # Android adaptive layers: the launcher adds a 16% inset, so the mark is drawn full size.
    write('parley-adaptive-foreground.svg', svg(256, 256, mark(PAPER, MINT, 1.05)))
    write('parley-adaptive-monochrome.svg', svg(256, 256, mark('#fff', '#fff', 1.05)))


def lockups():
    size, sym, gap = 150, 200, 34
    x0, _, x1, y1 = glyph_bounds(WORD, 'parley', size)
    base = 128 + y1 / 2 - 18
    d, _ = text_path(WORD, 'parley', size, x=sym + gap - x0, baseline=base)
    width = int(sym + gap + (x1 - x0) + 8)
    for name, left, right, ink in [
        ('parley-lockup.svg', GREEN, MINT, INK),
        ('parley-lockup-dark.svg', PAPER, MINT, PAPER),
        ('parley-lockup-black.svg', '#000', '#000', '#000'),
    ]:
        body = (f'<g transform="translate(-14 28) scale({sym / 256})"><path fill="{left}" d="{LEFT}"/>'
                f'<path fill="{right}" d="{RIGHT}"/></g><path fill="{ink}" d="{d}"/>')
        write(name, svg(width, 256, body))
    d, _ = text_path(WORD, 'parley', size, x=-x0 + 4, baseline=150)
    for name, ink in [('parley-wordmark.svg', INK), ('parley-wordmark-dark.svg', PAPER)]:
        write(name, svg(int(x1 - x0 + 8), 210, f'<path fill="{ink}" d="{d}"/>'))


def fitted(text, size, max_width, x, baseline):
    """Outlines [text] at [size], shrunk until it fits [max_width]."""
    while size > 10:
        x0, _, x1, _ = glyph_bounds(BODY, text, size)
        if x1 - x0 <= max_width:
            break
        size -= 1
    return text_path(BODY, text, size, x=x, baseline=baseline)[0]


def banner(dark):
    """The README header: the two halves slide in and meet, then the name and the line appear.
    CSS animations run once and respect reduced motion; the last frame is the resting design."""
    w, h = 1280, 360
    bg, left, right, ink, sub = (NIGHT, PAPER, MINT, PAPER, '#A29D93') if dark else ('#FFFFFF', GREEN, MINT, INK, MUTED)
    word, _ = text_path(WORD, 'parley', 132, x=400, baseline=188)
    line1, _ = text_path(BODY, 'Claude inside a real mobile app.', 34, x=404, baseline=250)
    line2 = fitted('Streaming chat, vision, PDFs with citations, web search, tool use.', 24, w - 404 - 64, x=404, baseline=290)
    style = '''<style>
.l{animation:l 1.1s cubic-bezier(.2,.8,.2,1) both}
.r{animation:r 1.1s cubic-bezier(.2,.8,.2,1) both}
.t{animation:t .8s ease-out .7s both}
.s{animation:t .8s ease-out 1s both}
@keyframes l{from{transform:translateX(-70px);opacity:0}to{transform:none;opacity:1}}
@keyframes r{from{transform:translateX(70px);opacity:0}to{transform:none;opacity:1}}
@keyframes t{from{transform:translateY(12px);opacity:0}to{transform:none;opacity:1}}
@media (prefers-reduced-motion:reduce){.l,.r,.t,.s{animation:none}}
</style>'''
    sym = f'translate(96 52) scale(1.0)'
    body = (style + f'<rect width="{w}" height="{h}" fill="{bg}"/>'
            f'<g transform="{sym}"><path class="l" fill="{left}" d="{LEFT}"/><path class="r" fill="{right}" d="{RIGHT}"/></g>'
            f'<path class="t" fill="{ink}" d="{word}"/>'
            f'<path class="s" fill="{ink}" d="{line1}"/><path class="s" fill="{sub}" d="{line2}"/>')
    return svg(w, h, body)


def social():
    w, h = 1280, 640
    word, _ = text_path(WORD, 'parley', 150, x=430, baseline=330)
    line, _ = text_path(BODY, 'Claude inside a real mobile app', 40, x=436, baseline=400)
    feats, _ = text_path(BODY, 'Chat  ·  Vision  ·  PDFs with citations  ·  Web search  ·  Tool use', 26, x=436, baseline=450)
    body = (f'<rect width="{w}" height="{h}" fill="{DEEP}"/>' + mark(PAPER, MINT, 1.15, dx=150, dy=192)
            + f'<path fill="{PAPER}" d="{word}"/><path fill="{PAPER}" d="{line}"/><path fill="{MINT}" d="{feats}"/>')
    return svg(w, h, body)


def chrome():
    for path in ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', shutil.which('chromium'), shutil.which('google-chrome')]:
        if path and pathlib.Path(path).exists():
            return path
    raise SystemExit('Headless Chrome is needed for the PNG exports.')


def png(svg_name, out, size):
    w, h = size
    html = KIT / '_render.html'
    html.write_text(f'<html><body style="margin:0;background:transparent">'
                    f'<img src="{svg_name}" style="width:{w}px;height:{h}px;display:block"></body></html>')
    subprocess.run([chrome(), '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000', f'--window-size={w},{h}',
                    f'--screenshot={out}', html.as_uri()], check=True, capture_output=True)
    html.unlink()


if __name__ == '__main__':
    PNG.mkdir(parents=True, exist_ok=True)
    symbols()
    lockups()
    BRAND = ROOT / 'brand'
    (BRAND / 'banner.svg').write_text(banner(dark=False))
    (BRAND / 'banner-dark.svg').write_text(banner(dark=True))
    write('social-preview.svg', social())
    png('parley-app-icon.svg', PNG / 'app-icon-1024.png', (1024, 1024))
    png('parley-adaptive-foreground.svg', PNG / 'adaptive-foreground-1024.png', (1024, 1024))
    png('parley-adaptive-monochrome.svg', PNG / 'adaptive-monochrome-1024.png', (1024, 1024))
    png('social-preview.svg', BRAND / 'banner.png', (1280, 640))
    png('parley-lockup.svg', PNG / 'lockup-1200.png', (1200, 464))
    print('Brand kit written to', KIT)
