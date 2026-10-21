// Soalan `kumpulan` — kelaskan setiap pernyataan ke dalam kategori.
//
// Kertas Adab UPKK 2024 Bahagian A Soalan Ketiga dan C Soalan Ketiga
// memakai bentuk ini:
//
//     (ا) جاڠن مڠهرتيديق مريک
//     (ب) (a) ادب دڠن کلوارک   (b) عاقبت تيدق برادب دڠن کلوارک
//
// Skemanya menulis `(a) → 1, 3` dan `(b) → 2, 4` — iaitu **setengah kategori
// menerima dua pernyataan**, dan kategori itu tidak habis apabila dipakai.
// Itu sebabnya ia tidak boleh menggunakan `PapanPadan`: papan itu memadam
// pasangan yang sudah dipadankan, jadi pernyataan ketiga tidak akan dapat
// dipadankan dengan (a) semula.
//
// Ujian ini mengunci perbezaan itu pada model dan pada papan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/widgets/papan_kumpulan.dart';

SoalanKertas _soalan() => SoalanKertas.dariJson(
      {
        'id': 'adab-a3',
        'jenis': 'kumpulan',
        'soalan': 'سووايکن ڤتاتاءن بهاڬين (ا) دڠن بهاڬين (ب).',
        'rumi': 'Suaikan pernyataan bahagian (ا) dengan bahagian (ب).',
        'markah': 4,
        'kategori': ['ادب دڠن کلوارک', 'عاقبت تيدق برادب دڠن کلوارک'],
        'kategoriRumi': ['Adab dengan keluarga', 'Akibat tidak beradab'],
        'item': [
          {'teks': 'جاڠن مڠهرتيديق مريک', 'jawapan': 0},
          {'teks': 'کلوارک تيدق بهاڬيا', 'jawapan': 1},
          {'teks': 'برتوتور دڠن لمه لمبوت', 'jawapan': 0},
          {'teks': 'هوبوڠن منجادي رڠکڠ', 'jawapan': 1},
        ],
      },
      bahagian: 'A',
      nombor: 3,
    );

void main() {
  group('model kumpulan', () {
    test('jenis dibaca daripada JSON', () {
      expect(_soalan().jenis, JenisKertas.kumpulan);
      expect(JenisKertas.dariTeks('kumpulan'), JenisKertas.kumpulan);
      expect(JenisKertas.kumpulan.teks, 'kumpulan');
    });

    test('kategori dibaca daripada JSON', () {
      expect(_soalan().kategori, hasLength(2));
      expect(_soalan().kategoriRumi, hasLength(2));
    });

    test('markah penuh ialah bilangan pernyataan', () {
      expect(_soalan().markahBolehDapat, 4);
    });

    test('setiap kategori boleh dipakai oleh beberapa pernyataan', () {
      final s = _soalan();
      // Dua pernyataan pertama kedua-duanya kategori 0 dan 1 seperti skema.
      final jawapan = const JawapanKumpulan([0, 1, 0, 1]);
      expect(s.markahDiperoleh(jawapan), 4);
      expect(s.betulPenuh(jawapan), isTrue);
    });

    test('markah separa dikikut pernyataan yang betul', () {
      final s = _soalan();
      expect(s.markahDiperoleh(const JawapanKumpulan([0, 0, 0, 0])), 2);
      expect(s.markahDiperoleh(const JawapanKumpulan([0, -1, -1, -1])), 1);
      expect(s.markahDiperoleh(const JawapanKumpulan([-1, -1, -1, -1])), 0);
      expect(s.markahDiperoleh(null), 0);
    });

    test('lengkap hanya apabila setiap pernyataan dikelaskan', () {
      final s = _soalan();
      expect(s.lengkap(const JawapanKumpulan([0, 1, 0, -1])), isFalse);
      expect(s.lengkap(const JawapanKumpulan([0, 1, 0, 1])), isTrue);
    });

    test('jawapan penuh menyebut pernyataan dan kategorinya', () {
      final teks = _soalan().jawapanPenuhTeks;
      expect(teks, contains('جاڠن مڠهرتيديق مريک — ادب دڠن کلوارک'));
      expect(teks.split('\n'), hasLength(4));
      expect(_soalan().jawapanPenuhDengar, contains('Adab dengan keluarga'));
    });
  });

  group('papan kumpulan', () {
    testWidgets('kategori yang sama boleh dipilih beberapa kali', (t) async {
      var dipilih = <int>[];

      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PapanKumpulan(
                pernyataan: const ['satu', 'dua', 'tiga'],
                kategori: const ['A', 'B'],
                kategoriRumi: const ['alpha', 'beta'],
                jawapan: const [-1, -1, -1],
                warna: Colors.pink,
                onJawab: (i, k) => dipilih = [...dipilih, i * 10 + k],
              ),
            ),
          ),
        ),
      );

      // Dua pernyataan berturut-turut memilih kategori yang sama — dalam
      // `PapanPadan` butang kedua itu sudah pun dipadam daripada lajur kanan.
      await t.tap(find.text('A').at(0));
      await t.tap(find.text('A').at(1));

      expect(dipilih, [0, 10]);
    });

    testWidgets('label kategori dipaparkan berserta panduan Rumi', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PapanKumpulan(
              pernyataan: const ['pernyataan'],
              kategori: const ['ادب'],
              kategoriRumi: const ['adab'],
              jawapan: const [-1],
              warna: Colors.pink,
              onJawab: (i, k) {},
            ),
          ),
        ),
      );

      expect(find.text('ادب'), findsOneWidget);
      expect(find.text('adab'), findsOneWidget);
      expect(find.text('pernyataan'), findsOneWidget);
    });
  });
}
