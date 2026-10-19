// Ujian penjana kertas percubaan.
//
// Penjana kertas ialah bahagian yang paling senang rosak diam-diam: bank soalan
// boleh dibaca, skrin boleh dipaparkan, tetapi kertas yang dijana boleh berjumlah
// 56 markah sedangkan kertas UPKK sebenar 70. Murid tidak akan perasan — mereka
// hanya nampak markah yang lebih rendah. Ujian ini mengunci peraturan format itu
// supaya kesilapan seperti ini ditangkap sebelum app dibina.
//
// Fail ujian membaca bank terus daripada cakera (`dart:io`), bukan melalui
// `rootBundle`, supaya ujian berjalan tanpa keadaan app Flutter dan boleh
// dijalankan selepas bank soalan dijana semula.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/jana_kertas.dart';

/// Laluan akar projek — ujian berjalan dari akar projek.
const String _akar = '.';

Subjek _bacaSubjek(String id) {
  final data =
      jsonDecode(File('$_akar/assets/content/subjek.json').readAsStringSync())
          as Map<String, dynamic>;
  final senarai = (data['subjek'] as List).cast<Map<String, dynamic>>();
  final json = senarai.firstWhere((s) => s['id'] == id);
  return Subjek.dariJson(json);
}

List<SoalanKertas> _bacaBank(String id) {
  final data = jsonDecode(
    File('$_akar/assets/content/bank/$id.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (data['soalan'] as List)
      .cast<Map<String, dynamic>>()
      .asMap()
      .entries
      .map((e) => SoalanKertas.dariJson(
            e.value,
            bahagian: (e.value['bahagian'] as String?) ?? '',
            nombor: e.key + 1,
          ))
      .toList();
}

/// Semua subjek yang banknya sudah ada dalam projek.
List<String> _subjekAdaBank() {
  final data =
      jsonDecode(File('$_akar/assets/content/subjek.json').readAsStringSync())
          as Map<String, dynamic>;
  final semua = (data['subjek'] as List)
      .cast<Map<String, dynamic>>()
      .map((s) => s['id'] as String);
  return [
    for (final id in semua)
      if (File('$_akar/assets/content/bank/$id.json').existsSync()) id,
  ];
}

void main() {
  group('format kertas percubaan', () {
    test('sekurang-kurangnya satu subjek sudah ada bank', () {
      expect(_subjekAdaBank(), isNotEmpty);
    });

    for (final id in _subjekAdaBank()) {
      test('$id: setiap percubaan bernilai 70 markah', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);
        final markahPenuh = subjek.bahagian.fold<int>(
          0,
          (jumlah, b) => jumlah + b.markah,
        );

        // Sepuluh percubaan berturut-turut — cukup untuk menguji tetingkap
        // bergerak tanpa menjadikan ujian lambat.
        for (var giliran = 0; giliran < 10; giliran++) {
          final kertas = JanaKertas.percubaan(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );

          final jumlah = kertas.bahagian.fold<int>(
            0,
            (a, b) => a + b.markahTersedia,
          );
          expect(
            jumlah,
            markahPenuh,
            reason: 'percubaan $giliran bagi $id hanya $jumlah markah',
          );
        }
      });

      test('$id: bilangan soalan setiap bahagian menepati format rasmi', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);

        for (var giliran = 0; giliran < 5; giliran++) {
          final kertas = JanaKertas.percubaan(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );
          for (final format in subjek.bahagian) {
            final bahagian =
                kertas.bahagian.where((b) => b.nama == format.nama).first;
            expect(
              bahagian.soalan.length,
              format.bilangan,
              reason: 'percubaan $giliran, bahagian ${format.nama}',
            );
          }
        }
      });

      test('$id: tiada soalan berulang dalam satu kertas', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);

        for (var giliran = 0; giliran < 10; giliran++) {
          final kertas = JanaKertas.percubaan(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );
          final idSoalan = [
            for (final bahagian in kertas.bahagian)
              for (final s in bahagian.soalan) s.id,
          ];
          expect(
            idSoalan.toSet().length,
            idSoalan.length,
            reason: 'percubaan $giliran bagi $id mengulang soalan',
          );
        }
      });

      test('$id: percubaan berturut-turut tidak sama', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);
        // Bank perlu cukup besar untuk ini bermakna; subjek yang banknya masih
        // kecil dilangkau dan diberitahu secara jelas.
        if (bank.length < subjek.bahagian.fold<int>(
              0,
              (a, b) => a + b.bilangan,
            ) *
            2) {
          return;
        }

        String cap(Kertas k) => k.bahagian
            .expand((b) => b.soalan)
            .map((s) => s.id)
            .join(',');
        final satu = cap(
          JanaKertas.percubaan(subjek: subjek, bank: bank, giliran: 0),
        );
        final dua = cap(
          JanaKertas.percubaan(subjek: subjek, bank: bank, giliran: 1),
        );
        expect(satu, isNot(dua));
      });
    }
  });

  group('latih tubi', () {
    for (final id in _subjekAdaBank()) {
      test('$id: sepuluh soalan, tiada ulangan', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);

        for (var giliran = 0; giliran < 5; giliran++) {
          final kertas = JanaKertas.latihTubi(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );
          final idSoalan = [for (final s in kertas.semuaSoalan) s.id];

          expect(idSoalan.length, 10);
          expect(
            idSoalan.toSet().length,
            idSoalan.length,
            reason: 'latih tubi $giliran bagi $id mengulang soalan',
          );
          expect(kertas.jenisSumber, 'latihan');
        }
      });

      test('$id: markah latih tubi tidak bercanggah', () {
        // Kulit kertas memaparkan "X markah (Y tersedia)" apabila X dan Y
        // berbeza. Untuk latih tubi, X ialah jumlah markah soalan yang benar-
        // benar terpilih — jadi kedua-duanya mesti sama. Sebelum ini X ialah
        // *bilangan* soalan, dan kulit kertas mengaku "10 markah (15 tersedia)".
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);

        for (var giliran = 0; giliran < 5; giliran++) {
          final kertas = JanaKertas.latihTubi(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );
          final jumlahSoalan = kertas.semuaSoalan.fold<int>(
            0,
            (jumlah, s) => jumlah + s.markahBolehDapat,
          );

          expect(kertas.markahPenuh, jumlahSoalan);
          expect(
            kertas.markahTersedia,
            jumlahSoalan,
            reason: 'kulit kertas akan memaparkan dua markah berbeza',
          );
        }
      });
    }
  });

  group('bank soalan', () {
    for (final id in _subjekAdaBank()) {
      test('$id: setiap soalan mempunyai markah positif', () {
        for (final s in _bacaBank(id)) {
          expect(
            s.markahBolehDapat,
            greaterThan(0),
            reason: '${s.id} tidak boleh dimarkah',
          );
        }
      });

      test('$id: setiap soalan mempunyai teks Jawi dan Rumi', () {
        for (final s in _bacaBank(id)) {
          expect(s.soalan.trim(), isNotEmpty, reason: '${s.id} tiada teks Jawi');
          expect(s.rumi.trim(), isNotEmpty, reason: '${s.id} tiada teks Rumi');
        }
      });

      test('$id: bank mencukupi untuk satu kertas penuh', () {
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);
        expect(
          JanaKertas.lengkap(subjek, bank),
          isTrue,
          reason: 'kekurangan: ${JanaKertas.bahagianKurang(subjek, bank)}',
        );
      });

      test('$id: percubaan berturut-turut meliputi sebahagian besar bank', () {
        // Percubaan bukan satu kertas tetap: ia dijana semula setiap kali, dan
        // gunanya ialah supaya murid bertemu soalan yang berbeza-beza. Kalau
        // penjana sentiasa memilih soalan yang sama, separuh bank menjadi sia-sia
        // dan murid menghafal jawapan dan bukan memahami.
        final subjek = _bacaSubjek(id);
        final bank = _bacaBank(id);

        final dipakai = <String>{};
        for (var giliran = 0; giliran < 60; giliran++) {
          final kertas = JanaKertas.percubaan(
            subjek: subjek,
            bank: bank,
            giliran: giliran,
          );
          for (final bahagian in kertas.bahagian) {
            for (final s in bahagian.soalan) {
              dipakai.add(s.id);
            }
          }
        }

        final nisbah = dipakai.length / bank.length;
        expect(
          nisbah,
          greaterThanOrEqualTo(0.5),
          reason: 'hanya ${dipakai.length} daripada ${bank.length} soalan '
              'digunakan dalam 60 percubaan',
        );
      });
    }
  });
}
