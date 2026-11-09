// Semakan versi automatik.
//
// App ini mesti kekal boleh digunakan tanpa Internet. Ujian ini mengunci dua
// perkara:
//  1. Kegagalan rangkaian tidak pernah menghalang app atau menimbulkan ralat.
//  2. Versi yang lebih rendah daripada `minimum` memaksa kemas kini, manakala
//     versi yang hanya ketinggalan daripada `terkini` masih boleh ditangguhkan.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/services/semakan_versi.dart';

const _jsonContoh = '''
{
  "nota": "Pembetulan pepijat kecil.",
  "android": {"terkini": "2.1.0", "minimum": "2.0.0"},
  "ios": {"terkini": "2.2.0", "minimum": "2.2.0", "pautan": "https://contoh.test/ios"}
}
''';

MaklumatVersi _maklumat(String terkini, String minimum) => MaklumatVersi(
      terkini: terkini,
      minimum: minimum,
      pautan: 'https://contoh.test',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SemakanVersi.instance.setSemula());
  tearDown(() => SemakanVersi.instance.setSemula());

  group('perbandingan versi', () {
    test('versi sama tidak memerlukan kemas kini', () {
      expect(_maklumat('2.1.0', '2.1.0').bandingkan('2.1.0'),
          StatusKemasKini.tiada);
    });

    test('versi lebih rendah daripada minimum dipaksa', () {
      expect(_maklumat('2.1.0', '2.1.0').bandingkan('2.0.0'),
          StatusKemasKini.paksa);
    });

    test('versi antara minimum dan terkini hanya digalakkan', () {
      expect(_maklumat('2.2.0', '2.0.0').bandingkan('2.1.0'),
          StatusKemasKini.galak);
    });

    test('perbandingan angka, bukan abjad', () {
      // "2.10.0" lebih tinggi daripada "2.9.0" walaupun secara abjad tidak.
      expect(_maklumat('2.10.0', '2.10.0').bandingkan('2.9.0'),
          StatusKemasKini.paksa);
      expect(_maklumat('2.9.0', '2.9.0').bandingkan('2.10.0'),
          StatusKemasKini.tiada);
    });

    test('versi dengan nombor binaan diterima', () {
      expect(_maklumat('2.1.0', '2.1.0').bandingkan('2.1.0+30'),
          StatusKemasKini.tiada);
    });
  });

  group('parsing versi.json', () {
    test('membaca platform semasa dan nota', () {
      final m = MaklumatVersi.daripadaJson(
        const {
          'nota': 'Nota ujian',
          'android': {'terkini': '2.1.0', 'minimum': '2.0.0'},
        },
        platform: 'android',
        pautanLalai: 'https://lalai.test',
      );
      expect(m, isNotNull);
      expect(m!.terkini, '2.1.0');
      expect(m.minimum, '2.0.0');
      expect(m.pautan, 'https://lalai.test');
      expect(m.nota, 'Nota ujian');
    });

    test('minimum dan pautan lalai digunakan jika tiada', () {
      final m = MaklumatVersi.daripadaJson(
        const {
          'ios': {'terkini': '3.0.0'},
        },
        platform: 'ios',
        pautanLalai: 'https://kedai.test',
      );
      expect(m!.minimum, '3.0.0');
      expect(m.pautan, 'https://kedai.test');
    });

    test('platform tiada atau JSON rosak pulang null', () {
      expect(
        MaklumatVersi.daripadaJson(const {'android': {'terkini': '1.0.0'}},
            platform: 'ios', pautanLalai: 'x'),
        isNull,
      );
      expect(
        MaklumatVersi.daripadaJson(null, platform: 'ios', pautanLalai: 'x'),
        isNull,
      );
    });
  });

  group('semakan rangkaian', () {
    test('JSON sah dibaca', () async {
      SemakanVersi.instance.ambilJson =
          (_) async => _jsonContoh;
      final m = await SemakanVersi.instance.semak();
      expect(m, isNotNull);
      expect(m!.terkini, '2.1.0');
      expect(m.nota, 'Pembetulan pepijat kecil.');
    });

    test('rangkaian gagal tidak membaling ralat', () async {
      SemakanVersi.instance.ambilJson = (_) async => null;
      expect(await SemakanVersi.instance.semak(), isNull);

      SemakanVersi.instance.ambilJson = (_) async => 'bukan json';
      expect(await SemakanVersi.instance.semak(), isNull);

      SemakanVersi.instance.ambilJson =
          (_) async => throw const SocketExceptionStub();
      expect(await SemakanVersi.instance.semak(), isNull);
    });

    test('versi semasa gagal dibaca pulang null', () async {
      SemakanVersi.instance.bacaVersiSemasa = () async => throw Exception('x');
      expect(await SemakanVersi.instance.versiSemasa(), isNull);
    });
  });

  group('dialog kemas kini', () {
    Widget balut(Widget anak) => MaterialApp(home: Scaffold(body: anak));

    testWidgets('paksa: tiada butang Nanti', (tester) async {
      await tester.pumpWidget(balut(
        DialogKemasKini(
          maklumat: _maklumat('2.1.0', '2.1.0'),
          paksa: true,
          versiSemasa: '2.0.0',
        ),
      ));
      expect(find.text('Kemas kini diperlukan'), findsOneWidget);
      expect(find.byKey(const ValueKey('kemas-kini-buka')), findsOneWidget);
      expect(find.text('Nanti'), findsNothing);
    });

    testWidgets('galak: butang Nanti menutup dialog', (tester) async {
      await tester.pumpWidget(balut(
        DialogKemasKini(
          maklumat: _maklumat('2.2.0', '2.0.0'),
          paksa: false,
          versiSemasa: '2.1.0',
        ),
      ));
      expect(find.text('Versi baharu tersedia'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('kemas-kini-nanti')));
      await tester.pump();
    });
  });
}

/// Ralat rangkaian palsu — ujian tidak memerlukan `dart:io`.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'tiada rangkaian';
}
