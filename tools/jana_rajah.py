#!/usr/bin/env python3
"""Jana rajah soalan bergambar Sejarah Tahun 5 (lukisan sendiri).

Hanya soalan jenis `gambar` yang memerlukan rajah dilukis di sini; semua
soalan lain memakai emoji. Semua bentuk dilukis daripada bentuk asas
(garisan, bulatan, polygon) — tiada gambar buku teks atau gambar yang
diambil dari Internet, jadi tiada isu hak cipta.

Guna:
    python3 tools/jana_rajah.py            # jana semua rajah
    python3 tools/jana_rajah.py jata       # jana satu rajah sahaja

Hasil ditulis ke assets/gambar/ dan pratonton ke build/rajah/.
"""

from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIMPAN = os.path.join(AKAR, "assets", "gambar")
PRATONTON = os.path.join(AKAR, "build", "rajah")

FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_TEBAL = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

PUTIH = (255, 255, 255)
DAWAI = (38, 50, 56)
LEMBUT = (144, 164, 174)
BIRU = (21, 101, 192)
BIRU_MUDA = (227, 242, 253)
MERAH = (198, 40, 40)
KUNING = (249, 168, 37)
HIJAU = (46, 125, 50)
COKLAT = (93, 64, 55)


def kanvas(lebar, tinggi):
    im = Image.new("RGB", (lebar, tinggi), PUTIH)
    return im, ImageDraw.Draw(im)


def teks(d, x, y, s, saiz=26, warna=DAWAI, anchor="mm", tebal=False):
    f = ImageFont.truetype(FONT_TEBAL if tebal else FONT, saiz)
    d.text((x, y), s, font=f, fill=warna, anchor=anchor)


def tajuk(d, tengah, s, saiz=28):
    teks(d, tengah, 34, s, saiz=saiz, tebal=True)


def kotak(d, x0, y0, x1, y1, isi=BIRU_MUDA, garis=BIRU, lebar=4, bulat=14):
    d.rounded_rectangle([x0, y0, x1, y1], radius=bulat, fill=isi, outline=garis, width=lebar)


def anak_panah(d, x1, y1, x2, y2, warna=BIRU, lebar=5, saiz=14):
    garisan(d, [(x1, y1), (x2, y2)], warna, lebar)
    sudut = math.atan2(y2 - y1, x2 - x1)
    for a in (sudut + 2.6, sudut - 2.6):
        garisan(
            d,
            [(x2, y2), (x2 + saiz * math.cos(a), y2 + saiz * math.sin(a))],
            warna,
            lebar,
        )


def garisan(d, titik, warna=DAWAI, lebar=4, joint=None):
    """Garisan dengan koordinat dibulatkan — PIL mahu integer bila lebar > 1."""
    d.line(
        [(int(x), int(y)) for x, y in titik],
        fill=warna,
        width=int(round(lebar)),
        joint=joint,
    )


def bendera_kecil(d, x, y, lebar=72, tinggi=36):
    """Bendera ringkas: jalur merah-putih dengan kantong biru."""
    jalur = tinggi / 6
    for i in range(6):
        warna = MERAH if i % 2 == 0 else PUTIH
        d.rectangle([x, y + i * jalur, x + lebar, y + (i + 1) * jalur], fill=warna, outline=None)
    d.rectangle([x, y, x + lebar * 0.5, y + tinggi * 0.5], fill=BIRU)
    d.rectangle([x, y, x + lebar, y + tinggi], outline=DAWAI, width=2)


