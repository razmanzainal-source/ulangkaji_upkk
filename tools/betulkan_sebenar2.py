#!/usr/bin/env python3
"""Betulkan isu sistematik transkrip kertas sebenar.

Tiga pembetulan menyeluruh:

1. **Kunci Cyrillic.** Proses transkrip kadangkala menghasilkan huruf Cyrillic
   yang kelihatan seperti huruf Latin (`teкс`, `teкс`). Model membaca `teks`,
   jadi item itu kelihatan kosong dalam app. Semua kunci ditukar kepada bentuk
   Latin tulen.

2. **`arahan` → `soalan`.** Soalan Bahagian C/D transkrip menggunakan medan
   `arahan`/`arahanRumi`, sedangkan model membaca `soalan`/`rumi`. Akibatnya
   teks soalan kosong dalam app. Medan dipindahkan tanpa kehilangan data.

3. **`adab-2025-c2` → `tempat_kosong`.** Item menyimpan jawapan sebagai
   rentetan (`"jawapan": "تنترم"`), sedangkan model mahu indeks `int` ke dalam
   bank perkataan. Soalan ini "isi tempat kosong" — tepat untuk jenis
   `tempat_kosong`, dengan bank dibina daripada jawapan yang transkrip berikan.

Skrip ini **tidak** menulis jawapan baharu — ia hanya memindahkan data sedia
ada ke tempat yang model fahami.
"""

import json
import sys
from pathlib import Path

DASAR = Path('assets/content/sebenar')

# Huruf Cyrillic yang kelihatan seperti Latin → padanan Latin.
# Transkrip menjana `teкс` (teks dengan k/s Cyrillic) dan varian serupa.
CYRILLIC = {
    'а': 'a', 'в': 'b', 'е': 'e', 'ё': 'e', 'з': '3', 'и': 'n',
    'к': 'k', 'м': 'm', 'н': 'h', 'о': 'o', 'р': 'p', 'с': 'c',
    'т': 't', 'у': 'y', 'х': 'x', 'ѕ': 's', 'і': 'i', 'ї': 'i',
    'ј': 'j', 'ѕ': 's', 'ґ': 'g', 'ё': 'e', '№': '#',
    # Huruf Cyrillic khusus yang muncul dalam transkrip ini.
    'к': 'k', 'с': 'c', 'т': 't', 'о': 'o', 'р': 'p', 'а': 'a',
    'е': 'e', 'н': 'h', 'м': 'm', 'в': 'b', 'у': 'y', 'х': 'x',
    # Huruf Arab yang menyerupai huruf Latin — transkrip juga menghasilkan
    # kunci `teكس` (kaf + seen Arab). Semua kunci model mesti Latin tulen.
    'ك': 'k', 'س': 's', 'ا': 'a', 'ب': 'b', 'ت': 't', 'ه': 'h',
    'ن': 'n', 'م': 'm', 'ل': 'l', 'ي': 'y', 'و': 'w', 'ر': 'r',
    'ف': 'f', 'د': 'd', 'ص': 's', 'ق': 'q', 'ج': 'j', 'ح': 'h',
    'ع': 'a', 'ط': 't', 'ء': '', 'گ': 'g', 'ڤ': 'p', 'چ': 'c',
    'ڠ': 'ng', 'ڽ': 'ny', 'ک': 'k', 'ۏ': 'v', 'ڬ': 'g',
}


def betulkan_kunci(obj):
    """Tukar semua kunci Cyrillic kepada Latin, secara rekursif."""
    if isinstance(obj, dict):
        baharu = {}
        for kunci, nilai in obj.items():
            k = ''.join(CYRILLIC.get(ch, ch) for ch in kunci)
            baharu[k] = betulkan_kunci(nilai)
        return baharu
    if isinstance(obj, list):
        return [betulkan_kunci(e) for e in obj]
    return obj


def pindah_arahan(soalan):
    """Pindahkan `arahan`/`arahanRumi` kepada `soalan`/`rumi` jika perlu."""
    if not soalan.get('soalan') and soalan.get('arahan'):
        soalan['soalan'] = soalan['arahan']
        soalan['rumi'] = soalan.get('arahanRumi', '')
    # Buang medan lapuk supaya model tidak keliru.
    soalan.pop('arahan', None)
    soalan.pop('arahanRumi', None)


def tukar_tempat_kosong(soalan):
    """Item `jawapan` String → `tempat_kosong` dengan bank jawapan.

    Setiap item menyimpan ayat bertanda `____` dan jawapannya sebagai
    rentetan. Bank dibina daripada jawapan mengikut susunan ayat, dan setiap
    item diberi indeks jawapannya. Rumi bank diambil daripada `kataKunci`
    jika ada.
    """
    item = soalan.get('item', [])
    jawapan_str = [i for i in item
                   if isinstance(i, dict) and isinstance(i.get('jawapan'), str)]
    if not jawapan_str:
        return False

    # Susun jawapan mengikut susunan item asal, buang pendua.
    bank = []
    bank_rumi = []
    peta = {}  # jawapan text → index dalam bank
    for i in item:
        if not isinstance(i, dict):
            continue
        jw = i.get('jawapan')
        if isinstance(jw, str) and jw not in peta:
            peta[jw] = len(bank)
            bank.append(jw)
            # Cari Rumi daripada kataKunci jika ada.
            r = ''
            for k in soalan.get('kataKunci', []):
                if k.get('teks') == jw:
                    r = k.get('rumi', '')
                    break
            bank_rumi.append(r)

    # Beri setiap item indeks jawapannya.
    for i in item:
        if not isinstance(i, dict):
            continue
        jw = i.get('jawapan')
        if isinstance(jw, str):
            i['jawapan'] = peta[jw]

    soalan['jenis'] = 'tempat_kosong'
    soalan['bank'] = bank
    if any(bank_rumi):
        soalan['bankRumi'] = bank_rumi
    soalan.pop('kataKunci', None)
    return True


def betulkan(path):
    asal = path.read_text(encoding='utf-8')
    data = json.loads(asal)
    data = betulkan_kunci(data)
    berubah = []

    for bahagian in data.get('bahagian', []):
        for soalan in bahagian.get('soalan', []):
            asal_id = soalan.get('id', '?')

            pindah_arahan(soalan)

            # Item dengan jawapan String → tempat_kosong.
            if tukar_tempat_kosong(soalan):
                berubah.append(f'  {asal_id}: → tempat_kosong')

    teks = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if teks != asal:
        path.write_text(teks, encoding='utf-8')
    print(f'{path.name}: {len(berubah)} soalan ditukar')
    for b in berubah:
        print(b)


def main():
    for path in sorted(DASAR.glob('*.json')):
        betulkan(path)
    return 0


if __name__ == '__main__':
    sys.exit(main())
