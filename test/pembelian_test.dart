// Gerbang ibu bapa dan tip sukarela.
//
// Dua jaminan yang dikunci oleh ujian ini:
//  1. Peluang pembelian hanya boleh dicapai di belakang gerbang matematik
//     (Apple Kids Category 1.3, Google Play Families).
//  2. Tiada kandungan dikunci — Percubaan tetap percuma untuk semua.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/screens/ibu_bapa_screen.dart';
import 'package:ulangkaji_upkk/services/pembelian.dart';
import 'package:ulangkaji_upkk/tema.dart';

Widget _balut(Widget anak) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: anak,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Pembelian.instance.lupakan();
  });

  testWidgets('gerbang ibu bapa muncul sebelum tip', (tester) async {
    await tester.pumpWidget(_balut(const IbuBapaScreen()));
    await tester.pump();

    expect(find.text('Kawasan khas ibu bapa'), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-tip_5')), findsNothing);
  });

  testWidgets('jawapan salah tidak membuka pilihan tip', (tester) async {
    await tester.pumpWidget(_balut(const IbuBapaScreen()));
    await tester.pump();

    await tester.enterText(
        find.byKey(const ValueKey('gerbang-jawapan')), '1');
    await tester.tap(find.byKey(const ValueKey('gerbang-teruskan')));
    await tester.pump();

    expect(find.text('Jawapan tidak tepat. Cuba lagi.'), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-tip_5')), findsNothing);
  });

  testWidgets('jawapan betul membuka tiga pilihan tip', (tester) async {
    await tester.pumpWidget(_balut(const IbuBapaScreen()));
    await tester.pump();

    final teks = tester
        .widgetList<Text>(find.textContaining('Berapakah'))
        .first
        .data!;
    final m = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(teks)!;
    final jawapan =
        (int.parse(m.group(1)!) + int.parse(m.group(2)!)).toString();

    await tester.enterText(
        find.byKey(const ValueKey('gerbang-jawapan')), jawapan);
    await tester.tap(find.byKey(const ValueKey('gerbang-teruskan')));
    // Maskot berdenyut tanpa henti — `pumpAndSettle` tidak boleh dipakai.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sokongan Sukarela'), findsOneWidget);
    for (final tier in Pembelian.tierTip) {
      expect(find.byKey(ValueKey('tip-$tier')), findsOneWidget);
    }
    // Tiada butang "pulihkan" — tip bukan pembelian kandungan.
    expect(find.text('Tip tidak membuka atau mengunci apa-apa. Semua soalan, '
        'kertas dan suara bacaan tetap percuma untuk semua orang.'),
        findsOneWidget);
  });

  test('tier tip ialah RM3 / RM5 / RM10', () {
    expect(Pembelian.tierTip, [3, 5, 10]);
  });

  test('ID produk mengikut gaya bundle app Wira Kira, dengan sandaran lama', () {
    // ID gaya bundle diutamakan; ID lama kekal supaya app terus berfungsi
    // jika produk baru belum dicipta di kedai.
    expect(Pembelian.semuaId, contains('com.razmanzainal.ulangkajiUpkk.tip3'));
    expect(Pembelian.semuaId, contains('com.razmanzainal.ulangkajiUpkk.tip5'));
    expect(Pembelian.semuaId, contains('com.razmanzainal.ulangkajiUpkk.tip10'));
    expect(Pembelian.semuaId, contains('tip_5'));
    expect(Pembelian.semuaId.length, 6);
  });

  test('tiada gerbang pembelian pada Percubaan atau Kertas', () {
    // Ciri yang pernah percuma tidak boleh dikunci semula tanpa keputusan
    // perniagaan yang jelas. Ujian ini mengunci keputusan itu.
    for (final fail in [
      'lib/screens/pilih_subjek_screen.dart',
      'lib/screens/kertas_sebenar_screen.dart',
    ]) {
      final isi = File(fail).readAsStringSync();
      expect(isi.contains('pastikanVersiPenuh'), isFalse, reason: fail);
      expect(isi.contains('IbuBapaScreen'), isFalse, reason: fail);
    }
  });

  test('warna tema tersedia untuk skrin tip', () {
    expect(Warna.utama, isNotNull);
  });
}
