"""Extract the first icon group of a Windows .exe into a .ico file (stdlib only).

usage: python3 -I extract_icon.py <file.exe> <out.ico>
"""
import struct
import sys

RT_ICON, RT_GROUP_ICON = 3, 14


def resources(data):
    """{type: {name_or_id: bytes}} for the first language of each resource."""
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    assert data[pe:pe + 4] == b"PE\0\0", "not a PE file"
    nsec, opt_size = struct.unpack_from("<H", data, pe + 6)[0], struct.unpack_from("<H", data, pe + 20)[0]
    opt = pe + 24
    magic = struct.unpack_from("<H", data, opt)[0]
    dirs = opt + (112 if magic == 0x20B else 96)
    rsrc_rva = struct.unpack_from("<I", data, dirs + 2 * 8)[0]
    sec = opt + opt_size
    for i in range(nsec):
        vsize, va, rawsize, rawptr = struct.unpack_from("<IIII", data, sec + i * 40 + 8)
        if va <= rsrc_rva < va + max(vsize, rawsize):
            base, delta = rawptr + (rsrc_rva - va), va - rawptr
            break
    else:
        raise SystemExit("no resource section")

    def entries(off):
        named, ids = struct.unpack_from("<HH", data, base + off + 12)
        for k in range(named + ids):
            name, target = struct.unpack_from("<II", data, base + off + 16 + k * 8)
            yield name & 0x7FFFFFFF if not name & 0x80000000 else ("n", name), target

    out = {}
    for rtype, t1 in entries(0):
        for name, t2 in entries(t1 & 0x7FFFFFFF):
            _lang, leaf = next(entries(t2 & 0x7FFFFFFF))
            rva, size = struct.unpack_from("<II", data, base + leaf)
            out.setdefault(rtype, {})[name] = data[rva - delta:rva - delta + size]
    return out


def main(exe, ico):
    res = resources(open(exe, "rb").read())
    group = next(iter(res[RT_GROUP_ICON].values()))
    _, _, count = struct.unpack_from("<HHH", group, 0)
    entries, blobs = [], []
    for k in range(count):
        w, h, colors, _r, planes, bits, _size, icon_id = struct.unpack_from("<BBBBHHIH", group, 6 + k * 14)
        blob = res[RT_ICON][icon_id]
        entries.append((w, h, colors, planes, bits, len(blob)))
        blobs.append(blob)
    # keep only the largest image (0 means 256), so converters can't pick a small one
    best = max(range(count), key=lambda k: ((entries[k][0] or 256), entries[k][4]))
    entries, blobs, count = [entries[best]], [blobs[best]], 1
    offset = 6 + 16 * count
    with open(ico, "wb") as f:
        f.write(struct.pack("<HHH", 0, 1, count))
        for (w, h, colors, planes, bits, size) in entries:
            f.write(struct.pack("<BBBBHHII", w, h, colors, 0, planes, bits, size, offset))
            offset += size
        for blob in blobs:
            f.write(blob)
    print(f"{count} images -> {ico}")


if __name__ == "__main__":
    main(*sys.argv[1:3])
