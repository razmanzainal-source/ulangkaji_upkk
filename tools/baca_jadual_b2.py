#!/usr/bin/env python3
"""Baca huruf jawapan jadual B dengan mengasingkan nombor dan huruf.

OCR biasa gagal pada jadual 2 lajur yang kecil: Vision menggabungkan
"nombor + huruf" atau memecahkannya kepada baris berbeza, jadi susunan
baris tidak boleh dipercayai.

Skrip ini mengambil langkah berbeza:

1. Cari **kedudukan** setiap nombor (x, y) melalui OCR — nombor sahaja
   mudah dikesan kerana ia hanya satu aksara.
2. Potong **window kecil** tepat sebelah nombor itu (kiri atau kanan, pada
   baris yang sama) dan OCR window tersebut — isinya hanya satu huruf.

Langkah 2 offender "huruf" terus kepada nombornya, tanpa perlu meneka
susunan lajur.
"""
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

OCR = "/tmp/ocr2.swift"
AKAR = Path(__file__).resolve().parent.parent

# (kertas, muka, y0, y1) — kawasan jadual jawapan B pada muka skim.
KERTAS = {
    'sirah-2024': (13, 0.430, 0.580),
    'sirah-2025': (13, 0.535, 0.660),
    'jawi-2024': (13, 0.600, 0.730),
    'jawi-2025': (14, 0.630, 0.760),
    'ibadah-2025': (13, 0.490, 0.610),
}

HURUF = "ابجد"


def ocr(path: Path) -> list[tuple[float, float, str]]:
    """Kembalikan [(y, x, teks)] bagi setiap baris yang dikesan."""
    try:
        out = subprocess.run(
            ['swift', str(OCR), str(path), 'ar-SA'],
            capture_output=True, text=True, timeout=180,
        )
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


def imej(kertas: str, muka: int, x0: float, y0: float, x1: float, y1: float, zoom: float):
    im = Image.open(AKAR / 'assets' / 'kertas' / kertas / f'muka{muka:02d}.jpg')
    w, h = im.size
    c = im.crop((int(w * x0), int(h * y0), int(w * x1), int(h * y1)))
    c = c.resize((int(c.width * zoom), int(c.height * zoom)), Image.LANCZOS)
    return c


def kotak(kertas: str, muka: int, y0: float, y1: float, zoom: float,
          px0: float, py0: float, px1: float, py1: float) -> Path:
    """Potong kotak tertentu (koordinat relatif kawasan) dan jana klip."""
    c = imej(kertas, muka, 0, 0, 1, 1, zoom)
    W, H = c.size
    kotak_ = c.crop((int(px0 * W), int(py0 * H), int(px1 * W), int(py1 * H)))
    p = Path(f'/tmp/ocr/KOTAK_{kertas}_{int(py0*1000)}_{int(px0*1000)}.png')
    kotak_.save(p)
    return p


def cari_nombor(kertas: str, muka: int, y0: float, y1: float) -> dict[int, list[tuple[float, float]]]:
    """Cari kedudukan setiap nombor 1–10 dalam kawasan jadual."""
    kedudukan = defaultdict(list)
    for x0f in (0.10, 0.25, 0.40, 0.55, 0.70):
        for zoom in (3.0, 4.0, 5.0):
            c = imej(kertas, muka, x0f, y0, 1.0, y1, zoom)
            p = Path(f'/tmp/ocr/NUM_{kertas}_{x0f}_{zoom}.png')
            c.save(p)
            for (y, x, teks) in ocr(p):
                teks = teks.strip()
                # Observation yang mengandungi KECIL sahaja nombor.
                if re.fullmatch(r'[0-9٠-٩]{1,2}', teks):
                    n = int(teks.translate(str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')))
                    if 1 <= n <= 10:
                        # Koordinat relatif terhadap kawasan.
                        kedudukan[n].append(((y), (x0f + x * (1.0 - x0f))))
            p.unlink(missing_ok=True)
    return kedudukan


def main() -> int:
    for kertas, (muka, y0, y1) in KERTAS.items():
        print('#' * 12, kertas)
        kedudukan = cari_nombor(kertas, muka, y0, y1)
        for n in range(1, 11):
            pos = kedudukan.get(n)
            if not pos:
                print(f'  B{n:2d} = ? (nombor tidak dijumpai)')
                continue
            undian = Counter()
            for (y, x) in pos[:3]:
                for sisi in (-1, 1):
                    for lebar in (0.035, 0.055, 0.08):
                        px0 = max(0.0, x + sisi * 0.012)
                        px1 = min(1.0, x + sisi * lebar)
                        py0 = max(0.0, y - 0.022)
                        py1 = min(1.0, y + 0.022)
                        if px1 - px0 < 0.008:
                            continue
                        p = kotak(kertas, muka, y0, y1, 6.0, px0, py0, px1, py1)
                        for (_, _, teks) in ocr(p):
                            for ch in teks:
                                if ch in HURUF:
                                    undian[ch] += 1
                        p.unlink(missing_ok=True)
            if undian:
                huruf, n = undian.most_common(1)[0]
                print(f'  B{n if False else n} = {huruf}  (undi {undian[huruf]}/{sum(undian.values())}) '
                      f'{dict(undian)}')
            else:
                print(f'  B{n:2d} = ? (huruf tidak dijumpai)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
