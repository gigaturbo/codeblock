"""Write the three 16x16 tiles that lib/nodes.lua tints per colour.

    python scripts/gen_textures.py

Run it when the tiles need redrawing; the PNGs it writes are committed, and
nothing checks that they match this source. It is the editable source for
textures/codeblock_block.png, codeblock_glass.png and codeblock_lamp.png the
way the .svg files beside them are for the two tool icons.

No Pillow on this machine, so the PNGs are assembled from zlib + struct.

The node definitions apply `^[multiply:#rrggbb`, which scales RGB per pixel, so
what a tile draws survives the tint: a white pixel comes out as the palette hex
exactly and a darker one as a proportionally darker shade of it.
`^[colorize:#rrggbb:255` would have replaced every pixel with the flat colour
instead. Hence the glass and lamp tiles being near-white, and hence the block
tile being pure white and nothing else - a solid block is meant to read as a
flat fill of its colour, so there is nothing for it to draw.
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
# Opaque and pure white, so `^[multiply:#rrggbb` reproduces the palette hex
# exactly: a solid block is a flat fill of its colour and draws nothing of its
# own.
block = [[(255, 255, 255, 255)] * W for _ in range(H)]
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

# --- codeblock_lamp.png -------------------------------------------------------
# Opaque and near-white, with a faint darker grid so a wall of lamps reads as
# panels rather than as one lit surface. Lines every 8 px, which puts four
# panes on a node face and keeps the pattern continuous across tiles - a
# 16 px spacing would only outline each node, and anything finer reads as
# texture rather than as a grid. The contrast is deliberately low, the tint
# multiplying it: more here would show as dirt on a dark colour.
GROUND, LINE = 252, 234
lamp = []
for y in range(H):
    row = []
    for x in range(W):
        v = LINE if x % 8 == 0 or y % 8 == 0 else GROUND
        row.append((v, v, v, 255))
    lamp.append(row)
print('codeblock_lamp.png', png(os.path.join(OUT, 'codeblock_lamp.png'), lamp))
