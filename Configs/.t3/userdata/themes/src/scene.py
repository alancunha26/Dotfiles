import math, os, sys
from multiprocessing import Pool
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import city, coats, poses as P
from rig import render
from apng import APNG

FPS = 20
DT = 1 / FPS
T = 48.0
FRAMES = int(round(T * FPS))
D = 1.5
UNIT = 3
HEAD = 34
GW, GH = 200, 96
RW, RH = GW * UNIT, (GH + HEAD) * UNIT
W, H = RW * 2, RH
TAU = 2 * math.pi

FAMILY = {'sit': (P.SIT, 10.0), 'quad': (P.STAND, 13.0), 'loaf': (P.LOAF, 12.0), 'lie': (P.LIE, 17.0)}


def q(x, n):
    return round(x * n) / n

IDLE, WALK, LOAF, LIE = 3.2, .85, 3.6, 4.4

def clock(g, c, period):
    return (g * c['rate'] / period + c['phase']) % 1

def blink(g, c):
    return (g + c['phase'] * 7) % 3.7 < .15

def twitch(g, c):
    return 1.0 if (g + c['phase'] * 11) % 6.3 < .15 else 0.0

def idle(g, c, **kw):
    kw.setdefault('eye', 'closed' if blink(g, c) else 'open')
    return ('sit', 'sit', dict(t=q(clock(g, c, IDLE), 64), twitch=twitch(g, c), bow=c['bow'], **kw))

def act_sit(k, g, c): return idle(g, c)
def act_look(k, g, c): return idle(g, c, look=1.0)
def act_swat(k, g, c):
    up = math.sin(math.pi * min(1, k * 2)) if k < .5 else math.sin(math.pi * min(1, (k - .5) * 2))
    return idle(g, c, look=1.0, eye='open', paw=(round(13.9 + 2.7 * up, 1), round(18.2 - 12.2 * up, 1)))
def act_meow(k, g, c):
    m = max(0, math.sin(math.pi * (k - .1) / .8)) if .1 < k < .9 else 0
    return idle(g, c, look=.6, eye='open', mouth=q(m, 6), tongue=m > .6)
def act_groom(k, g, c):
    lick = q(math.sin(TAU * (g * 2.4 + c['phase'])), 4)
    return idle(g, c, paw=(15.4, round(8.4 - .3 * lick, 2)), hdx=.6, hdy=round(1.0 + .25 * lick, 2), eye=None, tongue=lick > 0)
def act_itch(k, g, c):
    sw = q(math.sin(TAU * (g * 5.5 + c['phase'])), 2)
    return idle(g, c, hind=(round(11.2 + .5 * sw, 2), round(7.6 + .6 * sw, 2)), hdx=-.4, hdy=.6, eye='closed')
def act_walk(k, g, c): return ('quad', 'walk', dict(t=q(clock(g, c, WALK), 17), bow=c['bow']))
def act_stretch(k, g, c):
    s = min(1, k / .4) if k < .4 else 1 if k < .6 else max(0, (1 - k) / .4)
    s = .5 - .5 * math.cos(math.pi * s)
    return ('quad', 'stretch', dict(k=q(s, 12), bow=c['bow']))
def act_crouch(k, g, c): return ('quad', 'crouch', dict(bow=c['bow']))
def act_jump(k, g, c): return ('quad', 'leap' if k < .5 else 'fall', dict(bow=c['bow']))
def act_loaf(k, g, c): return ('loaf', 'loaf', dict(t=q(clock(g, c, LOAF), 72)))
def act_sleep(k, g, c): return ('loaf', 'loaf', dict(t=q(clock(g, c, LOAF * 1.4), 72), sleep=True))
def act_lie(k, g, c): return ('lie', 'lie', dict(t=q(clock(g, c, LIE), 88)))
def act_yawn(k, g, c): return ('lie', 'lie', dict(t=q(clock(g, c, LIE), 88), yawn=q(math.sin(math.pi * k), 8)))
def act_lsleep(k, g, c): return ('lie', 'lie', dict(t=q(clock(g, c, LIE * 1.4), 88), sleep=True))

CLOCKS = {'siamese': (.13, 1.0), 'tabby': (.47, .9), 'black': (.71, 1.1), 'calico': (.29, .95),
          'siamese2': (.83, 1.06), 'lynx': (.55, .92)}

ACTIONS = {n[4:]: f for n, f in globals().items() if n.startswith('act_')}
SLEEPY = {'sleep', 'lsleep'}


def S(dur, action, at, to=None, face=1):
    return (dur, action, at, to or at, face)

