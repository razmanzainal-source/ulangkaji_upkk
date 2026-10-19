#!/usr/bin/env python3
"""Lukis karya ikon "Ulangkaji UPKK" — maskot kanak-kanak perempuan bertudung.

Karya dilukis sepenuhnya dengan kod (PIL) supaya tiada fail luar diperlukan dan
warna sentiasa tepat dengan tema app:

    https://… → tiada. Semua bentuk dilukis di sini.

Gaya: ilustrasi rata (flat) comel untuk kanak-kanak sekolah rendah, dengan
garis luar tebal dan warna pink tema app.

Hasil: `tools/karya_ikon.png` (1024x1024) — sumber tunggal untuk ikon app
(`tools/jana_ikon.py`) dan lencana maskot (`tools/potong_maskot.py`).

Guna:
    python3 tools/lukis_karya.py [--keluar tools/karya_ikon.png] [--saiz 1024]
"""

from __future__ import annotations

import argparse
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --- Warna tema -------------------------------------------------------------

PINK_TUA = (173, 20, 87)        # #AD1457 — teks tajuk dan garis luar tebal
PINK = (236, 64, 122)           # #EC407A — tudung utama
PINK_MUDA = (244, 143, 177)     # #F48FB1 — tudung sorotan
PINK_SANGAT_MUDA = (255, 241, 246)  # #FFF1F6 — latar atas
PINK_LATAR = (255, 214, 231)    # #FFD6E7 — latar bawah
KULIT = (255, 224, 189)         # #FFE0BD
KULIT_GELAP = (240, 194, 150)   # bayang kulit
MATA = (62, 39, 35)             # #3E2723
MATA_SOROT = (255, 255, 255)
PIPI = (255, 138, 155)          # #FF8A9B
MULUT = (194, 24, 91)           # #C2185B
BUKU = (255, 249, 240)          # kertas buku
BUKU_TEPI = (216, 27, 96)
EMAS = (255, 202, 40)           # #FFCA40

FON_LATIN = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"


# --- Pembantu lukisan -------------------------------------------------------

def elips(d: ImageDraw.ImageDraw, x: float, y: float, rx: float, ry: float, **kw):
    d.ellipse([x - rx, y - ry, x + rx, y + ry], **kw)


def garis_elips(d: ImageDraw.ImageDraw, x, y, rx, ry, **kw):
    d.ellipse([x - rx, y - ry, x + rx, y + ry], **kw)


def lengkok(d: ImageDraw.ImageDraw, kotak, mula, akhir, **kw):
    d.arc(kotak, mula, akhir, **kw)


def gradien_menegak(saiz: int, atas, bawah) -> Image.Image:
    """Latar gradien menegak halus."""
    im = Image.new("RGB", (1, saiz))
    px = im.load()
    for y in range(saiz):
        t = y / max(1, saiz - 1)
        px[0, y] = tuple(int(atas[i] + (bawah[i] - atas[i]) * t) for i in range(3))
    return im.resize((saiz, saiz), Image.BILINEAR)


def bulat_kotak(saiz: int, jejari: int) -> Image.Image:
    """Topeng sudut bulat."""
    m = Image.new("L", (saiz, saiz), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, saiz - 1, saiz - 1],
                                        radius=jejari, fill=255)
    return m


def fon(saiz: int):
    try:
        return ImageFont.truetype(FON_LATIN, saiz)
    except OSError:
        return ImageFont.load_default()


def teks_tengah(d, teks, y, saiz, warna, jarak=0, lebar_maks=880, tengah=512):
    """Tulis teks berpusat pada x=512, dikecilkan supaya muat dalam kanvas."""
    f = fon(saiz)
    if jarak:
        lebar = sum(d.textlength(c, font=f) for c in teks) + jarak * (len(teks) - 1)
        if lebar > lebar_maks:
            nisbah = lebar_maks / lebar
            return teks_tengah(d, teks, y, max(8, int(saiz * nisbah)), warna,
                               jarak * nisbah, lebar_maks, tengah)
        x = tengah - lebar / 2
        for c in teks:
            d.text((x, y), c, font=f, fill=warna, anchor="la")
            x += d.textlength(c, font=f) + jarak
    else:
        d.text((tengah, y), teks, font=f, fill=warna, anchor="ma")