# ------------------------------------------------------------------ rajah 1
def carta_institusi_raja():
    """Carta susunan pemerintahan kerajaan Melayu dahulu (unit 6.1)."""
    im, d = kanvas(760, 470)
    tajuk(d, 380, "Susunan Pemerintahan Kerajaan Melayu Dahulu")

    tengah = 380
    kotak(d, tengah - 130, 80, tengah + 130, 148)
    teks(d, tengah, 114, "RAJA", saiz=30, tebal=True, warna=BIRU)

    kotak(d, tengah - 150, 208, tengah + 150, 276)
    teks(d, tengah, 242, "PEMBESAR", saiz=28, tebal=True, warna=BIRU)

    kotak(d, tengah - 160, 336, tengah + 160, 404)
    teks(d, tengah, 370, "RAKYAT", saiz=28, tebal=True, warna=BIRU)

    anak_panah(d, tengah, 148, tengah, 208)
    anak_panah(d, tengah, 276, tengah, 336)

    teks(d, tengah + 96, 178, "memerintah", saiz=20, warna=LEMBUT, anchor="lm")
    teks(d, tengah + 96, 306, "mentadbir", saiz=20, warna=LEMBUT, anchor="lm")
    teks(d, tengah - 96, 178, "dipatuhi", saiz=20, warna=LEMBUT, anchor="rm")
    teks(d, tengah - 96, 306, "taat setia", saiz=20, warna=LEMBUT, anchor="rm")

    teks(d, 380, 440, "Raja dibantu pembesar dalam pentadbiran negeri.",
         saiz=20, warna=LEMBUT)
    return im


# ------------------------------------------------------------------ rajah 2
def garis_masa_kuasa_asing():
    """Garis masa kedatangan kuasa asing (unit 7.1)."""
    im, d = kanvas(760, 470)
    tajuk(d, 380, "Kedatangan Kuasa Asing ke Negara Kita")

    y = 250
    d.line([(60, y), (700, y)], fill=BIRU, width=6)
    anak_panah(d, 690, y, 715, y, warna=BIRU)

    tanda = [
        (150, "1511", "Portugis\nmenawan\nMelaka"),
        (325, "1641", "Belanda\nmenawan\nMelaka"),
        (500, "1786", "British di\nPulau\nPinang"),
        (665, "1941", "Jepun\nmenduduki\nnegara kita"),
    ]
    for x, tahun, nama in tanda:
        d.ellipse([x - 15, y - 15, x + 15, y + 15], fill=KUNING, outline=DAWAI, width=3)
        teks(d, x, y - 50, tahun, saiz=26, tebal=True, warna=BIRU)
        anak_panah(d, x, y - 30, x, y - 14, warna=LEMBUT, lebar=3, saiz=9)
        for i, baris in enumerate(nama.split("\n")):
            teks(d, x, y + 48 + i * 30, baris, saiz=21)

    teks(d, 380, 430, "Setiap kuasa asing datang untuk menguasai perdagangan dan hasil bumi.",
         saiz=19, warna=LEMBUT)
    return im


# ------------------------------------------------------------------ rajah 3
def garis_masa_1957():
    """Garis masa usaha ke arah kemerdekaan (unit 7.3)."""
    im, d = kanvas(760, 480)
    tajuk(d, 380, "Usaha ke Arah Kemerdekaan")

    y = 265
    d.line([(50, y), (710, y)], fill=BIRU, width=6)
    anak_panah(d, 700, y, 725, y, warna=BIRU)

    tanda = [
        (105, "1946", "Penubuhan\nUMNO", True),
        (255, "1948", "Persekutuan\nTanah Melayu", False),
        (405, "1955", "Pilihan raya\npertama", True),
        (555, "1956", "Rombongan\nke London", False),
        (690, "1957", "Kemerdekaan\n31 Ogos", True),
    ]
    for x, tahun, nama, atas in tanda:
        utama = tahun == "1957"
        warna = MERAH if utama else KUNING
        d.ellipse([x - 14, y - 14, x + 14, y + 14], fill=warna, outline=DAWAI, width=3)
        if atas:
            teks(d, x, y - 52, tahun, saiz=25, tebal=True, warna=BIRU)
            baris_nama = nama.split("\n")
            for i, baris in enumerate(baris_nama):
                teks(d, x, y - 88 - (len(baris_nama) - 1 - i) * 27, baris,
                     saiz=20, warna=DAWAI)
        else:
            teks(d, x, y + 44, tahun, saiz=25, tebal=True, warna=BIRU)
            for i, baris in enumerate(nama.split("\n")):
                teks(d, x, y + 78 + i * 27, baris, saiz=20, warna=DAWAI)

    bendera_kecil(d, 654, 196, lebar=72, tinggi=36)
    return im


