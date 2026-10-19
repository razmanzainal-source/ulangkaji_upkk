// Ujian "Kertas Sebenar" — imbasan kertas UPKK 2024 dan 2025.
//
// Kertas sebenar ialah bukti app ini bukan sekadar kuiz: murid boleh melihat
// kertas yang sama seperti yang akan dipegangnya di dewan peperiksaan. Dua
// perkara senang rosak tanpa disedari:
//
//   1. **Fail imbasan.** `subjek.json` boleh menyebut 13 muka, sedangkan folder
//      hanya mempunyai 12 (muka terakhir rosak), atau sebaliknya — muka ke-14
//      dibundelkan tetapi tidak didaftarkan, jadi ia berada dalam app tanpa
//      pernah dilihat sesiapa.
//
//   2. **Pembaca.** Senarai tahun, pembaca satu muka satu halaman, jalur
//      thumbnail, dan butang Sebelum/Seterusnya.
//
// Kedua-duanya diperiksa di sini — yang pertama terus daripada cakera, yang
// kedua dengan membuka skrin sebenar.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/kertas_sebenar_screen.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

import 'bantuan/saiz_telefon.dart';

/// Laluan akar projek — ujian berjalan dari akar projek.
const String _akar = '.';

List<Subjek> _subjekDariCakera() {
  final data = jsonDecode(
    File('$_akar/assets/content/subjek.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (data['subjek'] as List)
      .cast<Map<String, dynamic>>()
      .map(Subjek.dariJson)
      .toList();
}

/// Majukan beberapa bingkai — pembaca tidak boleh memakai `pumpAndSettle`
/// kerana maskot Upik di skrin belakang berdenyut tanpa henti.
Future<void> _bingkai(WidgetTester tester, [int bilangan = 10]) async {
  for (var i = 0; i < bilangan; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  final subjek = _subjekDariCakera();

  group('fail imbasan', () {
    test('setiap subjek ada kertas 2024 dan 2025', () {
      for (final s in subjek) {
        final tahun = {for (final k in s.kertasSebenar) k.tahun};
        expect(
          tahun,
          containsAll(<int>[2024, 2025]),
          reason: 'subjek ${s.id} hanya ada tahun $tahun',
        );
      }
    });

    test('setiap muka yang didaftarkan benar-benar ada', () {
      for (final s in subjek) {
        for (final k in s.kertasSebenar) {
          expect(k.muka, greaterThan(0), reason: '${k.folder} tiada muka');
          for (var i = 1; i <= k.muka; i++) {
            expect(
              File('$_akar/${k.laluan(i)}').existsSync(),
              isTrue,
              reason: '${k.laluan(i)} didaftarkan tetapi tiada di cakera',
            );
          }
        }
      }
    });

    test('tiada muka dibundelkan tanpa didaftarkan', () {
      for (final s in subjek) {
        for (final k in s.kertasSebenar) {
          final bilangan = Directory('$_akar/assets/kertas/${k.folder}')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.jpg'))
              .length;
          expect(
            bilangan,
            k.muka,
            reason:
                '${k.folder}: $bilangan imbasan dibundelkan tetapi hanya '
                '${k.muka} didaftarkan — bakinya tidak akan dilihat murid',
          );
        }
      }
    });
  });

  group('pembaca kertas sebenar', () {
    testWidgets('senarai membuka pembaca, dan pembaca menyelak muka', (
      tester,
    ) async {
      gunaSaizTelefon(tester);

      // Aset dibaca melalui saluran platform, jadi ia memerlukan gelung
      // peristiwa sebenar — `runAsync` membenarkan kerja itu di dalam ujian
      // widget (tanpa ini, `muat` tergantung selama-lamanya).
      await tester.runAsync(() => BankKertas.instance.muat());
      expect(BankKertas.instance.sedia, isTrue, reason: 'bank gagal dimuatkan');

      await tester.pumpWidget(const MaterialApp(home: SenaraiKertasSebenar()));
      await tester.pump();

      // Kad pengenalan di atas senarai.
      expect(find.text('Kertas UPKK sebenar'), findsOneWidget);

      // Ambil subjek dan kertas pertama, dan pastikan cipnya boleh ditekan.
      final s = BankKertas.instance.subjek.first;
      expect(
        s.kertasSebenar,
        isNotEmpty,
        reason: '${s.id} tiada kertas sebenar',
      );
      final k = s.kertasSebenar.first;
      final cip = find.byKey(ValueKey('cip-${s.id}-${k.tahun}'));

      await tester.dragUntilVisible(
        cip,
        find.byType(ListView).first,
        const Offset(0, -200),
        maxIteration: 30,
      );
      await tester.tap(cip);
      await _bingkai(tester);

      // Pembaca: tajuk kertas dan kiraan muka surat.
      expect(find.text('${s.nama} ${k.tahun}'), findsOneWidget);
      expect(find.text('Muka 1 / ${k.muka}'), findsOneWidget);

      // Sebelum muka pertama, butang Sebelum dimatikan — tidak boleh tersasar.
      final sebelum = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Sebelum'),
      );
      expect(sebelum.onPressed, isNull, reason: 'muka pertama tiada Sebelum');

      // Selak ke muka kedua.
      await tester.tap(find.text('Seterusnya'));
      await _bingkai(tester, 6);
      expect(find.text('Muka 2 / ${k.muka}'), findsOneWidget);

      // Jalur thumbnail: tekan muka ketiga terus.
      await tester.tap(find.text('Kertas penuh'));
      await _bingkai(tester, 4);
      await tester.tap(find.byKey(const Key('jalur-muka-3')));
      await _bingkai(tester, 4);
      expect(find.text('Muka 3 / ${k.muka}'), findsOneWidget);

      // Tutup jalur dan kembali ke muka pertama.
      await tester.tap(find.text('Tutup jalur'));
      await _bingkai(tester, 2);
      await tester.tap(find.text('Sebelum'));
      await _bingkai(tester, 4);
      expect(find.text('Muka 2 / ${k.muka}'), findsOneWidget);

      // Kembali ke senarai — tidak boleh tergantung.
      await tester.pageBack();
      await _bingkai(tester, 6);
      expect(find.byType(SenaraiKertasSebenar), findsOneWidget);

      // Senarai masih pada kedudukan tatal yang tadi (cip tahun di bawah),
      // jadi kad pengenalan di atas perlu ditatal semula untuk dilihat.
      await tester.dragUntilVisible(
        find.text('Kertas UPKK sebenar'),
        find.byType(ListView).first,
        const Offset(0, 300),
        maxIteration: 30,
      );
      expect(find.text('Kertas UPKK sebenar'), findsOneWidget);
    });
  });
}
