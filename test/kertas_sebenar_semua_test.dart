// Semua kertas sebenar UPKK yang ditranskrip — imbasan + skema rasmi.
//
// Setiap kertas yang ada di `assets/content/sebenar/` mesti **boleh dimuatkan**
// oleh model. Sebelum ini, `BankKertas._muatKertasJawab` menelan ralat
// parsing dengan `catch (_) {}` — jadi kertas yang JSON-nya rosak senyap sahaja
// menjadi "hanya imej", tanpa butang "Jawab".
//
// Ujian ini mengunci:
//   1. Setiap fail JSON di `assets/content/sebenar/` berjaya di-parse.
//   2. Format rasmi UPKK: 70 markah, 1 jam 15 minit, bahagian A/B/C/D.
//   3. Setiap indeks jawapan berada dalam julat.
//   4. Soalan `kumpulan` mempunyai 2 kategori; `senarai` ada jawapan contoh.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Nama fail JSON di `assets/content/sebenar/` (tanpa `.json`).
  List<String> _failSebenar() {
    final dir = Directory('assets/content/sebenar');
    if (!dir.existsSync()) return const [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path.split('/').last.replaceAll('.json', ''))
        .toList()
      ..sort();
  }

  group('muatan kertas sebenar', () {
    test('setiap fail JSON di assets/content/sebenar berjaya di-parse', () {
      final gagal = <String>[];
      for (final nama in _failSebenar()) {
        try {
          final json = jsonDecode(
            File('assets/content/sebenar/$nama.json').readAsStringSync(),
          ) as Map<String, dynamic>;
          Kertas.dariJson(json);
        } catch (e) {
          gagal.add('$nama: $e');
        }
      }
      expect(
        gagal,
        isEmpty,
        reason: 'Kertas berikut gagal di-parse — butang "Jawab" tidak akan '
            'muncul untuk kertas yang gagal:\n${gagal.join('\n')}',
      );
    });

    test('setiap kertas ditranskrip boleh dijawab dalam app', () async {
      await BankKertas.instance.muat();
      for (final nama in _failSebenar()) {
        expect(
          BankKertas.instance.bolehJawab(nama),
          isTrue,
          reason: '$nama tidak boleh dijawab — semak ralat parsing JSON',
        );
      }
    });
  });

  group('format rasmi setiap kertas sebenar', () {
    for (final nama in _failSebenar()) {
      test('$nama menepati format UPKK', () async {
        await BankKertas.instance.muat();
        final k = BankKertas.instance.kertasJawab(nama);
        expect(k, isNotNull, reason: 'kertas $nama tidak dimuatkan');

        expect(k!.markahPenuh, 70, reason: '$nama jumlah markah');
        expect(k.masaMinit, 75, reason: '$nama masa');
        expect(k.jenisSumber, 'sebenar', reason: '$nama jenis sumber');
        expect(
          k.bahagian.map((b) => b.nama).toSet(),
          containsAll(['A', 'B', 'C', 'D']),
          reason: '$nama bahagian',
        );
        // Jawi dan Khat mempunyai bahagian E (menulis semula ayat dalam Jawi);
        // subjek lain hanya A–D.
        expect(
          k.bahagian
              .map((b) => b.nama)
              .toSet()
              .difference({'A', 'B', 'C', 'D', 'E'}),
          isEmpty,
          reason: '$nama mempunyai bahagian di luar A–E',
        );
        expect(
          k.bahagian.fold<int>(0, (j, b) => j + b.markah),
          70,
          reason: '$nama jumlah markah bahagian',
        );
      });

      test('$nama indeks jawapan berada dalam julat', () async {
        await BankKertas.instance.muat();
        final k = BankKertas.instance.kertasJawab(nama)!;
        for (final s in k.semuaSoalan) {
          for (final i in s.item) {
            if (i.pilihan.isEmpty) continue;
            expect(
              i.jawapan,
              greaterThanOrEqualTo(0),
              reason: '${s.id}/${i.nombor} tiada jawapan',
            );
            expect(
              i.jawapan,
              lessThan(i.pilihan.length),
              reason: '${s.id}/${i.nombor} jawapan luar julat',
            );
          }
          if (s.jenis == JenisKertas.kumpulan) {
            expect(s.kategori, hasLength(2), reason: '${s.id} kategori');
            expect(s.kategoriRumi, hasLength(2), reason: '${s.id} kategoriRumi');
            for (final i in s.item) {
              expect(
                i.jawapan,
                lessThan(s.kategori.length),
                reason: '${s.id}/${i.nombor} kategori luar julat',
              );
            }
          }
          if (s.jenis == JenisKertas.senarai) {
            expect(s.bilanganJawapan, greaterThan(0), reason: '${s.id} isi');
            expect(s.jawapanContoh, isNotEmpty, reason: '${s.id} jawapan contoh');
          }
        }
      });

      test('$nama setiap item ada teks Rumi', () async {
        await BankKertas.instance.muat();
        final k = BankKertas.instance.kertasJawab(nama)!;
        for (final s in k.semuaSoalan) {
          expect(s.rumi.trim(), isNotEmpty, reason: '${s.id} soalan');
          for (final i in s.item) {
            if (i.teks.trim().isEmpty) continue;
            expect(i.rumi.trim(), isNotEmpty, reason: '${s.id}/${i.nombor}');
          }
        }
      });
    }
  });
}
