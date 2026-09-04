"""Write the two 16x16 tiles that lib/nodes.lua tints per colour.

    python scripts/gen_textures.py

Run it when the tiles need redrawing; the PNGs it writes are committed, and
nothing checks that they match this source. It is the editable source for
textures/codeblock_block.png and textures/codeblock_glass.png the way the .svg
files beside them are for the two tool icons.

No Pillow on this machine, so the PNGs are assembled from zlib + struct.
Both tiles are near-white, because the node definitions apply
`^[multiply:#rrggbb`, which scales RGB per pixel: a near-white base reproduces
the hex almost exactly and any darker pixel becomes a proportionally darker
shade of the same colour. `^[colorize:#rrggbb:255` would have replaced every
pixel with the flat colour and thrown the grain away.
"""
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'textures')

W = H = 16


def png(path, rows):
    """Write 8-bit RGBA rows, each a list of (r, g, b, a), as a PNG."""
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter type 0
        for r, g, b, a in row:
            raw += bytes((r, g, b, a))

    def chunk(tag, data):
        head = struct.pack('>I', len(data)) + tag + data
        return head + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)  # 8-bit RGBA
    blob = (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(bytes(raw), 9))
            + chunk(b'IEND', b''))
    with open(path, 'wb') as f:
        f.write(blob)
    return len(blob)


def hashnoise(x, y, salt):
    """Deterministic per-pixel value in [0, 1). No RNG state to seed."""
    n = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    n &= 0xffffffff
    n = (n ^ (n >> 13)) * 1274126177 & 0xffffffff
    return ((n ^ (n >> 16)) & 0xffff) / 65536.0


# --- codeblock_block.png ------------------------------------------------------
# Opaque, near-white, with a faint grain so a large flat wall reads at a
# distance instead of looking like a dead slab. The amplitude is deliberately
# small: the tint multiplies it, so more contrast here would show as dirt on a
# dark colour.
block = []
for y in range(H):
    row = []
    for x in range(W):
        # Two octaves - a fine speck plus a slow 4x4 mottle - so a tiled wall
        # does not read as television static.
        v = 250 - int(round(hashnoise(x, y, 1) * 9 + hashnoise(x // 4, y // 4, 2) * 5))
        row.append((v, v, v, 255))
    block.append(row)
print('codeblock_block.png', png(os.path.join(OUT, 'codeblock_block.png'), block))

# --- codeblock_glass.png ------------------------------------------------------
# A glasslike tile: an opaque near-white frame with a short highlight, over a
# barely-there fill. The node sets use_texture_alpha = 'blend', and [multiply
# leaves alpha alone, so the fill stays as transparent as it is here.
FILL = 56
glass = []
for y in range(H):
    row = []
    for x in range(W):
        if x == 0 or y == 0 or x == W - 1 or y == H - 1:
            row.append((252, 252, 252, 255))
        elif (x == 2 and 2 <= y <= 6) or (y == 2 and 3 <= x <= 6):
            # A highlight down the top-left inside corner, so the pane has a
            # direction and does not read as a plain rectangle.
            row.append((255, 255, 255, 190))
        else:
            v = 246 - int(round(hashnoise(x, y, 3) * 6))
            row.append((v, v, v, FILL))
    glass.append(row)
print('codeblock_glass.png', png(os.path.join(OUT, 'codeblock_glass.png'), glass))