# ------------------------------------------------------------------ rajah 4
def bilah_keris(d, x, y0, y1, lebar=13, gelombang=6, warna=DAWAI, lebar_garis=9):
    """Bilah keris berombak: satu garisan tebal melalui titik berselang-seli."""
    tinggi = y1 - y0
    titik = []
    for i in range(gelombang + 1):
        arah = 1 if i % 2 == 0 else -1
        titik.append((x + arah * lebar / 2, y0 + i * tinggi / gelombang))
    garisan(d, titik, warna, lebar_garis, joint="curve")
    # hujung tajam
    hujung = titik[-1]
    d.polygon([(hujung[0] - lebar / 2, hujung[1] - 6), (hujung[0] + lebar / 2, hujung[1] - 6),
               (x, hujung[1] + 16)], fill=warna)


def alat_kebesaran_agong():
    """Empat alat kebesaran Yang di-Pertuan Agong (unit 8.1).

    Dilukis tanpa label nama — soalan app meminta murid mengenal pasti alat
    berdasarkan pengajian mereka, bukan berdasarkan tulisan dalam rajah.
    """
    im, d = kanvas(760, 520)
    tajuk(d, 380, "Pakaian dan Alat Kebesaran Diraja")

    kiri_x = [(60, 350), (410, 700)]
    baris_y = [(80, 330), (350, 480)]

    for x0, x1 in kiri_x:
        for y0, y1 in baris_y:
            kotak(d, x0, y0, x1, y1, isi=PUTIH, garis=LEMBUT, lebar=3, bulat=10)

    # (1) Keris Panjang Diraja — hulu di atas, bilah berombak ke bawah.
    x = 205
    d.ellipse([x - 13, 96, x + 13, 122], fill=KUNING, outline=DAWAI, width=2)  # kepala hulu
    d.line([(x, 118), (x, 140)], fill=COKLAT, width=11)                        # hulu
    garisan(d, [(x - 22, 138), (x + 22, 138)], KUNING, 9)  # sengkang
    bilah_keris(d, x, 150, 300, lebar=13, gelombang=6)
    teks(d, 205, 358, "(1)", saiz=26, tebal=True, warna=BIRU)

    # (2) Cokmar — tongkat panjang dengan kepala bulat.
    x = 555
    d.line([(x, 130), (x, 300)], fill=COKLAT, width=11)
    d.ellipse([x - 32, 82, x + 32, 146], fill=KUNING, outline=DAWAI, width=3)
    d.ellipse([x - 18, 96, x + 18, 132], outline=DAWAI, width=2)
    teks(d, 555, 358, "(2)", saiz=26, tebal=True, warna=BIRU)

    # (3) Tengkolok Diraja — kain dilipat di atas kepala.
    x = 205
    d.polygon([(x, 372), (x - 46, 456), (x + 46, 456)], fill=KUNING, outline=DAWAI, width=3)
    d.line([(x - 30, 456), (x - 6, 396)], fill=COKLAT, width=3)
    d.line([(x + 30, 456), (x + 6, 396)], fill=COKLAT, width=3)
    d.line([(x - 54, 452), (x + 54, 452)], fill=DAWAI, width=6)
    d.ellipse([x - 9, 366, x + 9, 384], fill=KUNING, outline=DAWAI, width=2)
    teks(d, 205, 492, "(3)", saiz=26, tebal=True, warna=BIRU)

    # (4) Pending Diraja — gesper pinggang.
    x = 555
    d.rounded_rectangle([x - 62, 380, x + 62, 448], radius=16,
                        fill=KUNING, outline=DAWAI, width=3)
    d.rounded_rectangle([x - 34, 396, x + 34, 432], radius=10,
                        outline=DAWAI, width=3)
    d.line([(x - 62, 414), (x - 96, 414)], fill=COKLAT, width=14)
    d.line([(x + 62, 414), (x + 96, 414)], fill=COKLAT, width=14)
    teks(d, 555, 492, "(4)", saiz=26, tebal=True, warna=BIRU)
    return im