# --- Watak ------------------------------------------------------------------

def lukis_badan(d: ImageDraw.ImageDraw, S: float):
    """Badan, tudung yang menjuntai ke bahu, dan baju."""
    # Tudung menjuntai (di belakang muka).
    d.rounded_rectangle([352, 596, 672, 892], radius=140,
                        fill=PINK, outline=PINK_TUA, width=9)
    # Baju di bawah tudung.
    d.rounded_rectangle([372, 792, 652, 934], radius=86,
                        fill=PINK_MUDA, outline=PINK_TUA, width=9)


def lukis_kepala(d: ImageDraw.ImageDraw, S: float):
    """Kepala: tudung, muka, mata besar, pipi dan senyuman."""
    # Tudung.
    elips(d, 512, 548, 168, 182, fill=PINK, outline=PINK_TUA, width=10)
    elips(d, 420, 428, 62, 44, fill=PINK_MUDA)
    elips(d, 442, 452, 52, 36, fill=PINK)

    # Muka.
    elips(d, 512, 566, 112, 128, fill=KULIT, outline=PINK_TUA, width=8)
    elips(d, 512, 540, 108, 122, fill=KULIT)

    # Mata besar comel.
    for x in (470, 554):
        elips(d, x, 566, 30, 34, fill=MATA_SOROT, outline=PINK_TUA, width=7)
        elips(d, x, 568, 21, 24, fill=MATA)
        elips(d, x - 8, 558, 8, 9, fill=MATA_SOROT)
        elips(d, x + 7, 578, 4, 4, fill=MATA_SOROT)

    # Bulu mata.
    lengkok(d, [456, 528, 490, 556], 200, 340, fill=PINK_TUA, width=7)
    lengkok(d, [536, 528, 570, 556], 200, 340, fill=PINK_TUA, width=7)

    # Pipi.
    elips(d, 424, 616, 27, 17, fill=PIPI)
    elips(d, 600, 616, 27, 17, fill=PIPI)

    # Hidung kecil.
    lengkok(d, [500, 594, 524, 618], 20, 160, fill=KULIT_GELAP, width=5)

    # Mulut — senyuman manis.
    lengkok(d, [486, 612, 538, 656], 15, 165, fill=MULUT, width=8)
    lengkok(d, [490, 612, 534, 650], 20, 160, fill=PINK_TUA, width=3)

    # Kerongsang bunga pada tudung.
    bx, by = 622, 468
    for i in range(6):
        a = math.pi * 2 * i / 6
        elips(d, bx + math.cos(a) * 22, by + math.sin(a) * 22, 17, 17,
              fill=PINK_MUDA, outline=PINK_TUA, width=4)
    elips(d, bx, by, 15, 15, fill=EMAS, outline=PINK_TUA, width=4)


def lukis_buku(d: ImageDraw.ImageDraw, S: float):
    """Buku yang dipeluk di dada."""
    d.rounded_rectangle([376, 830, 648, 948], radius=22, fill=BUKU,
                        outline=PINK_TUA, width=9)
    d.rounded_rectangle([376, 830, 428, 948], radius=22, fill=BUKU_TEPI,
                        outline=PINK_TUA, width=9)
    for i in range(3):
        y = 862 + i * 28
        d.line([458, y, 610, y], fill=PINK_MUDA, width=9)
    # Tangan.
    elips(d, 428, 888, 40, 34, fill=KULIT, outline=PINK_TUA, width=8)
    elips(d, 596, 888, 40, 34, fill=KULIT, outline=PINK_TUA, width=8)


