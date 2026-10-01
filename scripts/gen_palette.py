"""The palette behind `colors.hex`, `colors.rgb` and `colors.oklch`.

    py -3 scripts/gen_palette.py            write textures/codeblock_palette_<n>.png
    py -3 scripts/gen_palette.py --check    say whether they match the list
    py -3 scripts/gen_palette.py --sample   build the list again (see below)

lib/palette_hexes.lua is the source of truth, and the sixteen textures are drawn
from it: node codeblock:color_<n> holds entries n * 256 to n * 256 + 255, its
16x16 texture read left to right, top to bottom, pixel i being entry
n * 256 + i. Pixels past the end of the list are black and never placed.

**Never re-run --sample once a release has shipped the list.** A world stores
a colour as its node and param2, so a changed list recolours every palette
block already built. The sampler is kept as the record of how the list was
made:

1. A grid in OKLCh, L through Ottosson's toe, the lightness Okhsl uses: 47
   lightness levels of step 1/46, chroma rings of step 0.022, and on ring k
   round(2 pi k / 1.5) hues, at least 3, the first at hue 0. Neighbours on a
   ring sit 1.5 ring steps apart, which spends the budget on lightness and
   chroma steps rather than hue. The greys are ring 0, black and white
   included. Kept where sRGB can show it.
2. Each point rounded to 8-bit sRGB. A point landing on a hex already taken is
   dropped, and so is one whose hex no longer rounds back to its own cell,
   which would stop it snapping to itself.
3. The six pure primaries and secondaries, #ff0000 to #ff00ff, added off the
   grid: none of the cube's corners is a grid point.
4. Ordered greys light to dark, then the rest by hue, lightness and chroma.

Each grid entry carries its cell, the level, ring and hue lib/palette.lua
rounds to, so no float in the snap decides membership; a corner carries none.

No Pillow on this machine, so the PNG is assembled from zlib + struct.
"""
import math
import os
import re
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIST = os.path.join(ROOT, 'lib', 'palette_hexes.lua')
NODES = 16
LEVELS, RING, HUE = 46, 0.022, 1.5
CORNERS = [(255, 0, 0), (255, 255, 0), (0, 255, 0), (0, 255, 255),
           (0, 0, 255), (255, 0, 255)]


