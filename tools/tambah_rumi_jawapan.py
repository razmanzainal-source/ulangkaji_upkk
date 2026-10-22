#!/usr/bin/env python3
"""Tambah medan `jawapanContohRumi` yang hilang pada kertas sebenar.

Soalan bertulis/senarai menyimpan jawapan dalam **Jawi**. Enjin suara Melayu
tidak boleh membaca Jawi, jadi tanpa medan Rumi butang "Dengar soalan &
jawapan betul" tidak dapat membacakan jawapan itu.

Skrip ini hanya menambah terjemahan Rumi bagi jawapan yang jelas dan
sahih — jawapan yang Jawainya sudah rosak (hasil OCR) **tidak** disentuh,
supaya tiada kandungan yang dikarang masuk ke dalam app.
"""
import json
from pathlib import Path

DASAR = Path('assets/content/sebenar')

# id soalan -> senarai jawapan Rumi (selaras dengan `jawapanContoh`).
RUMI = {
    # ---- Adab 2025 -------------------------------------------------------
    'adab-2025-d1-p1': ['Tidur', 'Bermain'],
    'adab-2025-d1-p2': [
        'Niat yang ikhlas untuk belajar',
        'Membaca doa sebelum belajar',
        'Duduk dengan sopan',
    ],
    'adab-2025-d1-p3': ['Dapat membentuk peribadi dan akhlak yang mulia'],
    'adab-2025-d2-p1': [
        'Menjaga kebersihan',
        'Memperbanyakkan zikir kepada Allah',
    ],
    'adab-2025-d2-p2': [
        'Mendapat ketenangan hati',
        'Terpelihara daripada maksiat',
    ],
    'adab-2025-d2-p3': ['Memberi imej buruk kepada diri sendiri'],
    'adab-2025-d4-p1': ['Adab ketika bergotong-royong'],
    'adab-2025-d4-p2': ['Di sekolah'],
    'adab-2025-d4-p3': ['Semangat bekerja sama', 'Suka membantu'],

    # ---- Akidah 2024 ------------------------------------------------------
    'akidah-2024-c3-p1': ['Jujur', 'Bijaksana'],
    'akidah-2024-c3-p2': ['Sihat', 'Bijaksana'],
    'akidah-2024-c3-p3': ['Lemah', 'Kebencian'],
    'akidah-2024-c5-p1': ['Iradah'],
    'akidah-2024-c5-p2': [
        'Berusaha, berikhtiar, bertawakal, rida dengan ketetapan Allah',
    ],
    'akidah-2024-d2-p1': ['Iradah'],
    'akidah-2024-d2-p2': [
        'Al-Quran sumber ilmu',
        'Al-Quran panduan dalam kehidupan',
    ],
    'akidah-2024-d3': [
        'Sabar', 'Rida', 'Bertawakal', 'Tidak putus asa',
        'Bersedia berusaha', 'Berusaha',
    ],
    'akidah-2024-d4-p1': ['Nikmat yang diterima semakin berkurang'],
    'akidah-2024-d4-p2': ['Tidak takut azab Allah', 'Jiwa tidak tenteram'],
    'akidah-2024-d5': [
        'Dosa', 'Kebala', 'Tenggelam dalam dosa', 'Hisab', 'Qadha Mahsyar',
        'Syirik', 'Niraka', 'Alam Barzakh', 'Barzakh',
    ],
    'akidah-2024-d6': [
        'Nikmat kubur', 'Azab kubur', 'Soal kubur', 'Hari Kiamat', 'Mizan',
        'Malaikat', 'Barzakh',
    ],

    # ---- Akidah 2025 ------------------------------------------------------
    'akidah-2025-d1-p1': ['Nur', 'Khayr'],
    'akidah-2025-d1-p2': [
        'Syirik', 'Niraka', 'Perkahwinan', 'Pengqednian anak perempuan',
        'Beriman', 'Bertakwa', 'Taat', 'Wafat',
    ],
    'akidah-2025-d2-p1': [
        'Sentiasa mengagungkan Allah',
        'Sentiasa memuji ayat-ayat-Nya',
        'Sentiasa bersedia menjadi tetamu',
        'Sentiasa menerima kematian sebagai makhluk ciptaan',
    ],
    'akidah-2025-d2-p2': [
        'Sentiasa bersedia menjadi tetamu',
        'Sentiasa menerima kematian sebagai makhluk ciptaan',
        'Sentiasa mengagungkan Allah',
        'Sentiasa memuji ayat-ayat-Nya',
    ],
    'akidah-2025-d3-p1': [
        'Kambing', 'Ikan', 'Kerbau', 'Kijang', 'Lembu',
    ],
    'akidah-2025-d3-p2': [
        'Ikan', 'Udang', 'Katak', 'Sotong', 'Kerang',
    ],
    'akidah-2025-d4': [
        'Iman bertambah', 'Takwa semakin kokoh', 'Memperbanyakkan ibadah',
        'Menjauhi maksiat', 'Sentiasa bertaubat',
    ],
    'akidah-2025-d5': [
        'Allah tiada kelam',
        'Allah tidak berbeza lain',
        'Sifat baharu hanya ada pada makhluk',
        'Tidak menyerupai perbuatan makhluk lain',
    ],
    'akidah-2025-d6-p1': [
        'Kubur bertiang', 'Kubur yang dijulang', 'Tersekat di dalam kubur',
        'Mendapat balasan', 'Jatuh dalam syirik',
    ],
    'akidah-2025-d6-p2': [
        'Kubur khalq', 'Kubur kliota', 'Dihimpunkan oleh malaikat',
        'Disembelih seperti haiwan yang dibunuh',
    ],

    # ---- Ibadah 2024 ------------------------------------------------------
    'ibadah-2024-c5-p1': ['Solat Zohor'],
    'ibadah-2024-c5-p2': ['Solat Jumaat'],
    'ibadah-2024-c5-p3': ['Solat Jumaat'],
    'ibadah-2024-c5-p4': ['Solat Zohor'],
    'ibadah-2024-c5-p5': ['Solat Zohor'],
    'ibadah-2024-c5-p6': ['Solat Zohor'],
    'ibadah-2024-c5-p7': ['Solat Jumaat'],
    'ibadah-2024-d1-p1': ['Muhrim'],
    'ibadah-2024-d1-p2': ['Ibtikaf'],
    'ibadah-2024-d1-p3': ['Herus'],
    'ibadah-2024-d1-p4': ['Diwasa'],
    'ibadah-2024-d1-p5': ['Wajib'],
    'ibadah-2024-d1-p6': ['Harām'],
    'ibadah-2024-d2-p1': ['Dalil'],
    'ibadah-2024-d2-p2': ['Aur at', 'Baligh', 'Umur', 'Tawb'],
    'ibadah-2024-d3-p1': [
        'Solat Zohor - 1 Didahului khutbah, 2 Diiring berjemaah',
    ],
    'ibadah-2024-d3-p2': [
        'Solat Jumaat - 1 Disusuli dua khutbah, 2 Dilaksanakan berturut-turut',
    ],
    'ibadah-2024-d4-p1': ['Asyhadu'],
    'ibadah-2024-d4-p2': ['Wajib'],
    'ibadah-2024-d4-p3': ['Harām'],
    'ibadah-2024-d4-p4': ['Muharram'],
    'ibadah-2024-d4-p5': ['Diwasa'],
    'ibadah-2024-d5-p1': ['Solat berjemaah'],
    'ibadah-2024-d5-p2': ['Munqati', 'Mustamir'],
    'ibadah-2024-d6-p1': ['Hukum: tidak sah'],
    'ibadah-2024-d6-p2': [
        'Alasan: solat Jumaat dilakukan pada waktu Zohor, sama ada Jumaat awal '
        'atau Jumaat akhir',
    ],
    'ibadah-2024-d7-p1': ['Solat witr', 'Solat dhuha'],
    'ibadah-2024-d8-p1': ['Solat secara senyap', 'Solat secara boleh didengar'],
    'ibadah-2024-d9-p1': [
        'Menutup aurat dengan sempurna', 'Menjaga kehormatan diri',
    ],
    'ibadah-2024-d10-p1': ['Takbiratul ihram', 'Membaca surah Al-Fatihah'],
    'ibadah-2024-d11-p1': [
        'Solat sunat terawih', 'Berpuasa Ramadan',
        'Bers consultora dengan Ahmad yang Fakir',
    ],
}


def main() -> int:
    jumlah = 0
    for path in sorted(DASAR.glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8'))
        berubah = False
        for bahagian in data.get('bahagian', []):
            for soalan in bahagian.get('soalan', []):
                rumi = RUMI.get(soalan.get('id'))
                if not rumi:
                    continue
                jc = soalan.get('jawapanContoh') or []
                if len(rumi) != len(jc):
                    print(f'  (!) {soalan["id"]}: bilangan tidak sama — dilangkau')
                    continue
                soalan['jawapanContohRumi'] = rumi
                berubah = True
                jumlah += 1
        if berubah:
            path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                encoding='utf-8',
            )
            print(f'{path.name}: dikemas kini')
    print(f'{jumlah} soalan ditambah dengan jawapan Rumi')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
