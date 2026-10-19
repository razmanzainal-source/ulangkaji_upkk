#!/usr/bin/env python3
"""Jana ikon app "Ulangkaji UPKK" daripada karya ikon.

Sumber: `tools/karya_ikon.png` — karya 1024x1024 (seorang kanak-kanak
perempuan comel bertudung pink, memeluk buku, dengan teks "ULANGKAJI UPKK").

Karya ini sudah pink — sama keluarga warna dengan tema app (#D81B60) — jadi
tiada geseran warna dibuat. Skrip ini:

  1. memangkas bingkai luar karya supaya kad mengisi seluruh kanvas;
  2. menjana semua saiz ikon Android (termasuk lapisan adaptif), iOS dan web,
     serta helaian pratonton.

Guna:
    python3 tools/jana_ikon.py

Hasil ditulis terus ke projek:
  android/app/src/main/res/mipmap-*/ic_launcher.png             (ikon legasi)
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  (lapisan depan adaptif)
  android/app/src/main/res/mipmap-*/ic_launcher_background.png  (lapisan belakang adaptif)
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml    (XML ikon adaptif)
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
  web/favicon.png, web/icons/*.png
"""

from __future__ import annotations

import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIMPANAN = os.path.join(AKAR, "build", "ikon")
KARYA = os.path.join(AKAR, "tools", "karya_ikon.png")
RES = os.path.join(AKAR, "android", "app", "src", "main", "res")
IOS = os.path.join(AKAR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
WEB = os.path.join(AKAR, "web")

# Warna tema app (seedColor 0xFFD81B60) — untuk label pratonton dan nada lembut.
PINK_TEMA = (216, 27, 96)
SAIZ_INDUK = 1024

# --- Pemangkasan karya -------------------------------------------------------
# Karya sumber bergambar kad bersudut bulat di atas latar biru muda. 6.5%
# daripada setiap sisi dibuang: bingkai luar dan sudut kad hilang, manakala isi
# karya (teks, Raz, tiang, jam) masih jauh dari tepi.
PANGKAS = 0.030


def muat_karya() -> Image.Image:
    """Baca karya sumber dan buang bingkai luarnya."""
    if not os.path.exists(KARYA):
        sys.exit(f"Gagal: {KARYA} tiada.")
    asal = Image.open(KARYA).convert("RGB")
    potong = int(asal.width * PANGKAS)
    karya = asal.crop((potong, potong, asal.width - potong, asal.height - potong))
    karya = karya.resize((SAIZ_INDUK, SAIZ_INDUK), Image.LANCZOS)
    print(f"Karya sumber: {asal.width}x{asal.height} -> dipangkas {PANGKAS:.1%}")
    return karya


def latar_kabur(karya: Image.Image, tebal: int = 56) -> Image.Image:
    """Lapisan belakang ikon adaptif: warna tepi karya diregangkan ke seluruh kanvas.

    Karya yang tajam diletak di tengah, jadi hanya bahagian tepi lapisan ini
    yang kelihatan. Jalur tepi karya (atas, bawah, kiri, kanan) diregangkan dan
    dipuratakan, jadi warnanya bersambung dengan karya tanpa jejak kabur yang
    kotor di tengah.
    """
    lebar, tinggi = karya.size
    jalur = [
        karya.crop((0, 0, lebar, tebal)).resize((lebar, tinggi), Image.BICUBIC),
        karya.crop((0, tinggi - tebal, lebar, tinggi)).resize((lebar, tinggi), Image.BICUBIC),
        karya.crop((0, 0, tebal, tinggi)).resize((lebar, tinggi), Image.BICUBIC),
        karya.crop((lebar - tebal, 0, lebar, tinggi)).resize((lebar, tinggi), Image.BICUBIC),
    ]
    atas = ImageChops.add(jalur[0], jalur[1], scale=2.0)
    bawah = ImageChops.add(jalur[2], jalur[3], scale=2.0)
    tapak = ImageChops.add(atas, bawah, scale=2.0)
    tapak = tapak.filter(ImageFilter.GaussianBlur(SAIZ_INDUK * 0.03))
    # Sedikit digelapkan supaya karya tajam di tengah menonjol.
    nada = Image.new("RGB", (SAIZ_INDUK, SAIZ_INDUK), (250, 232, 241))
    return ImageChops.multiply(tapak, nada)


def bulatkan(img: Image.Image, jejari_nisbah: float = 0.225) -> Image.Image:
    """Beri sudut bulat pada imej (gaya ikon Android legasi)."""
    saiz = img.width
    topeng = Image.new("L", (saiz, saiz), 0)
    ImageDraw.Draw(topeng).rounded_rectangle(
        [0, 0, saiz - 1, saiz - 1], radius=int(saiz * jejari_nisbah), fill=255
    )
    keluar = img.copy()
    keluar.putalpha(topeng)
    return keluar


def _bayang(kanvas: Image.Image, alfa: Image.Image, jarak_y: int,
            kabur: float, kelegapan: float) -> Image.Image:
    """Bayang lembut di bawah sesuatu bentuk, untuk rasa kedalaman."""
    lapis = Image.new("L", kanvas.size, 0)
    lapis.paste(alfa, (0, jarak_y))
    lapis = lapis.filter(ImageFilter.GaussianBlur(kabur))
    lapis = lapis.point(lambda v: int(v * kelegapan))
    gelap = Image.new("RGBA", kanvas.size, (80, 10, 45, 255))
    return Image.composite(gelap, kanvas, lapis)


def letak_karya(kanvas: Image.Image, karya: Image.Image, nisbah: float,
                bulat: bool = True, jejari: float = 0.225,
                bayang: bool = True) -> Image.Image:
    """Letak karya bersaiz `nisbah` daripada lebar kanvas, di tengah-tengah."""
    saiz = kanvas.width
    sisi = int(saiz * nisbah)
    kecil = karya.resize((sisi, sisi), Image.LANCZOS)
    if bulat:
        kecil = bulatkan(kecil, jejari)

    x = (saiz - sisi) // 2
    y = (saiz - sisi) // 2

    if bayang:
        alfa = Image.new("L", kanvas.size, 0)
        alfa.paste(kecil.getchannel("A"), (x, y))
        kanvas = _bayang(kanvas, alfa, int(saiz * 0.012), saiz * 0.022, 0.42)

    kanvas = kanvas.copy()
    kanvas.paste(kecil, (x, y), kecil)
    return kanvas


def simpan(img: Image.Image, laluan: str, saiz: int) -> None:
    os.makedirs(os.path.dirname(laluan), exist_ok=True)
    kecil = img.resize((saiz, saiz), Image.LANCZOS) if img.width != saiz else img
    kecil.save(laluan, "PNG", optimize=True)


# ---------------------------------------------------------------- ikon induk
def bina_induk() -> dict[str, Image.Image]:
    karya = muat_karya()
    belakang = latar_kabur(karya)

    # Zon selamat ikon adaptif Android = 66dp daripada 108dp (61% kanvas),
    # jadi karya dalam lapisan depan mesti dikecilkan ke dalam zon itu.
    depan = letak_karya(Image.new("RGBA", (SAIZ_INDUK, SAIZ_INDUK), (0, 0, 0, 0)),
                        karya, 0.62)

    # Ikon "maskable" web: zon selamat 80%, latar penuh (tanpa sudut bulat).
    petak = letak_karya(belakang.convert("RGBA"), karya, 0.84)

    dpr = {
        # iOS: penuh segi empat, TANPA sudut bulat (iOS memasukkannya sendiri)
        "ios": karya,
        # Android legasi: sudut bulat
        "legasi": bulatkan(karya),
        # Lapisan depan adaptif: lutsinar, karya dalam zon selamat
        "depan": depan,
        # Lapisan belakang adaptif: karya dikaburkan, penuh segi empat
        "belakang": belakang,
        # Ikon "maskable" web: latar penuh, karya dalam zon selamat
        "petak": petak,
    }
    return dpr


# ------------------------------------------------------------------ Android
def pasang_android(dpr: dict[str, Image.Image]) -> int:
    # ic_launcher: mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192
    # adaptif (108dp): mdpi 108, hdpi 162, xhdpi 216, xxhdpi 324, xxxhdpi 432
    peta = {
        "mdpi": (48, 108),
        "hdpi": (72, 162),
        "xhdpi": (96, 216),
        "xxhdpi": (144, 324),
        "xxxhdpi": (192, 432),
    }
    bil = 0
    for ketumpatan, (saiz_legasi, saiz_adaptif) in peta.items():
        folder = os.path.join(RES, f"mipmap-{ketumpatan}")
        simpan(dpr["legasi"], os.path.join(folder, "ic_launcher.png"), saiz_legasi)
        simpan(dpr["depan"], os.path.join(folder, "ic_launcher_foreground.png"), saiz_adaptif)
        simpan(dpr["belakang"], os.path.join(folder, "ic_launcher_background.png"), saiz_adaptif)
        bil += 3

    folder_xml = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(folder_xml, exist_ok=True)
    with open(os.path.join(folder_xml, "ic_launcher.xml"), "w") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<!-- Ikon adaptif: lapisan belakang lembut + maskot kanak-kanak bertudung di depan. -->\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '</adaptive-icon>\n'
        )
    return bil + 1