SCRIPTS = {
    'siamese': ('siamese', 'right', True, [
        S(6, 'sit', (150, 36), face=-1), S(1.8, 'look', (150, 36), face=-1), S(.64, 'swat', (150, 36), face=-1), S(2.6, 'look', (150, 36), face=-1),
        S(.64, 'swat', (150, 36), face=-1), S(2.3, 'look', (150, 36), face=-1), S(6, 'sit', (150, 36), face=-1), S(1.6, 'meow', (150, 36), face=-1),
        S(8.4, 'sit', (150, 36), face=-1), S(4, 'groom', (150, 36), face=-1), S(2.2, 'itch', (150, 36), face=-1), S(3.5, 'sit', (150, 36), face=-1),
        S(2.5, 'look', (150, 36), face=-1), S(.64, 'swat', (150, 36), face=-1), S(5.18, 'look', (150, 36), face=-1)]),
    'tabby': ('tabby', 'left', False, [
        S(3, 'sit', (100, 50), face=-1), S(1.4, 'stretch', (100, 50), face=1),
        S(1.4, 'walk', (100, 50), (108, 50), face=1), S(.4, 'crouch', (108, 50), face=1),
        S(.7, 'jump', (108, 50), (123, 34), face=1), S(.3, 'crouch', (123, 34), face=1),
        S(2, 'sit', (123, 34), face=-1), S(4, 'groom', (123, 34), face=-1), S(2.4, 'itch', (123, 34), face=-1),
        S(2.4, 'look', (123, 34), face=-1), S(.4, 'crouch', (123, 34), face=-1),
        S(.7, 'jump', (123, 34), (98, 50), face=-1), S(.3, 'crouch', (98, 50), face=-1),
        S(3, 'walk', (98, 50), (86, 50), face=-1), S(1.6, 'meow', (86, 50), face=-1),
        S(9, 'loaf', (86, 50), face=-1), S(1.4, 'stretch', (86, 50), face=1),
        S(2.4, 'walk', (86, 50), (100, 50), face=1), S(3.2, 'sit', (100, 50), face=1),
        S(4, 'look', (100, 50), face=-1), S(4, 'sit', (100, 50), face=-1)]),
    'black': ('black', 'left', False, [
        S(6, 'sit', (61, 42), face=1), S(3, 'look', (61, 42), face=1), S(4, 'groom', (61, 42), face=1),
        S(4, 'loaf', (61, 42), face=1), S(8, 'sleep', (61, 42), face=1), S(1.4, 'loaf', (61, 42), face=1),
        S(1.4, 'stretch', (61, 42), face=1), S(.4, 'crouch', (61, 42), face=1),
        S(.7, 'jump', (61, 42), (70, 50), face=1), S(.3, 'crouch', (70, 50), face=1),
        S(5.4, 'sit', (70, 50), face=1), S(.4, 'crouch', (70, 50), face=-1),
        S(.7, 'jump', (70, 50), (61, 42), face=-1), S(.3, 'crouch', (61, 42), face=-1),
        S(3.6, 'sit', (61, 42), face=1), S(4.6, 'look', (61, 42), face=1), S(3.8, 'sit', (61, 42), face=1)]),
    'calico': ('calico', 'right', False, [
        S(5, 'walk', (118, 48), (84, 48), face=-1), S(.4, 'crouch', (84, 48), face=-1),
        S(.7, 'jump', (84, 48), (50, 38), face=-1), S(.3, 'crouch', (50, 38), face=-1),
        S(2.6, 'sit', (50, 38), face=-1), S(2.4, 'look', (50, 38), face=-1), S(1.6, 'meow', (50, 38), face=-1),
        S(2.0, 'walk', (50, 38), (40, 38), face=-1), S(3, 'loaf', (40, 38), face=-1),
        S(8, 'sleep', (40, 38), face=-1), S(1.6, 'loaf', (40, 38), face=-1), S(1.4, 'stretch', (40, 38), face=1),
        S(1.8, 'walk', (40, 38), (52, 38), face=1), S(.4, 'crouch', (52, 38), face=1),
        S(.7, 'jump', (52, 38), (86, 48), face=1), S(.3, 'crouch', (86, 48), face=1),
        S(4.6, 'walk', (86, 48), (118, 48), face=1), S(5, 'groom', (118, 48), face=1), S(2.2, 'itch', (118, 48), face=1),
        S(2.2, 'sit', (118, 48), face=1), S(1.8, 'look', (118, 48), face=-1)]),
    'siamese2': ('siamese', 'left', False, [
        S(8, 'groom', (37, 27)), S(4, 'sit', (37, 27)), S(2.6, 'itch', (37, 27)),
        S(5, 'look', (37, 27)), S(8.4, 'sit', (37, 27)), S(8, 'groom', (37, 27)),
        S(4, 'look', (37, 27)), S(8, 'sit', (37, 27))]),
    'lynx': ('lynx', 'right', False, [
        S(10, 'lie', (183, 66), face=1), S(1.4, 'yawn', (183, 66)), S(13, 'lsleep', (183, 66)),
        S(1.0, 'lie', (183, 66)), S(1.4, 'yawn', (183, 66)), S(21.2, 'lie', (183, 66))]),
}

