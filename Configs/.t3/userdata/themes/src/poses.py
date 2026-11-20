import math
from rig import Ellipse as El, Capsule as Ca, Poly, Dot, chain

TAU = 2 * math.pi
R = math.radians

def head(hx, hy, look=0.0, eye='open', mouth=0.0, tongue=False, twitch=0.0, bow=False):
    hy -= .7 * look
    mx, my = hx + 2.8, hy + 1.3 - .7 * look
    s = [El('h', hx, hy, 3.9, 3.3), El('m', mx, my, 1.5, 1.2),
         Poly('E', [(hx - 2.5, hy - 1.6), (hx - 1.9 - twitch * .8, hy - 5.1 + twitch * .5), (hx, hy - 2.6)]),
         Poly('E', [(hx + .6, hy - 2.7), (hx + 1.8, hy - 5.4), (hx + 2.9, hy - 2.1)]),
         Poly('i', [(hx + 1.2, hy - 2.8), (hx + 1.8, hy - 4.3), (hx + 2.3, hy - 2.5)])]
    ey = hy - 1.1 - .5 * look
    if eye == 'open':
        s.append(Dot('e', hx + .7, ey, 1.6, 1.6))
    elif eye == 'closed':
        s.append(Dot('k', hx + .5, ey + .7, 1.8, .7))
    if mouth > 0:
        s.append(Dot('k', mx + .2, my + .5, 1.4, .6 + mouth))
        if tongue:
            s.append(Dot('T', mx + .4, my + 1.0 + mouth * .6, 1, 1))
    elif tongue:
        s.append(Dot('T', mx + .6, my + 1.0, 1, 1.1))
    s.append(Dot('n', mx + 1.0, my - .8, 1, 1))
    if bow:
        bx, by = hx + 1.6, hy + 3.6
        s += [Poly('w', [(bx - 1.9, by - 1.0), (bx - 1.9, by + 1.0), (bx, by)]),
              Poly('w', [(bx + 1.9, by - 1.0), (bx + 1.9, by + 1.0), (bx, by)]),
              Dot('W', bx - .4, by - .4, 1, 1)]
    return s, {'head': (hx, hy), 'muzzle': (mx, my)}

SIT = (21, 21, 18.8)

def sit(t=0.0, tail=None, look=0.0, eye='open', mouth=0.0, tongue=False, twitch=0.0,
        paw=None, hind=None, hdx=0.0, hdy=0.0, bow=False, breath=None):
    g = SIT[2]
    tip = (.5 + .35 * math.sin(TAU * t) + .15 * math.sin(TAU * t * 3)) if tail is None else tail
    b = .22 * math.sin(TAU * t * 2) if breath is None else breath
    s = chain('t', 6.6, 17.9, [R(180), R(185), R(-150 + 60 * tip), R(-110 + 70 * tip)], 1.7, 1.0, .8)
    s += [El('b', 7.9, 13.6 - b / 2, 4.7 + b * .3, 4.6 + b), Ca('b', 8.6, 13.4, 11.8, 7.6 - b * .6, 3.4 + b * .4, 3.0 + b * .3),
          El('B', 12.6 + b * .2, 10.6 - b * .3, 1.9 + b * .3, 3.2, -10)]
    hdy -= b * .5
    if hind:
        hx_, hy_ = hind
        s += [Ca('l', 9.0, 14.6, hx_, hy_, 1.1, .9), El('p', hx_, hy_, 1.2, .9)]
    else:
        s.append(El('p', 9.8, 18.2, 1.6, .75))
    s += [Ca('L', 12.2, 11.4, 12.6, 18.2, .95), El('P', 13.0, 18.3, 1.15, .7)]
    if paw:
        px, py = paw
        s += [Ca('l', 13.4, 11.4, px, py, 1.0), El('p', px + .2, py - .3, 1.2, .9)]
    else:
        s += [Ca('l', 13.5, 11.4, 13.9, 18.2, 1.0), El('p', 14.3, 18.3, 1.2, .72)]
    hs, a = head(12.8 + hdx, 4.6 + hdy, look, eye, mouth, tongue, twitch, bow)
    a.update(haunch=(7.9, 13.6), shoulder=(11.8, 8.6), ground=g)
    return s + hs, a

STAND = (29, 18, 16.0)