# --------------------------------------------------------------------- iOS
def pasang_ios(dpr: dict[str, Image.Image]) -> int:
    laluan_json = os.path.join(IOS, "Contents.json")
    with open(laluan_json) as f:
        data = json.load(f)

    bil = 0
    for imej in data["images"]:
        nama = imej.get("filename")
        if not nama:
            continue
        saiz_pt = float(imej["size"].split("x")[0])
        skala = int(imej["scale"].rstrip("x"))
        piksel = int(round(saiz_pt * skala))
        simpan(dpr["ios"], os.path.join(IOS, nama), piksel)
        bil += 1
    return bil


# --------------------------------------------------------------------- Web
def pasang_web(dpr: dict[str, Image.Image]) -> int:
    bil = 0
    for nama, saiz in [("favicon.png", 32), ("icons/Icon-192.png", 192),
                       ("icons/Icon-512.png", 512)]:
        simpan(dpr["legasi"], os.path.join(WEB, nama), saiz)
        bil += 1
    for nama, saiz in [("icons/Icon-maskable-192.png", 192),
                       ("icons/Icon-maskable-512.png", 512)]:
        simpan(dpr["petak"], os.path.join(WEB, nama), saiz)
        bil += 1
    return bil


def _topeng_bulat(img: Image.Image) -> Image.Image:
    saiz = img.width
    topeng = Image.new("L", (saiz, saiz), 0)
    ImageDraw.Draw(topeng).ellipse([0, 0, saiz - 1, saiz - 1], fill=255)
    keluar = img.copy()
    keluar.putalpha(Image.composite(keluar.getchannel("A"), Image.new("L", (saiz, saiz), 0), topeng))
    return keluar


