import math, os, sys

SS = 4

class Ellipse:
    def __init__(s, region, cx, cy, rx, ry, rot=0):
        s.region, s.cx, s.cy, s.rx, s.ry, s.rot = region, cx, cy, rx, ry, math.radians(rot)
    def hit(s, x, y):
        dx, dy = x - s.cx, y - s.cy
        c, n = math.cos(s.rot), math.sin(s.rot)
        u, v = dx * c + dy * n, -dx * n + dy * c
        return (u / s.rx) ** 2 + (v / s.ry) ** 2 <= 1

class Capsule:
    def __init__(s, region, x0, y0, x1, y1, r0, r1=None):
        s.region, s.a, s.b, s.r0, s.r1 = region, (x0, y0), (x1, y1), r0, r0 if r1 is None else r1
    def hit(s, x, y):
        (ax, ay), (bx, by) = s.a, s.b
        vx, vy = bx - ax, by - ay
        L = vx * vx + vy * vy
        t = 0 if L == 0 else max(0, min(1, ((x - ax) * vx + (y - ay) * vy) / L))
        px, py = ax + vx * t, ay + vy * t
        r = s.r0 + (s.r1 - s.r0) * t
        return (x - px) ** 2 + (y - py) ** 2 <= r * r

class Poly:
    def __init__(s, region, pts):
        s.region, s.pts = region, pts
    def hit(s, x, y):
        inside = False
        n = len(s.pts)
        for i in range(n):
            (x0, y0), (x1, y1) = s.pts[i], s.pts[(i + 1) % n]
            if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
                inside = not inside
        return inside

class Dot:
    def __init__(s, region, x, y, w=1, h=1):
        s.region, s.x, s.y, s.w, s.h = region, x, y, w, h

def chain(region, x, y, angles, length, r0, r1):
    out = []
    n = len(angles)
    for i, a in enumerate(angles):
        nx, ny = x + math.cos(a) * length, y + math.sin(a) * length
        out.append(Capsule(region, x, y, nx, ny, r0 + (r1 - r0) * i / n, r0 + (r1 - r0) * (i + 1) / n))
        x, y = nx, ny
    return out

def bbox(s):
    if isinstance(s, Ellipse):
        r = max(s.rx, s.ry)
        return s.cx - r, s.cy - r, s.cx + r, s.cy + r
    if isinstance(s, Capsule):
        r = max(s.r0, s.r1)
        (ax, ay), (bx, by) = s.a, s.b
        return min(ax, bx) - r, min(ay, by) - r, max(ax, bx) + r, max(ay, by) + r
    xs, ys = [p[0] for p in s.pts], [p[1] for p in s.pts]
    return min(xs), min(ys), max(xs), max(ys)

def raster(shapes, w, h, d, oy=0):
    W, H = int(math.ceil(w * d)), int(math.ceil(h * d))
    grid = [[None] * W for _ in range(H)]
    unit = [[((px + .5) / d, (py + .5) / d - oy) for px in range(W)] for py in range(H)]
    solids = [(s, bbox(s)) for s in shapes if not isinstance(s, Dot)]
    offs = [(k + .5) / SS for k in range(SS)]
    for py in range(H):
        y0, y1 = py / d - oy, (py + 1) / d - oy
        row = [(s, b) for s, b in solids if b[1] <= y1 and b[3] >= y0]
        if not row:
            continue
        for px in range(W):
            x0, x1 = px / d, (px + 1) / d
            cand = [s for s, b in row if b[0] <= x1 and b[2] >= x0]
            if not cand:
                continue
            votes = {}
            for oyy in offs:
                y = (py + oyy) / d - oy
                for oxx in offs:
                    x = (px + oxx) / d
                    top = None
                    for s in cand:
                        if s.hit(x, y):
                            top = s.region
                    votes[top] = votes.get(top, 0) + 1
            best = max(votes, key=votes.get)
            if best is not None and votes[best] >= SS * SS * 0.45:
                grid[py][px] = best
            elif best is None and votes[None] < SS * SS * 0.55:
                filled = {k: v for k, v in votes.items() if k is not None}
                grid[py][px] = max(filled, key=filled.get)
    for s in shapes:
        if isinstance(s, Dot):
            x0, y0 = int(s.x * d), int((s.y + oy) * d)
            for yy in range(y0, y0 + max(1, round(s.h * d * .8))):
                for xx in range(x0, x0 + max(1, round(s.w * d * .8))):
                    if 0 <= yy < H and 0 <= xx < W:
                        grid[yy][xx] = s.region
    return grid, unit

def hexrgb(h):
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]

def rgbhex(c):
    return ''.join(f'{max(0, min(255, int(round(v)))):02x}' for v in c)

def mix(a, b, t):
    A, B = hexrgb(a), hexrgb(b)
    return rgbhex([x + (y - x) * t for x, y in zip(A, B)])

MOON = 'c8d3f5'
SHADE = '1a1b2e'
FLAT = set('enikTwW')

def paint_frame(grid, unit, paint, far='L', anchors=None):
    H, W = len(grid), len(grid[0])
    out = [[None] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            r = grid[y][x]
            if r is None:
                continue
            u, v = unit[y][x]
            c = paint(r, u, v, anchors)
            if r not in FLAT:
                above = grid[y - 1][x] if y else None
                below = grid[y + 1][x] if y + 1 < H else None
                if r in far or r == 'P':
                    c = mix(c, SHADE, .35)
                elif above is None:
                    c = mix(c, MOON, .22)
                elif below is None or (below is not None and below in far + 'lpP' and r in 'bBh'):
                    c = mix(c, SHADE, .25)
            out[y][x] = c
    return out

def outline(img, color='13152a'):
    H, W = len(img), len(img[0])
    big = [[None] * (W + 2) for _ in range(H + 2)]
    for y in range(H):
        for x in range(W):
            big[y + 1][x + 1] = img[y][x]
    out = [row[:] for row in big]
    for y in range(H + 2):
        for x in range(W + 2):
            if big[y][x] is None:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < H + 2 and 0 <= xx < W + 2 and big[yy][xx] is not None:
                        out[y][x] = color
                        break
    return out

NIGHT = (0x2a, 0x2e, 0x48)

def night(c, amount=.2, dim=.9):
    rgb = hexrgb(c)
    return rgbhex([ch * dim * (1 - amount) + n * amount for ch, n in zip(rgb, NIGHT)])

def render(shapes, anchors, w, h, d, paint, oy=0):
    g, u = raster(shapes, w, h, d, oy)
    return outline(paint_frame(g, u, paint, 'L', anchors))