def quad(by=9.7, tilt=0.0, feet=None, head_at=(21.3, 5.0), look=0.0, tail=None, stretch=0.0, eye='open', bow=False):
    t = R(tilt)
    bx = 12.4
    hip = (bx - 5.0 * math.cos(t), by - 5.0 * math.sin(t) + 1.7)
    sho = (bx + 5.0 * math.cos(t), by + 5.0 * math.sin(t) + 1.7)
    feet = feet or {'bf': (6.4, 16), 'bn': (8.6, 16), 'ff': (16.4, 16), 'fn': (18.6, 16)}
    tail = tail or [R(a) for a in (-165, -140, -110, -85, -70)]
    s = []
    for k, start in (('ff', (sho[0] - .6, sho[1])), ('bf', (hip[0] - .6, hip[1]))):
        fx, fy = feet[k]
        s += [Ca('L', start[0], start[1], fx, fy, 1.05, .95), El('P', fx + .35, fy + .1, 1.15, .7)]
    s += chain('t', hip[0] - 2.6, hip[1] - 2.8, tail, 1.5, 1.0, .75)
    s += [El('b', hip[0] - .2, hip[1] - 1.4, 3.8, 3.5), El('b', bx, by, 7.4 + stretch, 3.2, tilt),
          El('B', sho[0] + .4, sho[1] - .4, 2.5, 2.3)]
    hx, hy = head_at
    s.append(Ca('b', sho[0] - .2, sho[1] - 2.2, hx - 1.5, hy + 1.2, 2.6, 2.3))
    for k, start in (('bn', hip), ('fn', (sho[0] + .4, sho[1] + .2))):
        fx, fy = feet[k]
        s += [Ca('l', start[0], start[1], fx, fy, 1.05, .95), El('p', fx + .35, fy + .1, 1.15, .7)]
    hs, a = head(hx, hy, look, eye, bow=bow)
    a.update(haunch=(hip[0] - .2, hip[1] - 1.4), shoulder=sho, ground=STAND[2])
    return s + hs, a

def walk(t, bow=False):
    p = TAU * t
    b = .3 * math.cos(2 * p)
    g = STAND[2]
    def foot(base, ph):
        sn = math.sin(ph)
        return (base + 2.0 * math.cos(ph), g if sn >= 0 else g - 1.3 * -sn)
    feet = {'ff': foot(16.6, p + math.pi), 'bf': foot(6.6, p), 'bn': foot(8.4, p + math.pi), 'fn': foot(18.6, p)}
    sway = math.sin(p) * .12
    tail = [R(a) + sway * k for k, a in enumerate((-165, -140, -110, -85, -70))]
    return quad(by=9.7 + b, feet=feet, head_at=(21.3, 5.0 + b), tail=tail, bow=bow)

def stretch(k, bow=False):
    lerp = lambda a, b: a + (b - a) * k
    feet = {'bf': (6.4, 16), 'bn': (8.6, 16), 'ff': (lerp(16.4, 22.6), 16), 'fn': (lerp(18.6, 24.4), 16)}
    tail = [R(a) for a in (lerp(-165, -120), lerp(-140, -100), lerp(-110, -80), lerp(-85, -60), lerp(-70, -40))]
    return quad(by=lerp(9.7, 11.0), tilt=lerp(0, 16), feet=feet, head_at=(lerp(21.3, 24.0), lerp(5.0, 10.4)),
                tail=tail, stretch=k * .6, eye='closed' if k > .7 else 'open', bow=bow)

def crouch(bow=False):
    feet = {'bf': (7.2, 16), 'bn': (9.2, 16), 'ff': (15.8, 16), 'fn': (17.8, 16)}
    return quad(by=11.4, feet=feet, head_at=(21.0, 7.0), look=.3, bow=bow)

def leap(bow=False):
    feet = {'bf': (2.6, 13.6), 'bn': (4.2, 14.8), 'ff': (23.0, 9.6), 'fn': (24.2, 11.2)}
    tail = [R(a) for a in (-178, -175, -170, -165, -160)]
    return quad(by=9.0, tilt=-10, feet=feet, head_at=(22.6, 4.2), tail=tail, stretch=1.0, bow=bow)

