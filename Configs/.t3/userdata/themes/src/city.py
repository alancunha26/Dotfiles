import sys, os, random
sys.path.insert(0, os.path.dirname(__file__))
class G:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.p = [['.'] * w for _ in range(h)]
    def set(s, x, y, c):
        if 0 <= x < s.w and 0 <= y < s.h:
            s.p[y][x] = c
    def get(s, x, y):
        return s.p[y][x] if 0 <= x < s.w and 0 <= y < s.h else '.'
    def rows(s, x0, y0, rows):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != '.':
                    s.set(x0 + dx, y0 + dy, ch)

R = random.Random(5)

PAL = {
    'A': '1d1f30', 'B': '202336', 'C': '1b1d2b',
    'a': '2a2e48',
    'r': '24273a', 'R': '3b4261',
    'K': '444a73', 'k': '16172a',
    'w': 'ffc777', 'v': 'c99a4e', 'x': '1a1b29',
    'F': '1a1c2b', 'g': '1f2133', 'u': '2a2e48',
    'f': '17182a',
}

WINDOWS = []

def win(g, x, y, w, h, odds):
    r = R.random()
    c = 'w' if r < odds[0] else 'v' if r < odds[1] else 'x'
    WINDOWS.append((x, y, w, h, c))
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            g.set(xx, yy, c)
    if c in 'wv' and h > 3:
        for xx in range(x, x + w):
            g.set(xx, y + h // 2, 'k')

def windows(g, x0, x1, top, bottom, w=3, h=5, dx=9, dy=16, odds=(0.10, 0.17)):
    for y in range(top, bottom - h + 1, dy):
        for x in range(x0, x1 - w + 1, dx):
            win(g, x, y, w, h, odds)

def wall(g, x0, x1, top, bottom, c):
    for y in range(top, bottom + 1):
        for x in range(x0, x1 + 1):
            g.set(x, y, c)
        g.set(x0, y, 'a')

def flat(g, x0, x1, roof, bottom, c, parapet=2, **kw):
    wall(g, x0, x1, roof, bottom, c)
    for x in range(x0, x1 + 1):
        g.set(x, roof, 'K')
        for k in range(1, parapet):
            g.set(x, roof + k, 'k')
    windows(g, x0 + 4, x1 - 3, roof + 8, bottom, **kw)

def gable(g, x0, x1, eave, peak, bottom, c, ridge=0, **kw):
    wall(g, x0 + 1, x1 - 1, eave, bottom, c)
    mid = (x0 + x1) / 2
    half = (x1 - x0) / 2 + 1 - ridge
    for x in range(x0 - 1, x1 + 2):
        top = int(round(peak + (eave - peak) * max(abs(x - mid) - ridge, 0) / half))
        for y in range(top, eave + 1):
            g.set(x, y, 'r')
        g.set(x, top, 'R' if x <= mid else 'r')
    for x in range(x0 - 1, x1 + 2):
        g.set(x, eave, 'k')
    windows(g, x0 + 4, x1 - 4, eave + 6, bottom, **kw)
    return int(round(mid))

def mansard(g, x0, x1, roof, eave, bottom, c):
    wall(g, x0, x1, eave, bottom, c)
    inset = eave - roof
    for y in range(roof, eave):
        k = (y - roof) // 2
        for x in range(x0 + inset // 2 - k, x1 - inset // 2 + k + 1):
            g.set(x, y, 'r')
        g.set(x0 + inset // 2 - k, y, 'R')
    for x in range(x0 + inset // 2, x1 - inset // 2 + 1):
        g.set(x, roof, 'R')
    for x in range(x0 + 6, x1 - 6, 10):
        win(g, x, roof + 4, 3, 4, (0.25, 0.4))
    for x in range(x0 - 1, x1 + 2):
        g.set(x, eave, 'K')
    windows(g, x0 + 5, x1 - 3, eave + 7, bottom)

def chimney(g, x, w, base, h, c='B'):
    for y in range(base - h, base + 1):
        for xx in range(x, x + w):
            g.set(xx, y, c)
        g.set(x, y, 'a')
    for xx in range(x - 1, x + w + 1):
        g.set(xx, base - h, 'K')
    return base - h

def water_tower(g, x, base):
    for y in range(base - 5, base):
        g.set(x + 1, y, 'k'); g.set(x + 8, y, 'k')
    for y in range(base - 14, base - 5):
        for xx in range(x, x + 10):
            g.set(xx, y, 'B')
        g.set(x, y, 'a')
    for xx in range(x - 1, x + 11):
        g.set(xx, base - 15, 'R')
    for xx in range(x + 1, x + 9):
        g.set(xx, base - 16, 'R')
    g.set(x + 4, base - 17, 'R'); g.set(x + 5, base - 17, 'R')

def hut(g, x, base, w=10, h=8):
    for y in range(base - h, base):
        for xx in range(x, x + w):
            g.set(xx, y, 'B')
        g.set(x, y, 'a')
    for xx in range(x - 1, x + w + 1):
        g.set(xx, base - h, 'K')
    for y in range(base - h + 3, base):
        for xx in range(x + 3, x + 6):
            g.set(xx, y, 'x')
    g.set(x + 4, base - h + 3, 'v')

def antenna(g, x, base, h=10):
    for y in range(base - h, base):
        g.set(x, y, 'R')
    for xx in range(x - 3, x + 4):
        g.set(xx, base - h + 2, 'R')
    for xx in range(x - 2, x + 3):
        g.set(xx, base - h + 5, 'R')

def dish(g, x, base):
    g.rows(x, base - 6, ['.RRR.', 'RrrrR', '.RRR.', '..R..', '..R..', '.RRR.'])

H = 96
anchors = {}

def left():
    g = G(200, H)
    mansard(g, 128, 186, 30, 40, H - 1, 'A')
    flat(g, 52, 132, 50, H - 1, 'B')
    hut(g, 56, 50)
    antenna(g, 108, 50, 11)
    gable(g, 2, 56, 50, 28, H - 1, 'C')
    top = chimney(g, 34, 6, 40, 13)
    water_tower(g, 120, 50)
    anchors['left'] = {'flat_roof': 50, 'chimney_top': top}
    return g

def right():
    g = G(200, H)
    flat(g, 0, 60, 38, H - 1, 'A')
    flat(g, 56, 130, 48, H - 1, 'C')
    dish(g, 66, 48)
    peak = gable(g, 126, 174, 56, 36, H - 1, 'B', ridge=7)
    chimney(g, 132, 5, 52, 10, 'A')
    flat(g, 170, 199, 66, H - 1, 'A', parapet=3, dx=8)
    antenna(g, 22, 38, 12)
    anchors['right'] = {'flat_roof': 48, 'peak_x': peak, 'peak_y': 36, 'ledge': 66}
    return g

MIDSLOTS = []

def mid():
    g = G(320, 64)
    x = -4
    while x < 320:
        w = R.randint(24, 40)
        eave = R.randint(26, 40)
        if R.random() < 0.55:
            peak = eave - R.randint(8, 14)
            mid_x = (x + x + w) / 2
            half = w / 2 + 1
            for xx in range(x, x + w + 1):
                top = int(round(peak + (eave - peak) * abs(xx - mid_x) / half))
                for y in range(top, 64):
                    g.set(xx % 320, y, 'g' if y < eave else 'F')
                g.set(xx % 320, top, 'u')
            if R.random() < 0.6:
                cx = x + R.randint(4, w - 8)
                for y in range(eave - 10, eave - 3):
                    g.set(cx % 320, y, 'F'); g.set((cx + 1) % 320, y, 'F'); g.set((cx + 2) % 320, y, 'F')
        else:
            for xx in range(x, x + w + 1):
                for y in range(eave, 64):
                    g.set(xx % 320, y, 'F')
                g.set(xx % 320, eave, 'u')
        for y in range(eave + 6, 60, 14):
            for xx in range(x + 4, x + w - 4, 9):
                r = R.random()
                if 0 <= xx < 318:
                    MIDSLOTS.append((xx, y))
                if r < 0.07:
                    for yy in range(y, y + 4):
                        g.set(xx % 320, yy, 'v'); g.set((xx + 1) % 320, yy, 'v')
        x += w + R.randint(0, 2)
    return g

def far():
    g = G(400, 90)
    x = 0
    while x < 400:
        w = R.randint(16, 34)
        top = R.randint(0, 34)
        for y in range(top, 90):
            for xx in range(x, x + w):
                g.set(xx % 400, y, 'f')
        for y in range(top + 4, 80, 6):
            for xx in range(x + 2, x + w - 2, 5):
                if R.random() < 0.04:
                    g.set(xx % 400, y, 'v')
        if R.random() < 0.4:
            ax = x + R.randint(3, w - 4)
            for y in range(top - R.randint(4, 9), top):
                g.set(ax % 400, y, 'f')
        x += w + R.randint(-3, 3)
    return g

def moon():
    import math
    g = G(22, 22)
    for y in range(22):
        for x in range(22):
            d = math.hypot(x - 10.5, y - 10.5)
            if d <= 10.2:
                g.set(x, y, 'M' if math.hypot(x - 7.5, y - 13.5) > 11.5 else 'm')
    for cx, cy, r in ((7, 8, 1.6), (13, 13, 2.2), (12, 5, 1.1), (6, 15, 1.2)):
        for y in range(22):
            for x in range(22):
                if math.hypot(x - cx, y - cy) <= r and g.get(x, y) != '.':
                    g.set(x, y, 'c')
    return g

MOON = {'m': 'ffc777', 'M': 'f0b35e', 'c': 'e6a84f'}

def build_all():
    R.seed(5)
    out, wins = {}, {}
    for name, fn in (('left', left), ('right', right)):
        WINDOWS.clear()
        out[name] = (fn(), PAL)
        wins[name] = list(WINDOWS)
    MIDSLOTS.clear()
    out['mid'] = (mid(), PAL)
    out['far'] = (far(), PAL)
    out['moon'] = (moon(), MOON)
    out['windows'] = wins
    out['midslots'] = list(MIDSLOTS)
    return out
