#!/usr/bin/env python3
"""Betulkan struktur transkrip kertas sebenar (laluan kedua).

Isu yang ditangani di sini:

1. **Soalan pilihan tanpa `jenis`.** Item yang semuanya membawa `pilihan`
   tetapi soalan tidak menyimpan `jenis` → dijadikan `bulat`, atau `kumpulan`
   jika soalan itu "padankan" dan semua item berkongsi 2 kategori yang sama.

2. **"Isi tempat kosong" transkrip sebagai item per-jenis.** Soalan "isi
   tempat kosong" ditranskrip sebagai senarai item yang setiap satunya membawa
   `jawapanContoh` (jawapan bagi tempat kosong itu). Ini ditukar kepada
   `tempat_kosong` dengan bank dibina daripada jawapan mengikut susunan item.

3. **Soalan berbilang bahagian.** Bahagian C/D kadangkala menggabungkan
   beberapa sub-soalan (senarai + huraian + tulis) dalam satu soalan, dengan
   setiap sub-soalan disimpan sebagai satu "item" yang membawa `jenis` sendiri.
   Ini dipecahkan kepada soalan berasingan supaya model dapat memaparkan dan
   memarkah setiap satu.

Skrip ini **tidak mengarang jawapan** — ia hanya memindahkan data sedia ada
ke struktur yang model fahami.
"""

import json
import re
import sys
from pathlib import Path

DASAR = Path('assets/content/sebenar')

# Padanan `jenis` pada item kepada jenis kanonik model.
JENIS_ITEM = {
    'tulis': 'tulis', 'توليس': 'tulis', 'سناراي': 'senarai',
    'senarai': 'senarai', 'huraian': 'huraian', 'سناراي': 'senarai',
    'padan': 'suai', 'suai': 'suai', 'kumpulan': 'kumpulan',
    'bulat': 'bulat', 'tempat_kosong': 'tempat_kosong',
}


def _ar_to_int(s):
    table = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')
    return s.translate(table)


def isi_tempat_kosong(soalan):
    teks = f"{soalan.get('soalan', '')} {soalan.get('rumi', '')}"
    return any(k in teks for k in (
        'isi tempat kosong', 'tempat kosong', 'ايسي تمڤت کوسوڠ',
        'ايسي تمڤت كوسوڠ', 'تمڤت کوسوڠ', 'تمڤت كوسوڠ', 'لڠکڤکن',
    ))


def pilihan_seragam(items):
    """Kembalikan tuple 2 pilihan jika semua item berkongsi 2 pilihan sama."""
    senarai = []
    for i in items:
        if not isinstance(i, dict):
            return None
        p = i.get('pilihan')
        if not p:
            return None
        senarai.append(tuple(
            (x.get('teks', '') if isinstance(x, dict) else x) for x in p))
    if not senarai:
        return None
    pertama = senarai[0]
    if len(pertama) == 2 and all(s == pertama for s in senarai):
        return pertama
    return None


def parse_markah(rumi, jawi, count):
    """Cuba baca `(N markah)` berurutan daripada teks gabungan."""
    # Rumi (digit ASCII).
    corak = re.findall(r'\((\d+)\s*markah\)', rumi, re.I)
    if len(corak) == count:
        return [int(n) for n in corak]
    corak = re.findall(r'\((\d+)\s*m\s*\)', rumi, re.I)
    if len(corak) == count:
        return [int(n) for n in corak]
    # Jawi (digit Arab-Indic).
    corak = re.findall(r'\(([٠-٩]+)\s*مركه', jawi)
    if len(corak) == count:
        return [int(_ar_to_int(n)) for n in corak]
    return None


def pilih_markah(parent_markah, items, item_jenis):
    """Markah bagi setiap sub-soalan apabila tiada dalam teks."""
    n = len(items)
    markah = []
    for i, j in zip(items, item_jenis):
        jj = JENIS_ITEM.get(j, 'tulis')
        if jj == 'senarai':
            bil = i.get('bilanganJawapan', 0)
            markah.append(bil if bil > 0 else 1)
        else:
            markah.append(1)
    # Selaraskan supaya jumlah = markah asal (agihkan baki ke sub-soalan pertama).
    jumlah = sum(markah)
    if jumlah != parent_markah and n > 0:
        markah[0] += parent_markah - jumlah
    return markah


def pecahkan(soalan, items, markah_list):
    """Hasilkan senarai soalan baharu daripada item berbilang bahagian."""
    hasil = []
    asas = {k: v for k, v in soalan.items() if k != 'item'}
    for idx, (i, mk) in enumerate(zip(items, markah_list), 1):
        jj = JENIS_ITEM.get(i.get('jenis'), 'tulis')
        baharu = dict(asas)
        baharu['id'] = f"{soalan['id']}-p{idx}"
        baharu['jenis'] = jj
        baharu['soalan'] = i.get('teks', '')
        baharu['rumi'] = i.get('rumi', '')
        baharu['markah'] = mk
        bil = i.get('bilanganJawapan')
        if bil is not None:
            baharu['bilanganJawapan'] = bil
        jc = i.get('jawapanContoh')
        if jc:
            baharu['jawapanContoh'] = jc
        jcr = i.get('jawapanContohRumi')
        if jcr:
            baharu['jawapanContohRumi'] = jcr
        # Buang medan item yang tidak relevan pada aras soalan.
        for k in ('jenis', 'teks', 'rumi', 'jawapanContoh', 'jawapanContohRumi',
                  'bilanganJawapan'):
            pass
        hasil.append(baharu)
    return hasil


