#!/usr/bin/env python3
"""Jadikan maskot **Raz** daripada karya ikon app.

`tools/karya_ikon.png` ialah satu ilustrasi penuh 1024x1024: kanak-kanak
perempuan bertudung pink memeluk buku, bersama bulan, bintang, awan dan teks
"ULANGKAJI UPKK / KAFA • TAHUN 5".

Kenapa bukan potongan lutsinar? Latar karya ini pink muda dan tudung Raz juga
pink — memotong latar secara automatik akan bocor ke dalam tudung atau
meninggalkan sisa latar. Kerana itu maskot dijadikan **lencana bulat** (bulatan
+ gelang putih) — bersih, sengaja kelihatan seperti lencana, dan warnanya kekal
sama dengan tema app.

Bulatan lencana mesti **mengelak teks tajuk** di bahagian atas karya (teks itu
berada pada y ≈ 0.09–0.33) dan tidak memotong buku di bawah (y ≈ 0.90).

Hasil:
    assets/gambar/maskot_upkk.png        lencana badan penuh (dengan buku)
    assets/gambar/maskot_upkk_muka.png   lencana kepala, untuk saiz kecil

Guna:
    python3 tools/potong_maskot.py
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jana_ikon as J  # noqa: E402  (alat dalam folder yang sama)

GAMBAR = os.path.join(J.AKAR, "assets", "gambar")
KARYA = J.KARYA

# Saiz fail yang disimpan.
TINGGI_BADAN = 512
TINGGI_MUKA = 384

# Bulatan lencana, dalam nisbah 0-1 daripada karya 1024x1024:
#   (tengah x, tengah y, jejari)
# Badan: dari atas tudung hingga hujung buku. Bulatan ini bermula di bawah teks
# "KAFA • TAHUN 5" (y ≈ 0.33) dan berakhir di bawah buku (y ≈ 0.90), sambil
# mengambil bulan (kiri) dan awan (kanan) sebagai latar — ia sebahagian daripada
# karya dan tidak mengganggu.
BULATAN_BADAN = (0.500, 0.635, 0.278)
# Kepala: tudung, bunga, mata dan senyuman — cukup jelas pada 48px.
BULATAN_MUKA = (0.500, 0.520, 0.175)


def muat_karya() -> Image.Image:
    """Baca karya sumber seperti asal (tanpa potong bingkai)."""
    if not os.path.exists(KARYA):
        sys.exit(f"Gagal: {KARYA} tiada.")
    return Image.open(KARYA).convert("RGBA")


def lencana(karya: Image.Image, bulatan: tuple[float, float, float]) -> Image.Image:
    """Potong bahagian karya menjadi lencana bulat dengan gelang putih."""
    lebar, tinggi = karya.size
    cx, cy, r = bulatan
    jejari = int(lebar * r)
    # Gelang putih ikut saiz lencana supaya nisbahnya sama pada semua saiz.
    gelang = max(4, int(jejari * 0.035))
    sisi = 2 * (jejari + gelang)

    pusat = (int(lebar * cx), int(tinggi * cy))
    potongan = karya.crop(
        (pusat[0] - sisi // 2, pusat[1] - sisi // 2,
         pusat[0] + sisi // 2, pusat[1] + sisi // 2)
    )

    topeng = Image.new("L", (sisi, sisi), 0)
    lukis = ImageDraw.Draw(topeng)
    lukis.ellipse(
        [gelang, gelang, sisi - gelang - 1, sisi - gelang - 1], fill=255
    )
    topeng = topeng.filter(ImageFilter.GaussianBlur(1.3))

    keluar = Image.new("RGBA", (sisi, sisi), (0, 0, 0, 0))
    keluar.paste(potongan, (0, 0), topeng)

    # Gelang putih pejal di luar gambar (lencana gaya "avatar").
    cincin = Image.new("L", (sisi, sisi), 0)
    lukis = ImageDraw.Draw(cincin)
    lukis.ellipse([1, 1, sisi - 2, sisi - 2], fill=255)
    lukis.ellipse(
        [gelang + 1, gelang + 1, sisi - gelang - 2, sisi - gelang - 2], fill=0
    )
    cincin = cincin.filter(ImageFilter.GaussianBlur(0.7))
    keluar.paste(Image.new("RGBA", (sisi, sisi), (255, 255, 255, 255)), (0, 0), cincin)
    return keluar


def simpan(img: Image.Image, nama: str, tinggi: int) -> None:
    skala = tinggi / img.height
    kecil = img.resize((max(1, int(img.width * skala)), tinggi), Image.LANCZOS)
    os.makedirs(GAMBAR, exist_ok=True)
    laluan = os.path.join(GAMBAR, nama)
    kecil.save(laluan, "PNG", optimize=True)
    print(f"  {laluan} ({kecil.width}x{kecil.height})")


def pratonton(muka: Image.Image, badan: Image.Image) -> str:
    """Helaian semakan: lencana atas latar biru (kepala surat) dan putih (kad)."""
    S = 420
    helai = Image.new("RGB", (S * 2 + 60, S + 150), (245, 245, 248))
    d = ImageDraw.Draw(helai)

    def tampal(img: Image.Image, x: int, y: int, maks: int) -> None:
        skala = maks / max(img.width, img.height)
        kecil = img.resize(
            (max(1, int(img.width * skala)), max(1, int(img.height * skala))),
            Image.LANCZOS,
        )
        helai.paste(
            kecil,
            (x + (maks - kecil.width) // 2, y + (maks - kecil.height) // 2),
            kecil,
        )

    # biru (kepala surat app)
    d.rectangle([30, 30, 30 + S, 30 + S], fill=J.PINK_TEMA)
    tampal(badan, 30, 30, S - 80)
    # putih (kad)
    d.rectangle([S + 60, 30, S * 2 + 60, 30 + S], fill=(255, 255, 255))
    tampal(badan, S + 60, 30, S - 80)

    # saiz sebenar dalam app — atas latar putih dan biru
    for i, saiz in enumerate([48, 64, 84, 116]):
        x = 40 + i * 130
        d.rectangle([x, S + 60, x + saiz, S + 60 + saiz], fill=(255, 255, 255))
        tampal(muka, x, S + 60, saiz)
        x = S + 70 + i * 130
        d.rectangle([x, S + 60, x + saiz, S + 60 + saiz], fill=J.PINK_TEMA)
        tampal(muka, x, S + 60, saiz)

    laluan = os.path.join(J.SIMPANAN, "pratonton_maskot.png")
    os.makedirs(J.SIMPANAN, exist_ok=True)
    helai.save(laluan, "PNG", optimize=True)
    return laluan


def main() -> None:
    print("Membaca karya...")
    karya = muat_karya()

    print("Membina lencana maskot...")
    badan = lencana(karya, BULATAN_BADAN)
    muka = lencana(karya, BULATAN_MUKA)

    simpan(badan, "maskot_upkk.png", TINGGI_BADAN)
    simpan(muka, "maskot_upkk_muka.png", TINGGI_MUKA)
    print(f"Pratonton: {pratonton(muka, badan)}")


if __name__ == "__main__":
    main()
