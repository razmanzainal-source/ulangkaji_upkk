#!/usr/bin/env python3
"""Ekstrak jadual jawapan Bahagian B daripada skim UPKK.

Jadual skim ialah jadual 2 lajur kecil (huruf ا ب ج د). OCR biasa mengelirukan
susunan baris, jadi skrip ini:

1. menjana banyak potongan imej (lazim, zoom,iwa>x atau Marriott) bagi
   setiap kertas;
2. membaca setiap potongan dengan Vision (bahasa Melayu — huruf Arab dibaca
   sebagai aksara Arab, bukan perkataan Inggeris);
3. mengasingkan pasangan "nombor + huruf" daripada setiap Bacaan;
4. mengundi — pasangan yang paling kerap muncul menang.

Skrip hanya membaca jadual skim. Ia tidak mengarang jawapan.
"""
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

AKAR = Path(__file__).resolve().parent.parent
OCR = "/tmp/ocr2.swift"
HURUF = "ابجد"

# Kertas → (muka surat skim, y0, y1) di mana jadual jawapan B berada.
KERTAS = {
    'sirah-2024': 13,
    'sirah-2025': 13,
    'jawi-2024': 13,
    'jawi-2025': 14,
    'ibadah-2025': 13,
}

# Huruf jawapan → indeks pilihan (0 = ا, 1 = ب, 2 = ج, 3 = د).
INDEKS = {h: i for i, h in enumerate(HURUF)}

CORAK_NOMBOR = r'[0-9٠-٩]'
CORAK_HURUF = f'[{HURUF}]'


def ocr(path: Path) -> str:
    try:
        out = subprocess.run(
            ['swift', str(OCR), str(path), 'ar-SA'],
            capture_output=True, text=True, timeout=180,
        )
        return out.stdout
    except Exception:  # noqa: BLE001
        return ''


def pasangan(teks: str) -> list[tuple[int, str]]:
    """Keluarkan pasangan (nombor, huruf) daripada satu baris OCR."""
    keluar = []
    # Normalkan digit Arab-Indic.
    teks = teks.translate(str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789'))
    i = 0
    while i < len(teks):
        if re.match(CORAK_NOMBOR, teks[i]):
            # Ambil nombor (1 atau 2 digit).
            m = re.match(r'\d{1,2}', teks[i:])
            if not m:
                i += 1
                continue
            nombor = int(m.group(0))
            j = i + len(m.group(0))
            # Skip ruang.
            while j < len(teks) and teks[j].isspace():
                j += 1
            if j < len(teks) and teks[j] in INDEKS:
                keluar.append((nombor, teks[j]))
                i = j + 1
                continue
            i += len(m.group(0))
        else:
            i += 1
    return keluar


def potongan(kertas: str, muka: int, x0f: float, y0f: float, y1f: float, zoom: float) -> Path:
    im = Image.open(AKAR / 'assets' / 'kertas' / kertas / f'muka{muka:02d}.jpg')
    w, h = im.size
    c = im.crop((int(w * x0f), int(h * y0f), w, int(h * y1f)))
    c = c.resize((int(c.width * zoom), int(c.height * zoom)), Image.LANCZOS)
    p = Path(f'/tmp/ocr/V_{kertas}_{x0f}_{y0f}_{y1f}_{zoom}.png')
    c.save(p)
    return p


def main() -> int:
    undian: dict[str, dict[int, Counter]] = defaultdict(lambda: defaultdict(Counter))
    # Julat y yang dicuba — skrip akan ambil julat yang menghasilkan jawapan
    # paling lengkap (bukan pertama sekali jumpa).
    julat = [(a, b) for a in (0.28, 0.34, 0.40, 0.46, 0.52, 0.58, 0.64)
             for b in (0.46, 0.52, 0.58, 0.64, 0.70, 0.76) if b - a >= 0.08]
    for kertas, muka in KERTAS.items():
        terbaik = None
        for y0, y1 in julat:
            calon = defaultdict(Counter)
            for x0f, zoom in ((0.35, 3.0), (0.35, 4.0), (0.30, 3.5), (0.42, 4.5)):
                p = potongan(kertas, muka, x0f, y0, y1, zoom)
                for baris in ocr(p).splitlines():
                    medan = baris.split('\t')
                    if len(medan) < 4:
                        continue
                    for nombor, huruf in pasangan(medan[3]):
                        if 1 <= nombor <= 10:
                            calon[nombor][huruf] += 1
                p.unlink(missing_ok=True)
            lengkap = sum(1 for n in range(1, 11) if calon.get(n))
            key = (lengkap, sum(sum(c.values()) for c in calon.values()))
            if terbaik is None or key > terbaik[0]:
                terbaik = (key, y0, y1, calon)
        _, y0, y1, calon = terbaik
        print(f'  (jadual ditemukan pada y={y0:.2f}-{y1:.2f})', file=sys.stderr)
        for nombor, huruf in sorted(calon.items()):
            for h, undi in huruf.items():
                undian[kertas][nombor][h] += undi
        for x0f, zoom in ((0.35, 3.0), (0.35, 4.0), (0.30, 3.5), (0.42, 4.5),
                          (0.35, 3.5), (0.30, 4.0), (0.40, 5.0), (0.28, 3.0)):
            p = potongan(kertas, muka, x0f, y0, y1, zoom)
            for baris in ocr(p).splitlines():
                medan = baris.split('\t')
                if len(medan) < 4:
                    continue
                for nombor, huruf in pasangan(medan[3]):
                    if 1 <= nombor <= 10:
                        undian[kertas][nombor][huruf] += 1
            p.unlink(missing_ok=True)
        continue
        for x0f, y0f, y1f, zoom in varian:
            p = potongan(kertas, muka, x0f, y0f, y1f, zoom)
            for baris in ocr(p).splitlines():
                medan = baris.split('\t')
                if len(medan) < 4:
                    continue
                for nombor, huruf in pasangan(medan[3]):
                    if 1 <= nombor <= 10:
                        undian[kertas][nombor][huruf] += 1
            p.unlink(missing_ok=True)

    hasil = {}
    for kertas in KERTAS:
        print('#' * 10, kertas)
        jawapan = {}
        for nombor in range(1, 11):
            pilihan = undian[kertas].get(nombor)
            if not pilihan:
                print(f'  B{nombor:2d} = ?   (tiada bacaan)')
                continue
            huruf, undi = pilihan.most_common(1)[0]
            jumlah = sum(pilihan.values())
            tanda = '' if undi >= 2 else '  ⚠ lemah'
            print(f'  B{nombor:2d} = {huruf}  (undi {undi}/{jumlah}){tanda}')
            jawapan[nombor] = huruf
        hasil[kertas] = jawapan
        print()
    out = Path('/tmp/ocr/jadual_b.json')
    out.write_text(json.dumps(hasil, ensure_ascii=False, indent=1), encoding='utf-8')
    print(f'-> {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