# ------------------------------------------------------------------ rajah 5
def harimau(d, x, y, sisi, saiz=1.0):
    """Harimau ringkas (pandangan sisi) yang memegang perisai.

    `x, y` ialah tengah badan; `sisi` = -1 (kiri perisai) atau 1 (kanan).
    """
    badan_l = 120 * saiz
    badan_t = 62 * saiz
    d.ellipse([x - badan_l / 2, y - badan_t / 2, x + badan_l / 2, y + badan_t / 2],
              fill=KUNING, outline=DAWAI, width=3)
    # jalur badan
    for i in range(3):
        bx = x - sisi * (10 + i * 26) * saiz
        d.line([(bx - 12 * saiz, y - 18 * saiz), (bx + 12 * saiz, y + 18 * saiz)],
               fill=DAWAI, width=3)
    # kaki
    for kaki in (-26, 4, 30):
        kx = x + kaki * saiz
        garisan(d, [(kx, y + badan_t / 2 - 6), (kx, y + badan_t / 2 + 32 * saiz)],
                KUNING, 13 * saiz)
        d.ellipse([kx - 8 * saiz, y + badan_t / 2 + 26 * saiz,
                   kx + 8 * saiz, y + badan_t / 2 + 40 * saiz],
                  fill=KUNING, outline=DAWAI, width=2)
    # ekor melengkung ke belakang
    ekor_x = x - sisi * badan_l / 2
    garisan(d, [(ekor_x, y - 4), (ekor_x - sisi * 34 * saiz, y - 44 * saiz),
                (ekor_x - sisi * 16 * saiz, y - 66 * saiz)],
            DAWAI, 6, joint="curve")
    # kepala
    kx = x + sisi * (badan_l / 2 + 8 * saiz)
    d.ellipse([kx - 30 * saiz, y - 60 * saiz, kx + 30 * saiz, y],
              fill=KUNING, outline=DAWAI, width=3)
    # telinga
    d.polygon([(kx - 24 * saiz, y - 54 * saiz), (kx - 12 * saiz, y - 74 * saiz),
               (kx - 2 * saiz, y - 52 * saiz)], fill=KUNING, outline=DAWAI)
    d.polygon([(kx + 12 * saiz, y - 54 * saiz), (kx + 24 * saiz, y - 72 * saiz),
               (kx + 30 * saiz, y - 52 * saiz)], fill=KUNING, outline=DAWAI)
    # mata dan muncung
    d.ellipse([kx + sisi * 8 * saiz - 6 * saiz, y - 44 * saiz,
               kx + sisi * 8 * saiz + 6 * saiz, y - 32 * saiz], fill=DAWAI)
    d.ellipse([kx + sisi * 30 * saiz - 12 * saiz, y - 24 * saiz,
               kx + sisi * 30 * saiz + 12 * saiz, y - 6 * saiz],
              fill=PUTIH, outline=DAWAI, width=2)


def kenyalang(d, x, y):
    """Burung kenyalang (enggang) ringkas — lambang negeri Sarawak."""
    # badan
    d.ellipse([x - 30, y - 26, x + 26, y + 30], fill=(121, 85, 61), outline=DAWAI, width=3)
    # sayap
    d.ellipse([x - 30, y - 6, x + 6, y + 24], fill=(93, 64, 55), outline=DAWAI, width=2)
    # kepala dan paruh melengkung ke bawah
    d.ellipse([x + 2, y - 44, x + 34, y - 12], fill=(121, 85, 61), outline=DAWAI, width=3)
    d.polygon([(x + 28, y - 40), (x + 62, y - 30), (x + 60, y - 6), (x + 30, y - 18)],
              fill=KUNING, outline=DAWAI)
    d.polygon([(x + 24, y - 46), (x + 46, y - 44), (x + 30, y - 30)],
              fill=(141, 110, 99), outline=DAWAI)  # ketul di atas paruh
    d.ellipse([x + 18, y - 34, x + 26, y - 26], fill=DAWAI)
    # ekor panjang ke bawah
    d.polygon([(x - 18, y + 22), (x - 46, y + 74), (x - 22, y + 64), (x - 6, y + 34)],
              fill=(121, 85, 61), outline=DAWAI)