def lukis_hiasan(d: ImageDraw.ImageDraw, S: float):
    """Bulan, bintang dan awan hiasan."""
    # Bulan sabit.
    elips(d, 148, 470, 46, 46, fill=EMAS, outline=PINK_TUA, width=7)
    elips(d, 166, 458, 36, 36, fill=PINK_SANGAT_MUDA)
    # Bintang.
    for bx, by, r in ((866, 400, 36), (152, 700, 28), (872, 700, 30)):
        titik = []
        for i in range(10):
            a = -math.pi / 2 + math.pi * i / 5
            rr = r if i % 2 == 0 else r * 0.45
            titik.append((bx + math.cos(a) * rr, by + math.sin(a) * rr))
        d.polygon(titik, fill=EMAS, outline=PINK_TUA, width=6)
    # Awan comel.
    for cx, cy, r in ((800, 872, 40), (856, 890, 32), (748, 890, 30)):
        elips(d, cx, cy, r, r * 0.88, fill=(255, 255, 255),
              outline=PINK_TUA, width=6)


# Ruang reka bentuk karya ialah 1024 x 1024. Semua fungsi lukisan di atas
# menggunakan nombor dalam ruang itu, jadi `S` = 1.0. Nilai `S` dijadikan
# parameter supaya karya boleh dilukis pada saiz lain tanpa menukar nombor.
S = 1.0


def lukis(keluar: str, saiz: int, ganda: int = 2) -> None:
    """Lukis karya penuh dan simpan sebagai PNG."""
    N = saiz * ganda
    skala = N / 1024.0

    # Lapisan watak dan hiasan (lutsinar) dalam ruang 1024.
    lapis = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    dl = ImageDraw.Draw(lapis)

    # Lingkaran lembut di belakang maskot.
    dl.ellipse([116, 290, 908, 950], fill=(255, 255, 255, 255))
    dl.ellipse([116, 290, 908, 950], outline=PINK_MUDA, width=8)

    lukis_hiasan(dl, S)
    lukis_badan(dl, S)
    lukis_buku(dl, S)
    lukis_kepala(dl, S)

    # Latar gradien + lapisan watak.
    # Reka bentuk dikecilkan sedikit (SAFE) supaya sudut bulat ikon Android/iOS
    # tidak memotong teks tajuk di penjuru.
    im = gradien_menegak(N, PINK_SANGAT_MUDA, PINK_LATAR).convert("RGB")
    SAFE = 0.92
    sisi = int(N * SAFE)
    kecil = lapis.resize((sisi, sisi), Image.LANCZOS)
    im.paste(kecil, ((N - sisi) // 2, (N - sisi) // 2), kecil)

    # Tajuk.
    d = ImageDraw.Draw(im)
    teks_tengah(d, "ULANGKAJI", 92 * skala, int(62 * skala), PINK_TUA,
                jarak=5 * skala, lebar_maks=700 * skala, tengah=512 * skala)
    teks_tengah(d, "UPKK", 150 * skala, int(140 * skala), PINK, jarak=10 * skala,
                lebar_maks=700 * skala, tengah=512 * skala)
    teks_tengah(d, "KAFA  •  TAHUN 5", 300 * skala, int(42 * skala), PINK_TUA,
                jarak=4 * skala, lebar_maks=640 * skala, tengah=512 * skala)

    # Karya kekal segi empat penuh: `jana_ikon.py` menambah sudut bulat
    # mengikut keperluan setiap platform (iOS tiada sudut, Android ada).
    im = im.convert("RGB")
    im = im.resize((saiz, saiz), Image.LANCZOS)

    os.makedirs(os.path.dirname(os.path.abspath(keluar)), exist_ok=True)
    im.save(keluar)
    print(f"Karya disimpan: {keluar} ({saiz}x{saiz})")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--keluar", default=os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "tools", "karya_ikon.png"))
    p.add_argument("--saiz", type=int, default=1024)
    a = p.parse_args()
    lukis(a.keluar, a.saiz)
    return 0


if __name__ == "__main__":
    sys.exit(main())