def locate(script, g):
    t = 0.0
    for dur, action, a, b, face in script:
        if g < t + dur or (dur, action, a, b, face) == script[-1]:
            k = min(1, max(0, (g - t) / dur))
            x = a[0] + (b[0] - a[0]) * k
            y = a[1] + (b[1] - a[1]) * k
            if action == 'jump':
                y -= (9 + abs(b[1] - a[1]) * .3) * 4 * k * (1 - k)
            return action, k, (x, y), face
        t += dur
    raise ValueError

def check_scripts():
    for name, (_, _, _, script) in SCRIPTS.items():
        total = sum(s[0] for s in script)
        if abs(total - T) > 1e-6:
            raise SystemExit(f'{name}: script is {total}s, not {T}s')


PAINTS = {}

def paint_for(coat):
    if coat not in PAINTS:
        PAINTS[coat] = getattr(coats, coat)()
    return PAINTS[coat]

def render_key(key):
    coat, family, fn, kw = key
    (w, h, g), _ = FAMILY[family]
    shapes, anchors = getattr(P, fn)(**dict(kw))
    grid = render(shapes, anchors, w, h, D, paint_for(coat))
    return key, [b''.join(b'\0\0\0\0' if c is None else bytes((int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)) for c in row) for row in grid]

def frame_plan():
    plan = []
    for f in range(FRAMES):
        g = f * DT
        items = []
        for name, (coat, side, bow, script) in SCRIPTS.items():
            action, k, pos, face = locate(script, g)
            phase, rate = CLOCKS[name]
            family, fn, kw = ACTIONS[action](k, g, {'bow': bow, 'phase': phase, 'rate': rate})
            items.append((name, side, (coat, family, fn, tuple(sorted(kw.items()))), pos, face, action))
        plan.append(items)
    return plan

def rgba(h, a=255):
    return bytes((int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a))

def blit_grid(buf, grid, pal, x0, y0, scale):
    for y, row in enumerate(grid.p):
        for x, ch in enumerate(row):
            if ch == '.':
                continue
            px = rgba(pal[ch])
            for dy in range(scale):
                i = ((y0 + y * scale + dy) * W + x0 + x * scale) * 4
                buf[i:i + 4 * scale] = px * scale