def jadi_tempat_kosong(soalan, items):
    """Bina bank daripada `jawapanContoh` setiap item, mengikut susunan."""
    bank = []
    for i in items:
        if not isinstance(i, dict):
            continue
        for j in i.get('jawapanContoh', []):
            if j and j not in bank:
                bank.append(j)
    if not bank:
        return False
    # Item baharu: kekalkan teks/rumi (yang membawa `____`), buang medan jawapan.
    item_baru = []
    for i in items:
        if not isinstance(i, dict):
            continue
        item_baru.append({
            'teks': i.get('teks', ''),
            'rumi': i.get('rumi', ''),
        })
    soalan['jenis'] = 'tempat_kosong'
    soalan['bank'] = bank
    soalan['item'] = item_baru
    # Bank Rumi jika jawapan Rumi ada.
    bank_rumi = []
    for i in items:
        if isinstance(i, dict):
            for j in i.get('jawapanContohRumi', []):
                if j and j not in bank_rumi:
                    bank_rumi.append(j)
    if any(bank_rumi):
        soalan['bankRumi'] = bank_rumi
    return True


def proses_soalan(soalan):
    """Kembalikan senarai soalan pengganti (1 atau lebih)."""
    items = soalan.get('item', [])
    items = [i for i in items if isinstance(i, dict)]
    qj = soalan.get('jenis')

    # Item yang membawa `jenis` sendiri → transkrip berbilang bahagian.
    item_jenis = [i.get('jenis') for i in items if i.get('jenis')]

    if item_jenis and len(item_jenis) == len(items) and items:
        # "Isi tempat kosong" → tempat_kosong.
        if isi_tempat_kosong(soalan) or all(
                '____' in (i.get('teks', '') or '') for i in items):
            if jadi_tempat_kosong(soalan, items):
                return [soalan]
        # Berbilang bahagian → pecahkan.
        markah_list = parse_markah(
            soalan.get('rumi', ''), soalan.get('soalan', ''), len(items))
        if markah_list is None:
            markah_list = pilih_markah(
                soalan.get('markah', 0), items, item_jenis)
        return pecahkan(soalan, items, markah_list)

    # Soalan pilihan tanpa `jenis`.
    if items and all(i.get('pilihan') for i in items) and qj in (None, ''):
        seragam = pilihan_seragam(items)
        if seragam is not None:
            # Kelas kategori — kumpulan.
            pertama = items[0]['pilihan']
            soalan['jenis'] = 'kumpulan'
            soalan['kategori'] = [
                (x.get('teks', '') if isinstance(x, dict) else x)
                for x in pertama]
            soalan['kategoriRumi'] = [
                (x.get('rumi', '') if isinstance(x, dict) else '')
                for x in pertama]
            for i in items:
                i.pop('pilihan', None)
            return [soalan]
        soalan['jenis'] = 'bulat'
        return [soalan]

    # Soalan senarai satu item → naikkan ke aras soalan.
    if len(items) == 1 and items[0].get('jawapanContoh') and qj in (None, ''):
        i = items[0]
        jj = JENIS_ITEM.get(i.get('jenis'), 'senarai')
        soalan['jenis'] = jj
        soalan['bilanganJawapan'] = i.get('bilanganJawapan', 0)
        soalan['jawapanContoh'] = i.get('jawapanContoh', [])
        if i.get('jawapanContohRumi'):
            soalan['jawapanContohRumi'] = i['jawapanContohRumi']
        soalan['item'] = []
        return [soalan]

    return [soalan]


def betulkan(path):
    asal = path.read_text(encoding='utf-8')
    data = json.loads(asal)
    laporan = []

    for bahagian in data.get('bahagian', []):
        baharu = []
        for soalan in bahagian.get('soalan', []):
            ganti = proses_soalan(soalan)
            for g in ganti:
                if g['id'] != soalan.get('id'):
                    laporan.append(f"  {soalan.get('id')} → {g['id']} ({g.get('jenis')})")
                elif g.get('jenis') != soalan.get('jenis'):
                    laporan.append(f"  {soalan.get('id')}: {soalan.get('jenis')} → {g.get('jenis')}")
            baharu.extend(ganti)
        bahagian['soalan'] = baharu

    teks = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if teks != asal:
        path.write_text(teks, encoding='utf-8')
    print(f'{path.name}: {len(laporan)} perubahan')
    for b in laporan:
        print(b)


def main():
    for path in sorted(DASAR.glob('*.json')):
        betulkan(path)
    return 0


if __name__ == '__main__':
    sys.exit(main())