def to_linear(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def to_srgb(c):
    c = min(1.0, max(0.0, c))
    c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return min(255, max(0, round(c * 255)))


def cbrt(x):
    return math.copysign(abs(x) ** (1 / 3), x)


K1, K2 = 0.206, 0.03
K3 = (1 + K1) / (1 + K2)


def toe(L):
    return (K3 * L - K1 + math.sqrt((K3 * L - K1) ** 2 + 4 * K2 * K3 * L)) / 2


def untoe(Lr):
    return (Lr * Lr + K1 * Lr) / (K3 * (Lr + K2))


def oklab(rgb):
    """OKLab of an 8-bit sRGB triple (Ottosson's matrices), L through the toe."""
    r, g, b = (to_linear(c) for c in rgb)
    l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return (toe(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s),
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def linear(L, a, b):
    """Linear sRGB of plain OKLab."""
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def hues(k):
    return 1 if k == 0 else max(3, math.floor(2 * math.pi * k / HUE + 0.5))


def cell(p):
    """The level, ring and hue lib/palette.lua rounds a toe-OKLab point to."""
    Lr, a, b = p
    k = math.floor(math.hypot(a, b) / RING + 0.5)
    h = math.atan2(b, a) % (2 * math.pi)
    return (math.floor(Lr * LEVELS + 0.5), k,
            math.floor(h / (2 * math.pi) * hues(k) + 0.5) % hues(k))


def sample():
    """[(rgb, cell or None)] in index order, and the count of dropped points."""
    taken, entries, dropped = set(), [], 0
    for il in range(LEVELS + 1):
        L = untoe(il / LEVELS)
        for k in range(int(0.4 / RING)):
            for j in range(hues(k)):
                t = 2 * math.pi * j / hues(k)
                lin = linear(L, k * RING * math.cos(t), k * RING * math.sin(t))
                if min(lin) < -1e-9 or max(lin) > 1 + 1e-9:
                    continue
                rgb = tuple(to_srgb(c) for c in lin)
                if rgb in taken or cell(oklab(rgb)) != (il, k, j):
                    dropped += 1
                    continue
                taken.add(rgb)
                entries.append((rgb, (il, k, j)))
    # The snap falls back to ring 0, so every level needs its grey.
    assert sum(1 for _, c in entries if c[1] == 0) == LEVELS + 1
    for c in CORNERS:
        assert c not in taken
        entries.append((c, None))

    # By the grid cell rather than the hex, whose rounding jitters a hue of 0
    # to either side of the wrap.
    def order(e):
        if e[1] is None:
            Lr, a, b = oklab(e[0])
            return (1, math.degrees(math.atan2(b, a)) % 360, Lr * LEVELS,
                    math.hypot(a, b) / RING)
        il, k, j = e[1]
        if k == 0:
            return (0, -il, 0, 0)
        return (1, 360 * j / hues(k), il, k)

    entries.sort(key=order)
    assert len(entries) <= NODES * 256
    return entries, dropped


def write_list(entries):
    lines = [
        '-- The palette, index 0 first: {hex, level, ring, hue}, the last three the',
        "-- entry's cell on the grid lib/palette.lua rounds to, absent for the six",
        '-- pure colours off it. Generated once by',
        '-- `py -3 scripts/gen_palette.py --sample`, and never again once a',
        '-- release has shipped it: a world stores only the index, so a changed',
        '-- list recolours every palette block already built.',
        'return {',
    ]
    for i in range(0, len(entries), 4):
        row = []
        for rgb, c in entries[i:i + 4]:
            hexs = "'#%02x%02x%02x'" % rgb
            row.append('{%s, %d, %d, %d}' % ((hexs,) + c) if c else
                       '{%s}' % hexs)
        lines.append('    ' + ', '.join(row) + ',')
    lines.append('}')
    with open(LIST, 'w', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')


def read_list():
    with open(LIST) as f:
        hexes = re.findall(r"'#([0-9a-f]{6})'", f.read())
    return [tuple(int(h[k:k + 2], 16) for k in (0, 2, 4)) for h in hexes]


def png_bytes(colours):
    """A 16x16 8-bit RGB PNG of up to 256 colours, black past the end."""
    colours = colours + [(0, 0, 0)] * (256 - len(colours))
    raw = bytearray()
    for y in range(16):
        raw.append(0)  # filter type 0
        for c in colours[y * 16:(y + 1) * 16]:
            raw += bytes(c)

    def chunk(tag, data):
        head = struct.pack('>I', len(data)) + tag + data
        return head + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', 16, 16, 8, 2, 0, 0, 0)  # 8-bit RGB
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) +
            chunk(b'IDAT', zlib.compress(bytes(raw), 9)) +
            chunk(b'IEND', b''))


if '--sample' in sys.argv:
    entries, dropped = sample()
    write_list(entries)
    print('%d colours, %d grid points dropped' % (len(entries), dropped))

colours = read_list()
stale = []
for n in range(NODES):
    path = os.path.join(ROOT, 'textures', 'codeblock_palette_%x.png' % n)
    blob = png_bytes(colours[n * 256:(n + 1) * 256])
    if '--check' in sys.argv:
        try:
            with open(path, 'rb') as f:
                same = f.read() == blob
        except FileNotFoundError:
            same = False
        if not same:
            stale.append(os.path.basename(path))
    else:
        with open(path, 'wb') as f:
            f.write(blob)

if '--check' in sys.argv:
    print('palette textures ' +
          ('up to date' if not stale else 'out of date: ' + ' '.join(stale)))
else:
    print('wrote %d palette textures' % NODES)