def put(buf, x, y, px):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        a = px[3]
        if a == 255:
            buf[i:i + 4] = px
        else:
            old = buf[i:i + 4]
            na = a + old[3] * (255 - a) // 255
            buf[i:i + 4] = bytes([min(255, (px[c] * a + old[c] * (255 - a) * old[3] // 255) // max(na, 1)) for c in range(3)] + [na])

def blit_sprite(buf, sprite, side, cx, surface, family, face):
    (w, h, ground), anchor = FAMILY[family]
    ox = (0 if side == 'left' else RW) + round(cx * UNIT)
    oy = HEAD * UNIT + round(surface * UNIT)
    for py, row in enumerate(sprite):
        sy = oy + round(((py - 1) / D - ground) * UNIT)
        for px in range(len(row) // 4):
            if not row[px * 4 + 3]:
                continue
            c = row[px * 4:px * 4 + 4]
            u0, u1 = (px - 1) / D, px / D
            sx = ox + round(((u0 - anchor) if face > 0 else (anchor - u1)) * UNIT)
            for dy in range(2):
                for dx in range(2):
                    put(buf, sx + dx, sy + dy, c)

Z = ['111', '.1.', '111']

def draw_z(buf, side, u, v, phase):
    ox = 0 if side == 'left' else RW
    for n in range(2):
        p = (phase + n * .5) % 1
        a = int(220 * (1 - p))
        x = ox + round((u + 1.5 * p + n * 1.2) * UNIT)
        y = HEAD * UNIT + round((v - 7 * p) * UNIT)
        for r, line in enumerate(Z):
            for c, ch in enumerate(line):
                if ch == '1':
                    for dy in range(2):
                        for dx in range(2):
                            put(buf, x + c * 2 + dx, y + r * 2 + dy, rgba('c8d3f5', a))

MOTH_WINDOWS = [(5.2, 13.6), (39.6, 44.2)]

def draw_moth(buf, g):
    for start, end in MOTH_WINDOWS:
        if start <= g < end:
            k = (g - start)
            leave = max(0, g - (end - 1.2))
            u = 147 + 9 * math.cos(TAU * k / 2.6) + 14 * leave * leave
            v = 12 + 5 * math.sin(TAU * k / 1.3) - 16 * leave
            a = 255 if leave == 0 else max(0, int(255 * (1 - leave / 1.2)))
            x, y = RW + round(u * UNIT), HEAD * UNIT + round(v * UNIT)
            up = int(g * 12) % 2
            for dx in range(-7, 8):
                for dy in range(-5, 6):
                    r = math.hypot(dx, dy * 1.3)
                    if r < 7:
                        put(buf, x + dx, y + dy, rgba('ffe6a6', int(a * .22 * (1 - r / 7))))
            body = [(0, 0), (1, 0), (0, 1), (1, 1)]
            wing = [(-2, -2), (-3, -2), (-2, -1), (-3, -3), (-4, -3)] if up else [(-2, 1), (-3, 1), (-2, 2), (-3, 2), (-4, 3)]
            for dx, dy in body:
                put(buf, x + dx, y + dy, rgba('fff1c8', a))
            for dx, dy in wing:
                put(buf, x + dx, y + dy, rgba('e8eefc', a))
                put(buf, x + 1 - dx, y + dy, rgba('e8eefc', a))

def window_flips(windows):
    import random
    r = random.Random(7)
    flips = []
    for side, wins in windows.items():
        for x, y, w, h, c in r.sample(wins, min(18, len(wins))):
            n = r.choice((1, 1, 2))
            for i in range(n):
                length = r.uniform(3, 14)
                start = r.uniform(i * T / n, (i + 1) * T / n - length)
                flips.append((side, x, y, w, h, c, start, start + length))
    return flips

def draw_flip(buf, side, x, y, w, h, c):
    on = c == 'x'
    color = rgba(city.PAL['w' if on else 'x'])
    bar = rgba(city.PAL['k'])
    ox = 0 if side == 'left' else RW
    for yy in range(h):
        px = bar if on and h > 3 and yy == h // 2 else color
        for dy in range(UNIT):
            for xx in range(w):
                i = ((HEAD * UNIT + (y + yy) * UNIT + dy) * W + ox + (x + xx) * UNIT) * 4
                buf[i:i + 4 * UNIT] = px * UNIT

def main(out, only=None):
    check_scripts()
    groups = city.build_all()
    flips = window_flips(groups['windows'])
    base = bytearray(W * H * 4)
    blit_grid(base, groups['left'][0], groups['left'][1], 0, HEAD * UNIT, UNIT)
    blit_grid(base, groups['right'][0], groups['right'][1], RW, HEAD * UNIT, UNIT)
    plan = frame_plan()
    used = plan if only is None else [plan[f] for f in sorted(only)]
    keys = sorted({it[2] for items in used for it in items}, key=repr)
    with Pool(4) as pool:
        sprites = dict(pool.map(render_key, keys, chunksize=4))
    anim = APNG(W, H, int(round(DT * 1000)))
    for f, items in enumerate(plan):
        if only is not None and f not in only:
            continue
        g = f * DT
        buf = bytearray(base)
        for side, x, y, w, h, c, on, off in flips:
            if on <= g < off:
                draw_flip(buf, side, x, y, w, h, c)
        for name, side, key, (cx, sy), face, action in items:
            blit_sprite(buf, sprites[key], side, cx, sy, key[1], face)
            if action in SLEEPY:
                hu = cx + (6.0 * face if action == 'sleep' else -10.0)
                draw_z(buf, side, hu, sy - (9 if action == 'sleep' else 12), (g / 2.4) % 1)
        draw_moth(buf, g)
        if only is not None:
            from apng import write_png
            write_png(f'{out}-{f:03d}.png', W, H, buf)
            continue
        anim.add(buf)
    if only is not None:
        return len(keys), len(only)
    anim.write(out)
    return len(keys), len(anim.frames)

if __name__ == '__main__':
    print(main(sys.argv[1], {int(round(float(t) * FPS)) for t in sys.argv[2:]} or None))
