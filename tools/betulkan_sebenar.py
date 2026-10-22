#!/usr/bin/env python3
"""Betulkan format JSON kertas sebenar supaya sepadan dengan model `Kertas`.

Model app hanya menerima beberapa bentuk soalan. Skrip ini menukar bentuk
transkrip yang tidak sepadan kepada bentuk tersebut:

| Bentuk transkrip | Bentuk model |
| --- | --- |
| `tanda` + `item[].jawapan: bool` | `betul_salah` + `item[].betul` |
| `tulis` + `item[].jawapan: bool` | `betul_salah` + `item[].betul` |
| `tulis` + `bilanganJawapan` | `senarai` + `jawapanContoh` |
| `padan` + 2 `pilihan` seragam | `kumpulan` + `kategori`/`kategoriRumi` |
| `objektif` + 2 `pilihan` setiap item | `bulat` |
| `objektif` + `pilihan` di aras soalan | 1 item dengan `pilihan` |
| `kumpulan` A/B + `jawapan` (peta) | `kumpulan` + `kategori`/`kategoriRumi` |

Skrip ini **tidak** menulis jawapan baharu — ia hanya memindahkan data yang
sudah ada ke tempat yang model fahami.
"""

import json
import sys
from pathlib import Path

DASAR = Path('assets/content/sebenar')

# Kunci yang sah pada aras soalan (mengikut model `SoalanKertas`).
KUNCI_SOALAN = {
    'id', 'jenis', 'soalan', 'rumi', 'markah', 'item', 'arahan', 'arahanRumi',
    'bank', 'bankRumi', 'pasangan', 'urutan', 'urutanRumi', 'idea',
    'jawapanContoh', 'jawapanContohRumi', 'bilanganJawapan',
    'kategori', 'kategoriRumi', 'bahasa',
}


def lapis(soalan, nama, nilai):
    """Tulis nilai pada aras soalan dan buang kunci lapuk yang sama."""
    soalan[nama] = nilai


def tukar_tanda(soalan):
    """`tanda` dengan `jawapan: true/false` → `betul_salah` dengan `betul`."""
    soalan['jenis'] = 'betul_salah'
    for i in soalan.get('item', []):
        if isinstance(i, dict) and isinstance(i.get('jawapan'), bool):
            i['betul'] = i.pop('jawapan')


def tukar_betul_salah_dari_tulis(soalan):
    """`tulis` yang item-nya `jawapan: bool` → `betul_salah`."""
    item = soalan.get('item', [])
    if not item:
        return False
    for i in item:
        if not isinstance(i, dict) or not isinstance(i.get('jawapan'), bool):
            return False
    soalan['jenis'] = 'betul_salah'
    for i in item:
        i['betul'] = i.pop('jawapan')
    return True


def tukar_tulis_senarai(soalan):
    """`tulis` yang ada `bilanganJawapan` → `senarai` dengan `jawapanContoh`."""
    if not soalan.get('bilanganJawapan'):
        return False
    contoh = soalan.get('jawapanContoh')
    if isinstance(contoh, str):
        soalan['jawapanContoh'] = [contoh]
    if not soalan.get('jawapanContoh'):
        return False
    soalan['jenis'] = 'senarai'
    return True


def tukar_padan_kumpulan(soalan):
    """`padan` dengan 2 pilihan seragam → `kumpulan` dengan 2 kategori."""
    item = soalan.get('item', [])
    if not item:
        return False
    for i in item:
        if not isinstance(i, dict):
            return False
        p = i.get('pilihan')
        if not isinstance(p, list) or len(p) != 2:
            return False
        if not isinstance(i.get('jawapan'), int):
            return False
    pertama = item[0]['pilihan']
    for i in item:
        if [x.get('teks') for x in i['pilihan']] != [
            x.get('teks') for x in pertama
        ]:
            return False

    soalan['jenis'] = 'kumpulan'
    soalan['kategori'] = [p.get('teks', '') for p in pertama]
    soalan['kategoriRumi'] = [p.get('rumi', '') for p in pertama]
    for i in item:
        i.pop('pilihan', None)
    return True


def tukar_objektif_dua_pilihan(soalan):
    """`objektif` yang setiap itemnya 2 pilihan → `bulat`."""
    item = soalan.get('item', [])
    if not item:
        return False
    for i in item:
        if not isinstance(i, dict):
            return False
        p = i.get('pilihan')
        if not isinstance(p, list) or len(p) != 2:
            return False
    soalan['jenis'] = 'bulat'
    return True