def jata_negara():
    """Perisai Jata Negara dengan lambang utama (unit 9.1)."""
    im, d = kanvas(760, 680)
    tajuk(d, 380, "Perisai Jata Negara")

    # --- perisai: sisi lurus, bawah tirus ke satu titik di tengah
    kiri, kanan = 230, 530
    atas, bawah = 175, 525
    d.polygon([(kiri, atas), (kanan, atas), (kanan, atas + 200),
               (380, bawah), (kiri, atas + 200)],
              fill=(255, 253, 231), outline=DAWAI, width=4)

    # --- jalur atas: lima bilah keris
    d.rectangle([kiri + 2, atas + 2, kanan - 2, atas + 56], fill=MERAH)
    for i in range(5):
        x = kiri + 36 + i * ((kanan - kiri - 72) / 4)
        garisan(d, [(x, atas + 12), (x - 5, atas + 16), (x, atas + 20)], KUNING, 6)
        bilah_keris(d, x, atas + 20, atas + 48, lebar=7, gelombang=2,
                    warna=KUNING, lebar_garis=5)

    # --- kiri: pokok pinang dengan Jambatan Pulau Pinang
    px, py = 312, 250
    garisan(d, [(px, py + 26), (px, py + 108)], COKLAT, 7)
    for sudut in range(0, 360, 40):
        a = math.radians(sudut)
        garisan(d, [(px, py + 26),
                    (px + 36 * math.cos(a), py + 2 + 28 * math.sin(a))], HIJAU, 4)
    # jambatan: dek, dua menara dan kabel penggantung di atas dek
    garisan(d, [(px - 68, py + 118), (px + 68, py + 118)], DAWAI, 5)
    garisan(d, [(px - 44, py + 78), (px - 44, py + 118)], DAWAI, 4)
    garisan(d, [(px + 44, py + 78), (px + 44, py + 118)], DAWAI, 4)
    garisan(d, [(px - 44, py + 78), (px - 18, py + 92), (px, py + 94),
                (px + 18, py + 92), (px + 44, py + 78)], DAWAI, 4, joint="curve")
    garisan(d, [(px - 18, py + 92), (px - 18, py + 118)], DAWAI, 2)
    garisan(d, [(px + 18, py + 92), (px + 18, py + 118)], DAWAI, 2)

    # --- kanan: pokok melaka
    mx, my = 455, 250
    garisan(d, [(mx, my + 20), (mx, my + 118)], COKLAT, 8)
    garisan(d, [(mx, my + 62), (mx - 28, my + 32)], COKLAT, 5)
    garisan(d, [(mx, my + 76), (mx + 28, my + 44)], COKLAT, 5)
    d.ellipse([mx - 48, my - 38, mx + 48, my + 40], fill=HIJAU, outline=DAWAI, width=2)

    # --- bawah kiri: burung kenyalang (Sarawak)
    kenyalang(d, 322, 430)

    # --- bawah kanan: bunga raya
    fx, fy = 452, 428
    for i in range(5):
        a = math.radians(i * 72 - 90)
        d.ellipse([fx + 30 * math.cos(a) - 18, fy + 30 * math.sin(a) - 18,
                   fx + 30 * math.cos(a) + 18, fy + 30 * math.sin(a) + 18],
                  fill=MERAH, outline=DAWAI, width=2)
    d.ellipse([fx - 9, fy - 9, fx + 9, fy + 9], fill=KUNING, outline=DAWAI, width=2)

    # --- bulan sabit dan bintang 14 bucu di atas perisai
    cx, cy, r = 342, 100, 34
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=KUNING, outline=DAWAI, width=2)
    d.ellipse([cx - r + 22, cy - r + 5, cx + r + 22, cy + r + 5], fill=PUTIH)
    bintang_x, bintang_y = cx + 76, cy
    d.polygon(
        [
            (
                bintang_x + (32 if i % 2 == 0 else 14) * math.cos(math.radians(i * 180 / 14 - 90)),
                bintang_y + (32 if i % 2 == 0 else 14) * math.sin(math.radians(i * 180 / 14 - 90)),
            )
            for i in range(28)
        ],
        fill=KUNING,
        outline=DAWAI,
    )

    # --- dua harimau di kiri dan kanan perisai
    harimau(d, 158, 320, -1, saiz=0.85)
    harimau(d, 602, 320, 1, saiz=0.85)

    # --- cogan kata
    d.rounded_rectangle([180, 575, 580, 630], radius=10, fill=BIRU_MUDA, outline=BIRU, width=3)
    teks(d, 380, 603, "Bersekutu Bertambah Mutu", saiz=28, tebal=True, warna=BIRU)
    return im


