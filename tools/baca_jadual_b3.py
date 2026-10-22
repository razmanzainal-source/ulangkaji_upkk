#!/usr/bin/env python3
"""Baca jadual jawapan B dengan mengasingkan dua lajurnya.

Jadual skim ialah 2 lajur: **kiri = nombor 1–5, kanan = nombor 6–10**.
OCR biasa gagal kerana ia menyusun semua baris mengikut Y, lalu lajur
kiri dan kanan bercampur.

Skrip ini:
1. mengimbas kawasan jadual dan mengambil kedudukan (x, y) setiap baris;
2. Mengcluster mengikut X kepada dua kumpulan (kiri / kanan) — jarak terbesar
   dalam histogram X menjadi pemisah;
3. mengurutkan setiap kumpulan mengikut Y (atas ke bawah) — jadi baris
   pertama = nombor 1 (kiri) atau 6 (kanan);
4. membaca pasangan nombor + huruf daripada setiap baris.

Dengan itu tiada peneka loudly: setiap nombor Statnya sudah diketahui
daripada kedudukan.
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image

OCR = "/tmp/ocr2.swift"
AKAR = Path(__file__).resolve().parent.parent
HURUF = "ابجد"

KERTAS = {
    'sirah-2024': (13, 0.420, 0.590),
    'sirah-2025': (13, 0.520, 0.670),
    'jawi-2024': (13, 0.590, 0.740),
    'jawi-2025': (14, 0.610, 0.770),
    'ibadah-2025': (13, 0.595, 0.790),
}


def ocr(path: Path):
    try:
        out = subprocess.run(['swift', str(OCR), str(path), 'ar-SA'],
                             capture_output=True, text=True, timeout=180)
    except Exception:  # noqa: BLE001
        return []
    hasil = []
    for baris in out.stdout.splitlines():
        medan = baris.split('\t')
        if len(medan) < 4:
            continue
        try:
            hasil.append((float(medan[0]), float(medan[1]), medan[3]))
        except ValueError:
            continue
    return hasil


def imej(kertas, muka, x0, y0, x1, y1, zoom):
    im = Image.open(AKAR / 'assets' / 'kertas' / kertas / f'muka{muka:02d}.jpg')
    w, h = im.size
    c = im.crop((int(w * x0), int(h * y0), int(w * x1), int(h * y1)))
    return c.resize((int(c.width * zoom), int(c.height * zoom)), Image.LANCZOS)


def pasangan(teks):
    """Keluarkan [(nombor, huruf)] daripada satu baris, mengikut turutan."""
    keluar = []
    teks = teks.translate(str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789'))
    i = 0
    while i < len(teks):
        if teks[i].isdigit():
            m = re.match(r'\d{1,2}', teks[i:])
            nombor = int(m.group(0))
            j = i + len(m.group(0))
            while j < len(teks) and teks[j].isspace():
                j += 1
            if j < len(teks) and teks[j] in HURUF:
                keluar.append((nombor, teks[j]))
                i = j + 1
                continue
            i += len(m.group(0))
        else:
            i += 1
    return keluar


def kelompok_x(baris, jurang_min=0.04):
    """Asingkan baris kepada dua kumpulan X (kiri / kanan)."""
    if len(baris) < 2:
        return [baris]
    xs = sorted(b[1] for b in baris)
    jurang, pos = 0.0, 0
    for i in range(1, len(xs)):
        if xs[i] - xs[i - 1] > jurang:
            jurang, pos = xs[i] - xs[i - 1], i
    if jurang < jurang_min:
        return [baris]
    kiri = [b for b in baris if b[1] < (xs[pos - 1] + xs[pos]) / 2]
    kanan = [b for b in baris if b[1] >= (xs[pos - 1] + xs[pos]) / 2]
    return [kiri, kanan]


def baca(kertas, muka, y0, y1):
    """Kembalikan {nombor: huruf} untuk satu kertas."""
    terkumpul = []
    for x0f in (0.10, 0.25, 0.40, 0.55, 0.70):
        for zoom in (3.0, 4.0, 5.0):
            c = imej(kertas, muka, x0f, y0, 1.0, y1, zoom)
            p = Path(f'/tmp/ocr/LJ_{kertas}_{x0f}_{zoom}.png')
            c.save(p)
            for (y, x, teks) in ocr(p):
                if not pasangan(teks):
                    continue
                terkumpul.append((y, x0f + x * (1.0 - x0f), teks))
            p.unlink(missing_ok=True)

    jawapan = {}
    for kumpulan in kelompok_x(terkumpul):
        if not kumpulan:
            continue
        # Susun mengikut Y (atas ke bawah).
        kumpulan = sorted(kumpulan, key=lambda b: -b[0])
        for (y, x, teks) in kumpulan:
            for (n, h) in pasangan(teks):
                jawapan.setdefault(n, h)
    return jawapan, terkumpul


def main() -> int:
    for kertas, (muka, y0, y1) in KERTAS.items():
        jawapan, semua = baca(kertas, muka, y0, y1)
        print('#' * 12, kertas, f'({len(semua)} baris dikesan)')
        for n in range(1, 11):
            print(f'  B{n:2d} = {jawapan.get(n, "?")}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