def adaptif(dpr: dict[str, Image.Image]) -> Image.Image:
    """Rupa ikon adaptif Android: latar lembut + karya, sebelum ditopeng pelancar."""
    belakang = dpr["belakang"].copy().convert("RGBA")
    belakang.alpha_composite(dpr["depan"])
    return belakang


def pratonton(dpr: dict[str, Image.Image]) -> str:
    """Helaian pratonton: rupa sebenar ikon pada iOS dan Android 8+."""
    W, H = 1168, 700
    helai = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    d = ImageDraw.Draw(helai)

    font = None
    for laluan in ["/System/Library/Fonts/Supplemental/Arial.ttf",
                   "/System/Library/Fonts/Helvetica.ttc"]:
        if os.path.exists(laluan):
            try:
                font = ImageFont.truetype(laluan, 22)
                break
            except Exception:
                pass

    def label(teks: str, x: int, y: int) -> None:
        d.text((x, y), teks, fill=(70, 70, 70, 255), font=font)

    # 1. Rupa iOS (dibulatkan oleh sistem, ~22.5% jejari)
    ios = bulatkan(dpr["ios"].resize((360, 360), Image.LANCZOS))
    helai.paste(ios, (48, 70), ios)
    if font:
        label("iOS", 48, 446)
        label("(segulung sistem)", 48, 474)

    # 2. Android 8+: bulatan
    adp = adaptif(dpr)
    bulat = _topeng_bulat(adp.resize((300, 300), Image.LANCZOS))
    helai.paste(bulat, (480, 100), bulat)

    # 3. Android 8+: segi empat bulat
    segi = bulatkan(adp.resize((300, 300), Image.LANCZOS), 0.20)
    helai.paste(segi, (820, 100), segi)

    if font:
        label("Android 8+", 480, 446)
        label("(bulatan)", 480, 474)
        label("Android 8+", 820, 446)
        label("(segulung)", 820, 474)

    # 4. Saiz kecil pada telefon
    x = 48
    for saiz in [48, 72, 96, 144]:
        kecil = _topeng_bulat(adp.resize((saiz, saiz), Image.LANCZOS))
        helai.paste(kecil, (x, 540), kecil)
        x += saiz + 16

    return helai


def main() -> None:
    dpr = bina_induk()

    os.makedirs(SIMPANAN, exist_ok=True)
    for nama, img in dpr.items():
        img.save(os.path.join(SIMPANAN, f"ikon_{nama}_1024.png"), "PNG", optimize=True)

    a = pasang_android(dpr)
    i = pasang_ios(dpr)
    w = pasang_web(dpr)

    helai = pratonton(dpr)
    laluan_pratonton = os.path.join(SIMPANAN, "pratonton_ikon.png")
    helai.convert("RGB").save(laluan_pratonton, "PNG", optimize=True)

    print(f"Android : {a} fail")
    print(f"iOS     : {i} fail")
    print(f"Web     : {w} fail")
    print(f"Pratonton: {laluan_pratonton}")


if __name__ == "__main__":
    main()
