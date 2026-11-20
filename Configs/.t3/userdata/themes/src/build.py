"""Build the Tokyo Night theme for T3 Code.

Writes, next to the theme folder:
  tokyo-night.png   the rooftop groups and their cats, as an animated PNG
                    (T3 Code serves it as --theme-background-image)
  tokyo-night.json  "css" rebuilt from tokyo-night.css, with the sky SVG embedded
T3 Code themes can't load files from CSS (url() takes data: only), so the sky's
images are inlined as data URLs; the CSS may not contain backslashes and must stay
under 50,000 characters.
"""
import base64, json, os, sys, urllib.parse
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import city, scene
from apng import png_bytes

def grid_png(grid, pal):
    buf = bytearray(grid.w * grid.h * 4)
    for y, row in enumerate(grid.p):
        for x, ch in enumerate(row):
            if ch != '.':
                c = pal[ch]
                buf[(y * grid.w + x) * 4:(y * grid.w + x) * 4 + 4] = bytes((int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    return 'data:image/png;base64,' + base64.b64encode(png_bytes(grid.w, grid.h, buf)).decode()

def sky_svgs():
    groups = city.build_all()
    out = {}
    for name in ('tokyo-night', 'moon'):
        svg = open(os.path.join(HERE, f'{name}.svg')).read()
        for part in ('far', 'mid', 'moon'):
            ref = 'sprite:moon' if part == 'moon' else f'sprite:city-{part}'
            svg = svg.replace(f"{ref}'", grid_png(*groups[part]) + "'")
        out[name] = svg
    import random
    r = random.Random(3)
    slots = r.sample(groups['midslots'], min(16, len(groups['midslots'])))
    rects = ''.join(f"<g class='mw{k + 1}'>" + ''.join(f"<rect class='mw' x='{x}' y='{y}' width='2' height='4'/>" for x, y in slots[k::4]) + '</g>'
                    for k in range(4))
    out['tokyo-night'] = out['tokyo-night'].replace('MIDWINDOWS', rects)
    return out

def data_url(svg):
    return 'data:image/svg+xml,' + ' '.join(svg.split()).replace('%', '%25').replace('#', '%23')

def css(svgs):
    out = open(os.path.join(HERE, 'tokyo-night.css')).read()
    out = out.replace('scene.svg', data_url(svgs['tokyo-night'])).replace('moon.svg', data_url(svgs['moon']))
    if '\\' in out or len(out) > 50000:
        raise SystemExit(f'tokyo-night: css is {len(out)} characters or has a backslash')
    return out

def main(themes):
    scene.main(os.path.join(themes, 'tokyo-night.png'))
    path = os.path.join(themes, 'tokyo-night.json')
    theme = json.load(open(path))
    theme['css'] = css(sky_svgs())
    with open(path, 'w') as f:
        json.dump(theme, f, indent=2)
        f.write('\n')

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(HERE))
