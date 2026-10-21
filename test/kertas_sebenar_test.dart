// Kertas sebenar Adab UPKK 2024 — transkrip imbasan + skema rasmi.
//
// Kertas ini ialah kertas yang sama yang dipegang murid UPKK: soalan diambil
// terus daripada imbasan (assets/kertas/adab-2024/) dan **jawapan diambil
// terus daripada skema rasmi pada muka 11** — tiada jawapan yang ditulis oleh
// pembangun app.
//
// Ujian ini mengunci:
//   1. Strukturnya menepati format rasmi (70 markah, 1 jam 15 minit).
//   2. Setiap indeks jawapan berada dalam julat — kesilapan transkrip nombor
//      menjadikan soalan mustahil untuk dijawab betul.
//   3. Setiap soalan jenis terbuka (`senarai`) dan kumpulan mempunyai kandungan
//      yang diperlukannya.

import 'package:flutter_test/flutter_test.dart';

import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  late Kertas kertas;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await BankKertas.instance.muat();
    final k = BankKertas.instance.kertasJawab('adab-2024');
    expect(k, isNotNull,
        reason: 'kertas sebenar tidak dimuatkan: ${BankKertas.instance.ralat}');
    kertas = k!;
  });

  group('kertas Adab 2024', () {
    test('boleh dijawab, bukan sekadar imbasan', () {
      expect(BankKertas.instance.bolehJawab('adab-2024'), isTrue);
      expect(BankKertas.instance.kertasJawab('adab-2025'), isNull);
    });

    test('menepati format rasmi UPKK', () {
      expect(kertas.markahPenuh, 70);
      expect(kertas.markahTersedia, 70);
      expect(kertas.masaMinit, 75);
      expect(kertas.jenisSumber, 'sebenar');
      expect(kertas.subjekId, 'adab');
      expect(kertas.bahagian.map((b) => b.nama), ['A', 'B', 'C', 'D']);
      expect(kertas.bahagian.map((b) => b.markah), [10, 10, 30, 20]);
      expect(kertas.bilanganSoalan, 27);
    });

    test('setiap indeks jawapan berada dalam julat', () {
      for (final s in kertas.semuaSoalan) {
        for (final i in s.item) {
          if (i.pilihan.isEmpty) continue;
          expect(i.jawapan, greaterThanOrEqualTo(0), reason: '${s.id}/${i.nombor}');
          expect(
            i.jawapan,
            lessThan(i.pilihan.length),
            reason: '${s.id}/${i.nombor}',
          );
        }
      }
    });

    test('pilihan setiap item unik', () {
      for (final s in kertas.semuaSoalan) {
        for (final i in s.item) {
          final pilihan = i.pilihan.where((p) => p.trim().isNotEmpty).toList();
          expect(
            pilihan.toSet().length,
            pilihan.length,
            reason: '${s.id}/${i.nombor} mempunyai pilihan berulang',
          );
        }
      }
    });

    test('soalan tempat kosong mempunyai bank yang cukup', () {
      for (final s in kertas.semuaSoalan.where(
        (s) => s.jenis == JenisKertas.tempatKosong,
      )) {
        expect(s.bank, isNotEmpty, reason: s.id);
        for (final i in s.item) {
          expect(i.jawapan, lessThan(s.bank.length), reason: s.id);
        }
      }
    });

    test('soalan kumpulan mempunyai kategori untuk setiap item', () {
      for (final s in kertas.semuaSoalan.where(
        (s) => s.jenis == JenisKertas.kumpulan,
      )) {
        expect(s.kategori, hasLength(2), reason: s.id);
        expect(s.kategoriRumi, hasLength(2), reason: s.id);
        for (final i in s.item) {
          expect(i.jawapan, lessThan(s.kategori.length), reason: s.id);
        }
      }
    });

    test('soalan senarai mempunyai jawapan contoh yang boleh disemak', () {
      for (final s in kertas.semuaSoalan.where(
        (s) => s.jenis == JenisKertas.senarai,
      )) {
        expect(s.bilanganJawapan, greaterThanOrEqualTo(1), reason: s.id);
        expect(s.jawapanContoh, isNotEmpty, reason: s.id);
        expect(s.jawapanContoh.every((j) => j.trim().isNotEmpty), isTrue,
            reason: s.id);
        expect(s.jawapanContohRumi.every((j) => j.trim().isNotEmpty), isTrue,
            reason: s.id);
      }
    });

    test('setiap item mempunyai teks Rumi untuk skrin latih tubi', () {
      for (final s in kertas.semuaSoalan) {
        expect(s.rumi.trim(), isNotEmpty, reason: '${s.id} soalan');
        for (final i in s.item) {
          if (i.teks.trim().isEmpty) continue;
          expect(i.rumi.trim(), isNotEmpty, reason: '${s.id}/${i.nombor}');
        }
      }
    });
  });
}
