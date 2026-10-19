#!/usr/bin/env python3
"""Periksa sebutan klip rakaman app secara akustik (tanpa perlu mendengar).

Masalah yang diperiksa: suara TTS kadangkala menyebut huruf "c" Bahasa Melayu
seperti /k/ — "cuba" menjadi "kuba". Untuk bunyi:
  * letupan /k/ (kuba)     — pendek, terus masuk vokal   => ZCR rendah
  * geseran /tʃ/ (chuba)   — geseran frekuensi tinggi    => ZCR tinggi

Skrip ini mengukur Kadar Lintasan Sifar (ZCR) 150 ms pertama klip rakaman app
(daripada `manifest.json`), jadi tiada audio dijana semula dan tiada rangkaian
digunakan.

Penilaian dibuat pada **nilai mutlak**, bukan dengan membandingkan klip
kawalan: klip pujian ("Betul! Syabas.", "Syabas! Kamu...") yang dahulunya
menjadi rujukan letupan /b/ dan geseran /s/ sudah dibuang daripada app.
Menggantungkan keputusan pada klip yang tidak lagi dijana hanya menghasilkan
alat yang gagal tanpa sebab.

Keputusan: klip "Cuba lagi." (f-salah) mesti menyerupai geseran (/tʃ/, ZCR
tinggi), bukan letupan /k/ — barulah 'c' disebut dengan betul.

Penggunaan:
    python3 tools/periksa_sebutan.py
"""

from __future__ import annotations

import json
import os
import struct
import subprocess
import sys
import tempfile

SR = 22050
AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(AKAR, "assets", "bunyi", "suara", "manifest.json")

# (kunci manifest, teks, jenis onset jangkaan)
UJIAN = [
    ("f-salah", "Cuba lagi. (c)", "geseran /tʃ/"),
    ("f-bagus", "Bagus! (b)", "letupan /b/"),
    ("f-ulang", "Jangan putus asa... (j)", "letupan /dʒ/"),
]

# Ambang: 0.15 memisahkan letupan (rendah) daripada geseran (tinggi) pada
# ukuran bingkai 10 ms yang digunakan di sini.
AMBANG = 0.15


def baca_wav(laluan: str) -> list[float]:
    """Baca WAV (termasuk WAVE_FORMAT_EXTENSIBLE) sebagai sampel -1..1."""
    data = open(laluan, "rb").read()
    if data[:4] != b"RIFF":
        raise SystemExit("bukan fail RIFF")
    pos = 12
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        saiz = struct.unpack("<I", data[pos + 4:pos + 8])[0]
        if cid == b"data":
            isi = data[pos + 8:pos + 8 + saiz]
            return [v[0] / 32768.0 for v in struct.iter_unpack("<h", isi)]
        pos += 8 + saiz + (saiz % 2)
    raise SystemExit("tiada chunk data")


def profil_zcr(sampel: list[float]) -> dict:
    """ZCR bingkai 10 ms; bingkai senyap di hujung dibuang (seperti app)."""
    saiz = int(SR * 0.010)
    bingkai = []
    for i in range(0, len(sampel) - saiz, saiz):
        b = sampel[i:i + saiz]
        lintas = sum(1 for a, c in zip(b, b[1:]) if (a >= 0) != (c >= 0))
        bingkai.append(lintas / (len(b) - 1))
    bingkai = [b for b in bingkai if b > 0.001]
    if not bingkai:
        return {"purata": 0.0, "maks": 0.0, "bingkai_geseran": 0}
    awal = bingkai[:15]  # 150 ms pertama
    return {
        "purata": sum(awal) / len(awal),
        "maks": max(awal),
        "bingkai_geseran": sum(1 for b in awal if b > AMBANG),
    }


def main() -> int:
    if not os.path.exists(MANIFEST):
        print("Manifest rakaman tidak dijumpai:", MANIFEST)
        return 1
    fail = json.load(open(MANIFEST, encoding="utf-8"))["fail"]

    hasil: dict[str, dict] = {}
    with tempfile.TemporaryDirectory() as td:
        print(f"{'kunci':9s} {'teks':30s} {'onsep':14s} {'ZCR awal':>9s} {'geseran':>8s}")
        print("-" * 76)
        for kunci, teks, onsep in UJIAN:
            nama = fail.get(kunci)
            if not nama:
                print(f"{kunci:9s} {teks:30s} -- tiada dalam manifest")
                continue
            wav = os.path.join(td, kunci + ".wav")
            subprocess.run(
                ["afconvert", "-f", "WAVE", "-d", f"LEI16@{SR}", "-c", "1",
                 os.path.join(AKAR, "assets", "bunyi", "suara", nama), wav],
                check=True, capture_output=True,
            )
            profil = profil_zcr(baca_wav(wav))
            hasil[kunci] = profil
            print(
                f"{kunci:9s} {teks:30s} {onsep:14s} "
                f"{profil['purata']:9.3f} {profil['bingkai_geseran']:8d}"
            )

    cuba = hasil.get("f-salah")
    if not cuba:
        print("\nKlip 'f-salah' tiada — tidak dapat membuat keputusan.")
        return 1

    print()
    print(f"  'Cuba lagi.' (c) : ZCR awal {cuba['purata']:.3f}, "
          f"{cuba['bingkai_geseran']} bingkai geseran")
    if cuba["purata"] >= AMBANG:
        print(f"\n  LULUS: ZCR melebihi ambang {AMBANG:.2f} — 'cuba' disebut "
              "dengan geseran /tʃ/ (chuba).")
        return 0
    print(f"\n  GAGAL: ZCR di bawah ambang {AMBANG:.2f} — 'cuba' menyerupai "
          "letupan /k/ (kuba); perlu jana semula klip.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