def fall(bow=False):
    feet = {'bf': (5.0, 13.0), 'bn': (6.6, 12.4), 'ff': (20.8, 16), 'fn': (22.6, 15.4)}
    tail = [R(a) for a in (-150, -120, -100, -90, -85)]
    return quad(by=10.0, tilt=10, feet=feet, head_at=(21.8, 6.6), tail=tail, stretch=.5, bow=bow)

LOAF = (25, 21, 18.8)

def loaf(t=0.0, sleep=False, mouth=0.0):
    g = LOAF[2]
    breath = .25 * math.sin(TAU * t) if sleep else .15 * math.sin(TAU * t * 2)
    flick = 0 if sleep else max(0, math.sin(TAU * t * 2)) ** 2
    s = chain('t', 4.6, 17.4, [R(110), R(20), R(5), R(-20 - 50 * flick)], 1.8, 1.0, .8)
    s += [El('b', 10.6, 15.2 - breath / 2, 6.8, 3.6 + breath), El('B', 16.2, 15.8, 2.3, 2.6),
          El('p', 18.6, 18.2, 1.5, .75), El('P', 17.0, 18.3, 1.3, .7)]
    if sleep:
        hs, a = head(18.4, 13.0, -.2, 'closed')
    else:
        blink = .6 <= t < .64
        hs, a = head(18.6, 11.0, 0, 'closed' if blink else 'open', mouth=mouth, tongue=mouth > .5)
    a.update(haunch=(6.4, 14.6), shoulder=(15.0, 13.8), ground=g)
    return s + hs, a

LIE = (34, 15, 12.4)

def lie(t=0.0, sleep=False, yawn=0.0):
    flick = 0 if sleep else (max(0, math.sin(TAU * t * 3)) ** 2 if t < .7 else 0)
    breath = .18 * math.sin(TAU * t)
    s = chain('t', 29.4, 11.4, [R(5), R(40), R(150 - 60 * flick), R(185 - 90 * flick)], 1.6, 1.0, .75)
    s += [El('b', 25.0, 9.2 - breath / 2, 4.6, 3.5 + breath), El('b', 17.0, 9.6 - breath / 2, 9.5, 3.0 + breath),
          El('B', 9.6, 10.0, 2.8, 2.5)]
    s += [Ca('L', 10.0, 11.0, 2.6, 11.2, .95), El('P', 2.4, 11.4, 1.3, .8)]
    s += [Ca('l', 10.6, 11.8, 3.4, 12.2, 1.0), El('p', 3.2, 12.4, 1.35, .8)]
    hy = 7.0 if sleep else 5.8 - .4 * yawn
    tw = 1.0 if (not sleep and .8 <= t < .84) else 0
    s += [El('h', 6.6, hy, 4.4, 3.7),
          Poly('E', [(2.4, hy - 1.4), (2.8 - tw, hy - 6.0 + tw * .6), (5.2, hy - 3.1)]),
          Poly('E', [(8.0, hy - 3.1), (10.4, hy - 6.0), (10.8, hy - 1.4)]),
          Poly('i', [(3.2, hy - 2.0), (3.3 - tw, hy - 4.6 + tw * .6), (4.7, hy - 2.9)]),
          Poly('i', [(8.5, hy - 2.9), (9.9, hy - 4.6), (10.0, hy - 2.0)]),
          El('m', 6.6, hy + 1.8, 1.8, 1.2)]
    closed = sleep or yawn > .4 or .5 <= t < .55
    if closed:
        s += [Dot('k', 3.9, hy - .2, 1.8, .7), Dot('k', 7.6, hy - .2, 1.8, .7)]
    else:
        s += [Dot('e', 4.3, hy - .8, 1.6, 1.6), Dot('e', 7.9, hy - .8, 1.6, 1.6)]
    if yawn > 0:
        s += [Dot('k', 5.8, hy + 1.9, 1.8, .6 + 1.4 * yawn)]
        if yawn > .5:
            s.append(Dot('T', 6.1, hy + 2.6 + yawn, 1, 1))
    s.append(Dot('n', 6.2, hy + 1.0, 1, 1))
    return s, {'head': (6.6, hy), 'muzzle': (6.6, hy + 1.8), 'haunch': (25.0, 9.2), 'shoulder': (10.0, 10.0), 'ground': LIE[2]}
