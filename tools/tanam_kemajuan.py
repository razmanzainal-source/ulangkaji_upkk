#!/usr/bin/env python3
"""Tanam data kemajuan dummy dalam emulator untuk semak visual lencana.

Skrip ini hanya untuk **pemeriksaan visual** — ia menulis fail
`FlutterSharedPreferences.xml` terus dalam storan aplikasi emulator, supaya
skrin Kemajuan boleh dilihat dengan lencana yang sudah diperoleh.

Ia hanya berfungsi pada build *debug* (build release tidak boleh
`run-as`). Guna `flutter run` atau `flutter build apk --debug` dahulu.

Usage:
    python3 tools/tanam_kemajuan.py [device]
"""
import json
import pathlib
import subprocess
import sys
from datetime import datetime, timedelta
from xml.sax.saxutils import escape

ADB = "/opt/homebrew/share/android-commandlinetools/platform-tools/adb"
PAKEJ = "com.razmanzainal.ulangkaji_upkk"
SP = "shared_prefs/FlutterSharedPreferences.xml"

# (id subjek, markah, penuh) — sengaja berbeza supaya setiap tahap lencana
# kelihatan ada padanya.
SUBJEK = [
    ("adab", 67, 70),
    ("akidah", 63, 70),
    ("arab", 56, 70),
    ("ibadah", 49, 70),
    ("jawi", 60, 70),
    ("sirah", 70, 70),
]

# Lencana global yang dipaparkan sebagai diperoleh.
LENCANA_GLOBAL = ["g-rajin", "g-kilat", "g-pujangga", "g-konsisten"]

TAHAP = [(70, "gangsa"), (80, "perak"), (90, "emas"), (95, "sempurna")]


def rekod(subjek, markah, penuh, hari: datetime) -> dict:
    return {
        "t": hari.isoformat(),
        "s": subjek,
        "k": f"{subjek}-2024",
        "j": f"UPKK {subjek.upper()} 2024",
        "m": markah,
        "p": penuh,
        "d": 2400,
        "b": {"A": markah // 4, "B": markah // 4, "C": markah // 4, "D": markah // 4},
        "l": False,
    }


def main() -> int:
    device = sys.argv[1] if len(sys.argv) > 1 else "emulator-5554"
    hari_ini = datetime.now()

    rekod_list = []
    for i, (subjek, markah, penuh) in enumerate(SUBJEK):
        # Rekod bertarikh berbeza supaya "hari berturut" ada beberapa hari.
        rekod_list.append(rekod(subjek, markah, penuh, hari_ini - timedelta(days=i)))

    lencana = set(LENCANA_GLOBAL)
    for subjek, markah, penuh in SUBJEK:
        peratus = round(markah / penuh * 100)
        for paras, tahap in TAHAP:
            if peratus >= paras:
                lencana.add(f"subjek-{subjek}-{tahap}")

    # Hanya **rentetan** dan senarai `<string>`/`<long>` yang ditulis di sini.
    #
    # `<long>`, bukan `<int>`: plugin Android menyimpan nilai `int` Dart
    # sebagai `Long`, jadi itulah format yang dibaca semula. Fail `<int>`
    # akan membuat codec plugin melontar ralat.
    #
    # Lencana tidak ditulis terus: app mengira sendiri lencana daripada
    # rekod yang ditanam (lihat `Kemajuan.muat`), jadi senarai `<set>` —
    # yang formatnya berbeza dan tidak boleh dibaca oleh plugin Android —
    # tidak diperlukan.
    baris = [
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>",
        "<map>",
        '    <string name="flutter.rekod_percubaan">%s</string>'
        % escape(json.dumps(rekod_list, ensure_ascii=False)),
        '    <long name="flutter.rentetan_terpanjang" value="24" />',
        '    <long name="flutter.jumlah_betul" value="1240" />',
        "</map>",
        "",
    ]
    kandungan = "\n".join(baris)

    # Tulis ke storan aplikasi melalui run-as (hanya build debug).
    #
    #_fail belum boleh_dipakai: quoting `adb shell` merosakkan ayat yang
    # panjang. Jadi failnya lebih dahulu dihantar ke /data/local/tmp, kemudian
    # disalin ke dalam storan aplikasi.
    #
    # Fail XML ditulis sebagai UTF-8 biasa — `adb push` tidak perlu escaping
    # tambahan.
    sementara = "/data/local/tmp/prefs_upkk.xml"
    tmp = pathlib.Path("/tmp/prefs_upkk.xml")
    tmp.write_text(kandungan, encoding="utf-8")

    langkah = [
        [ADB, "-s", device, "push", str(tmp), sementara],
        [ADB, "-s", device, "shell", "run-as", PAKEJ, "mkdir", "-p", "shared_prefs"],
        [ADB, "-s", device, "shell", "run-as", PAKEJ, "cp", sementara, SP],
        [ADB, "-s", device, "shell", "run-as", PAKEJ, "chmod", "644", SP],
        [ADB, "-s", device, "shell", "am", "force-stop", PAKEJ],
    ]
    for langkah_cmd in langkah:
        hasil = subprocess.run(langkah_cmd, capture_output=True, text=True)
        if hasil.returncode != 0:
            print("Gagal:", ' '.join(langkah_cmd[3:]), '->',
                  hasil.stderr.strip() or hasil.stdout.strip())
            print("Hanya berfungsi pada build debug — run-as ditolak oleh "
                  "build release.")
            return 1
    print(f"Data dummy ditanam: {len(rekod_list)} rekod, {len(lencana)} lencana.")
    print(f"Jalankan: {ADB} -s {device} shell am start -n {PAKEJ}/.MainActivity")
    return 0


if __name__ == "__main__":
    sys.exit(main())
