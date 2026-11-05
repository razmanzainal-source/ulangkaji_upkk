// Laporan Ibu Bapa — logik pengiraan dan penjanaan PDF.
//
// Laporan ialah ciri untuk ibu bapa; ia mesti tepat walaupun rekod kosong,
// dan PDF mesti benar-benar boleh dijana (bukan hanya UI yang cantik).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulangkaji_upkk/models/gred.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';
import 'package:ulangkaji_upkk/services/kemajuan.dart';
import 'package:ulangkaji_upkk/services/laporan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gred laporan sama dengan gred rasmi app (A/B/C/D)', () {
    // Julat rasmi UPKK: A 80-100 · B 60-79 · C 40-59 · D 1-39 (tiada E).
    expect(Laporan.gred(100), 'A');
    expect(Laporan.gred(80), 'A');
    expect(Laporan.gred(79), 'B');
    expect(Laporan.gred(60), 'B');
    expect(Laporan.gred(59), 'C');
    expect(Laporan.gred(40), 'C');
    expect(Laporan.gred(39), 'D');
    expect(Laporan.gred(0), 'D');
  });

  test('gred laporan tidak boleh menyimpang daripada model Gred', () {
    for (var p = 0; p <= 100; p++) {
      expect(Laporan.gred(p), Gred.dariPeratus(p).huruf, reason: 'pada $p%');
    }
  });

  test('tanpa rekod: ringkasan kosong, tiada subjek fokus', () async {
    await BankKertas.instance.muat();
    expect(Laporan.ringkasan(), isEmpty);
    expect(Laporan.perluPerhatian(const []), isNull);
  });

  test('PDF dijana walaupun tiada rekod', () async {
    await BankKertas.instance.muat();
    final pdf = await Laporan.bina();
    expect(pdf.length, greaterThan(1000));
    // Kepala fail PDF.
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('ringkasan dikira daripada rekod sebenar', () async {
    final rekod = [
      {'t': '2026-10-01T10:00:00', 's': 'adab', 'k': 'p1', 'j': 'P1',
       'm': 42, 'p': 70, 'd': 3600},
      {'t': '2026-10-10T10:00:00', 's': 'adab', 'k': 'p2', 'j': 'P2',
       'm': 56, 'p': 70, 'd': 3600},
      {'t': '2026-10-12T10:00:00', 's': 'sirah', 'k': 'p3', 'j': 'P3',
       'm': 35, 'p': 70, 'd': 3600},
    ];
    SharedPreferences.setMockInitialValues({
      'rekod_percubaan': jsonEncode(rekod),
    });
    await BankKertas.instance.muat();
    await Kemajuan.instance.muat();

    final baris = Laporan.ringkasan();
    expect(baris, isNotEmpty);

    final adab = baris.firstWhere((b) => b.nama == 'Adab');
    expect(adab.percubaan, 2);
    expect(adab.terbaik, 80); // 56/70
    expect(adab.purata, 70); // (60 + 80) / 2
    expect(adab.perubahan, 20); // 80 - 60

    final sirah = baris.firstWhere((b) => b.nama == 'Sirah');
    expect(sirah.terbaik, 50); // 35/70
    expect(Laporan.perluPerhatian(baris)?.nama, 'Sirah');

    final pdf = await Laporan.bina();
    expect(pdf.length, greaterThan(2000));
  });

  test('perluPerhatian memilih purata terendah', () {
    const baris = [
      BarisLaporan(
          nama: 'Adab', percubaan: 2, terbaik: 80, purata: 75, perubahan: 5),
      BarisLaporan(
          nama: 'Sirah', percubaan: 1, terbaik: 55, purata: 55, perubahan: 0),
      BarisLaporan(
          nama: 'Jawi', percubaan: 3, terbaik: 90, purata: 88, perubahan: -2),
    ];
    expect(Laporan.perluPerhatian(baris)?.nama, 'Sirah');
  });
}
