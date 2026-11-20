import struct, zlib

def _chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)

def _rows(buf, W, x, y, w, h):
    out = bytearray()
    for r in range(y, y + h):
        out.append(0)
        out += buf[(r * W + x) * 4:(r * W + x + w) * 4]
    return zlib.compress(bytes(out), 9)

def _ihdr(W, H):
    return _chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0))

def write_png(path, W, H, buf):
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + _ihdr(W, H) + _chunk(b'IDAT', _rows(buf, W, 0, 0, W, H)) + _chunk(b'IEND', b''))

def png_bytes(W, H, buf):
    return b'\x89PNG\r\n\x1a\n' + _ihdr(W, H) + _chunk(b'IDAT', _rows(buf, W, 0, 0, W, H)) + _chunk(b'IEND', b'')

def _dirty(prev, cur, W, H):
    stride = W * 4
    rows = [r for r in range(H) if prev[r * stride:(r + 1) * stride] != cur[r * stride:(r + 1) * stride]]
    if not rows:
        return None
    x0, x1 = W, -1
    for r in rows:
        a, b = prev[r * stride:(r + 1) * stride], cur[r * stride:(r + 1) * stride]
        lo = 0
        while lo < W and a[lo * 4:lo * 4 + 4] == b[lo * 4:lo * 4 + 4]:
            lo += 1
        hi = W - 1
        while hi > lo and a[hi * 4:hi * 4 + 4] == b[hi * 4:hi * 4 + 4]:
            hi -= 1
        x0, x1 = min(x0, lo), max(x1, hi)
    return x0, rows[0], x1 - x0 + 1, rows[-1] - rows[0] + 1

class APNG:
    def __init__(s, W, H, delay_ms):
        s.W, s.H, s.delay = W, H, delay_ms
        s.frames = []
        s.prev = None
    def add(s, buf):
        buf = bytes(buf)
        if s.prev is None:
            s.frames.append([(0, 0, s.W, s.H), s.delay, _rows(buf, s.W, 0, 0, s.W, s.H)])
        else:
            rect = _dirty(s.prev, buf, s.W, s.H)
            if rect is None:
                s.frames[-1][1] += s.delay
            else:
                s.frames.append([rect, s.delay, _rows(buf, s.W, *rect)])
        s.prev = buf
    def write(s, path):
        out = [b'\x89PNG\r\n\x1a\n', _ihdr(s.W, s.H), _chunk(b'acTL', struct.pack('>II', len(s.frames), 0))]
        seq = 0
        for i, ((x, y, w, h), delay, data) in enumerate(s.frames):
            out.append(_chunk(b'fcTL', struct.pack('>IIIIIHHBB', seq, w, h, x, y, delay, 1000, 0, 0)))
            seq += 1
            if i == 0:
                out.append(_chunk(b'IDAT', data))
            else:
                out.append(_chunk(b'fdAT', struct.pack('>I', seq) + data))
                seq += 1
        out.append(_chunk(b'IEND', b''))
        with open(path, 'wb') as f:
            f.write(b''.join(out))
