import math
from rig import night

KEEP = {'e', 'k', 'T', 'n', 'bow', 'knot'}

def N(pal):
    return {k: (v if k in KEEP else night(v)) for k, v in pal.items()}

DARK = '1c1618'

def tabby():
    P = N({'a': 'd08a48', 's': '9a5a2c', 'c': 'ecc08a', 'i': 'd98a8a', 'e': 'b8d070', 'n': 'c97a7a', 'k': DARK, 'T': 'e8889a'})
    def paint(r, u, v, A):
        hx, hy = A['head']
        if r in 'einkT':
            return P[r]
        if r in 'mBpP':
            return P['c']
        if r == 'b':
            return P['s'] if math.sin(u * 1.35) > .5 else P['a']
        if r == 'h':
            return P['s'] if v < hy - 1.2 and math.sin(u * 2.8) > .4 else P['a']
        if r == 't':
            return P['s'] if math.sin((u + v) * 1.5) > .35 else P['a']
        if r in 'lL':
            return P['s'] if math.sin(v * 2.2) > .7 else P['a']
        return P['a']
    return paint

def spine(u, v, A):
    hu, hv = A['haunch']
    su, sv = A['shoulder']
    dx, dy = su - hu, sv - hv
    L = math.hypot(dx, dy) or 1
    along = ((u - hu) * dx + (v - hv) * dy) / (L * L)
    side = (dx * (v - hv) - dy * (u - hu)) / L
    return along, side

def calico():
    P = N({'w': 'e2e4f0', 'o': 'd4893f', 'K': '4a4656', 'i': 'd98a8a', 'e': 'c8cc60', 'n': 'd98a8a', 'k': DARK, 'T': 'e8889a'})
    def paint(r, u, v, A):
        hx, hy = A['head']
        if r in 'einkT':
            return P[r]
        if r == 'E':
            return P['K'] if u < hx else P['o']
        if r == 'h':
            if v < hy - .6:
                return P['o'] if u < hx else P['K']
            return P['o'] if u < hx - 2.4 and v < hy + 1.2 else P['w']
        if r == 'b':
            along, side = spine(u, v, A)
            if along < .42 and side < 1.4:
                return P['o']
            if .42 <= along < .74 and side < 2.4:
                return P['K']
            return P['w']
        if r == 't':
            return P['o']
        return P['w']
    return paint

def siamese():
    P = N({'a': 'd6c8ac', 'c': 'e8dcc4', 'u': 'a8927a', 'd': '54403a', 'i': 'c98a7f', 'e': '7aa2f7',
           'n': '2a1f1c', 'k': DARK, 'T': 'e8889a', 'bow': 'ff757f', 'knot': 'c53b53'})
    def paint(r, u, v, A):
        mx, my = A['muzzle']
        g = A['ground']
        if r in 'einkT':
            return P[r]
        if r in 'wW':
            return P['bow' if r == 'w' else 'knot']
        if r in 'EtpP':
            return P['d']
        if r in 'lL':
            return P['d'] if v > g - 3.0 else P['u']
        if r in 'hm':
            d = math.hypot(u - mx, (v - my) * 1.15)
            return P['d'] if d < 1.9 else P['u'] if d < 3.0 else P['a']
        if r == 'B':
            return P['c']
        return P['a']
    return paint

def lynx():
    P = N({'a': 'd2cabd', 's': '857a6c', 'w': 'eceef6', 'i': 'd09a90', 'e': '82aaff', 'n': 'c98a7f', 'k': DARK, 'T': 'e8889a'})
    def paint(r, u, v, A):
        hx, hy = A['head']
        if r in 'einkT':
            return P[r]
        if r == 'E':
            return P['s'] if v < hy - 4.6 else P['a']
        if r == 'h':
            return P['s'] if v < hy - 2.2 and math.sin(u * 3.0) > .5 else P['a']
        if r in 'mBpP':
            return P['w']
        if r in 'lL':
            return P['s'] if math.sin(u * 2.2) > .55 else P['a']
        if r == 't':
            return P['s'] if math.sin(u * 1.8) > .2 or u > 32 else P['a']
        return P['a']
    return paint

def black():
    P = N({'a': '2a2c3e', 'c': '30334a', 'i': '5a4250', 'n': '4a3a48', 'T': 'e8889a'})
    P.update({'e': 'd7e36a', 'k': '4a5070'})
    def paint(r, u, v, A):
        if r in 'einkT':
            return P[r]
        if r in 'B':
            return P['c']
        return P['a']
    return paint