def tukar_objektif_pilihan_di_aras_soalan(soalan):
    """`objektif` dengan `pilihan` di aras soalan → 1 item dalam `item`.

    Kertas UPKK Bahagian B lazimnya satu soalan dengan 4 pilihan. Transkrip
    meletakkan `pilihan` pada aras soalan dan `item` pada aras soalan juga.
    Model mahu `item` berisi satu entri dengan `pilihan` di dalamnya.
    """
    if 'pilihan' not in soalan:
        return False
    pilihan = soalan.pop('pilihan')
    jawapan = soalan.pop('jawapan', 0)
    item_teks = soalan.pop('item', [])
    item_rumi = soalan.pop('itemRumi', [])

    # `item` asal mungkin senarai perkataan (bukan soalan) — ia dipaparkan
    # sebagai teks soalan di atas pilihan.
    teks_soalan = soalan.get('soalan', '')
    rumi_soalan = soalan.get('rumi', '')
    if isinstance(item_teks, list) and item_teks and isinstance(item_teks[0], str):
        if item_teks and not all(isinstance(x, str) for x in item_teks):
            return False
        if not teks_soalan:
            teks_soalan = '\n'.join(item_teks)
        if not rumi_soalan and item_rumi:
            rumi_soalan = '\n'.join(item_rumi)
        soalan['soalan'] = teks_soalan
        soalan['rumi'] = rumi_soalan

    soalan['item'] = [{
        'teks': '',
        'rumi': '',
        'pilihan': pilihan,
        'jawapan': jawapan,
    }]
    return True


def tukar_kumpulan_ab(soalan):
    """`kumpulan` A/B dengan peta `jawapan` → `kumpulan` dengan 2 kategori.

    Bentuk asal: senarai butir berkumpulan (A) diikuti senarai jawapan (B),
    dengan peta `jawapan` yang memetakan indeks butir → teks jawapan.

    Bentuk model: `kategori` = senarai jawapan (B), dan setiap `item[].jawapan`
    = indeks jawapan yang betul.
    """
    jawapan_peta = soalan.get('jawapan')
    if not isinstance(jawapan_peta, dict):
        return False
    item = soalan.get('item', [])
    if not item:
        return False

    # Kumpul semua teks jawapan yang muncul, ikut susunan kemunculan.
    kategori = []
    kategori_rumi = []
    for nilai in jawapan_peta.values():
        if isinstance(nilai, dict):
            if nilai.get('teks') not in kategori:
                kategori.append(nilai.get('teks', ''))
                kategori_rumi.append(nilai.get('rumi', ''))
        elif isinstance(nilai, str) and nilai not in kategori:
            kategori.append(nilai)
            kategori_rumi.append('')
    if not kategori:
        return False

    soalan['kategori'] = kategori
    soalan['kategoriRumi'] = kategori_rumi
    soalan.pop('jawapan', None)

    # Setiap butir perlu nilai jawapan dalam bentuk indeks.
    for i, butir in enumerate(item):
        if not isinstance(butir, dict):
            return False
        if 'jawapan' in butir and isinstance(butir['jawapan'], int):
            continue
        # Cari jawapan bagi butir ini daripada peta asal.
        for kunci, nilai in jawapan_peta.items():
            if not isinstance(kunci, str):
                continue
            try:
                indeks = int(kunci)
            except ValueError:
                continue
            if indeks != i:
                continue
            if isinstance(nilai, dict):
                butir['jawapan'] = kategori.index(nilai.get('teks', ''))
            elif isinstance(nilai, str):
                butir['jawapan'] = kategori.index(nilai)
            break
        else:
            return False

    soalan['jenis'] = 'kumpulan'
    return True


def bersih(soalan):
    """Buang kunci lapuk yang tidak difahami model."""
    for kunci in list(soalan.keys()):
        if kunci not in KUNCI_SOALAN:
            soalan.pop(kunci)


def betulkan(path):
    data = json.loads(path.read_text(encoding='utf-8'))
    berubah = []
    asal_teks = path.read_text(encoding='utf-8')

    for bahagian in data.get('bahagian', []):
        for soalan in bahagian.get('soalan', []):
            jenis = soalan.get('jenis', 'tulis')
            asal = jenis

            if jenis == 'tanda':
                tukar_tanda(soalan)
            elif jenis in ('tulis', 'huraian'):
                if not tukar_betul_salah_dari_tulis(soalan):
                    tukar_tulis_senarai(soalan)
            elif jenis == 'padan':
                if not tukar_padan_kumpulan(soalan):
                    tukar_kumpulan_ab(soalan)
            elif jenis == 'objektif':
                if not tukar_objektif_dua_pilihan(soalan):
                    tukar_objektif_pilihan_di_aras_soalan(soalan)
            elif jenis == 'kumpulan':
                if 'kategori' not in soalan:
                    tukar_kumpulan_ab(soalan)

            # Soalan dengan `item[].jawapan` sebagai senarai indeks (dua jawapan
            # diterima) tidak sepadan dengan model — model hanya menerima satu
            # indeks bagi setiap item.
            for i in soalan.get('item', []):
                if isinstance(i, dict) and isinstance(i.get('jawapan'), list):
                    i.pop('jawapan')

            bersih(soalan)

            if soalan.get('jenis', 'tulis') != asal:
                berubah.append(
                    f"  {soalan['id']}: {asal} → {soalan.get('jenis')}"
                )

    # Tulis fail hanya jika kandungan benar-benar berubah — `jenis` mungkin
    # sama tetapi bentuk data sudah dibetulkan.
    teks_baru = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if teks_baru != asal_teks:
        path.write_text(teks_baru, encoding='utf-8')
    print(f"{path.name}: {len(berubah)} soalan ditukar")
    for b in berubah:
        print(b)


def main():
    for path in sorted(DASAR.glob('*.json')):
        betulkan(path)
    return 0


if __name__ == '__main__':
    sys.exit(main())