# ------------------------------------------------------------------ rajah 6
def jalur_gemilang():
    """Bendera Jalur Gemilang (unit 9.2)."""
    im, d = kanvas(760, 420)
    kiri, atas = 60, 70
    lebar, tinggi = 640, 320
    jalur = tinggi / 14
    for i in range(14):
        warna = MERAH if i % 2 == 0 else PUTIH
        d.rectangle([kiri, atas + i * jalur, kiri + lebar, atas + (i + 1) * jalur], fill=warna)
    # kantong biru: separuh lebar, separuh tinggi
    d.rectangle([kiri, atas, kiri + lebar / 2, atas + tinggi / 2], fill=BIRU)

    cx, cy = kiri + lebar / 4, atas + tinggi / 4
    r = 46
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=KUNING)
    d.ellipse([cx - r + 26, cy - r + 4, cx + r + 26, cy + r + 4], fill=BIRU)
    bx = cx + 62
    d.polygon(
        [
            (
                bx + (40 if i % 2 == 0 else 17) * math.cos(math.radians(i * 180 / 14 - 90)),
                cy + (40 if i % 2 == 0 else 17) * math.sin(math.radians(i * 180 / 14 - 90)),
            )
            for i in range(28)
        ],
        fill=KUNING,
    )
    d.rectangle([kiri, atas, kiri + lebar, atas + tinggi], outline=DAWAI, width=4)
    return im


# ------------------------------------------------------------------ rajah 7
def bunga_raya():
    """Bunga raya — lima kelopak merah (unit 9.5)."""
    im, d = kanvas(760, 520)
    cx, cy = 380, 250
    d.line([(cx, 300), (cx, 470)], fill=HIJAU, width=12)
    for sisi in (-1, 1):
        d.polygon([(cx, 400), (cx + sisi * 120, 350), (cx + sisi * 40, 440)],
                  fill=HIJAU, outline=(27, 94, 32), width=3)
    for i in range(5):
        a = math.radians(i * 72 - 90)
        px, py = cx + 92 * math.cos(a), cy + 92 * math.sin(a)
        d.ellipse([px - 66, py - 56, px + 66, py + 56], fill=MERAH, outline=(136, 14, 79), width=3)
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(211, 47, 47))
    garisan(d, [(cx, cy), (cx + 34, cy - 134)], (136, 14, 79), 12)
    d.ellipse([cx + 34 - 16, cy - 134 - 16, cx + 34 + 16, cy - 134 + 16],
              fill=KUNING, outline=(136, 14, 79), width=2)
    teks(d, 380, 495, "Lima kelopak · warna merah", saiz=20, warna=LEMBUT)
    return im


RAJAH = {
    "carta_institusi_raja": carta_institusi_raja,
    "garis_masa_kuasa_asing": garis_masa_kuasa_asing,
    "garis_masa_1957": garis_masa_1957,
    "alat_kebesaran_agong": alat_kebesaran_agong,
    "jata_negara": jata_negara,
    "jalur_gemilang": jalur_gemilang,
    "bunga_raya": bunga_raya,
}


def main():
    os.makedirs(SIMPAN, exist_ok=True)
    os.makedirs(PRATONTON, exist_ok=True)

    dipilih = sys.argv[1:] or list(RAJAH)
    for nama in dipilih:
        if nama not in RAJAH:
            print(f"Nama rajah tidak dikenali: {nama}")
            print("Pilihan:", ", ".join(RAJAH))
            return 1
        im = RAJAH[nama]()
        laluan = os.path.join(SIMPAN, nama + ".png")
        im.save(laluan)
        print(f"{nama}.png  {im.size[0]}×{im.size[1]}  {os.path.getsize(laluan) / 1024:.0f} KB")

    # Helaian pratonton: semua rajah bersebelahan untuk semakan visual.
    if len(dipilih) > 1:
        helai = Image.new("RGB", (800, 380 * len(dipilih)), PUTIH)
        y = 0
        for nama in dipilih:
            helai.paste(RAJAH[nama](), (20, y))
            y += 380
        helai.save(os.path.join(PRATONTON, "pratonton_rajah.png"))
        print("Pratonton:", os.path.relpath(os.path.join(PRATONTON, "pratonton_rajah.png"), AKAR))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
