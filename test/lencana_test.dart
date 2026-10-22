// Ujian lencana pencapaian —hierarki markah dan lencana global.
//
// Dua perkara yang dikunci di sini:
//
//   1. Lencana diperoleh daripada **markah terbaik** satu subjek, bukan
//      daripada kertas terakhir. Murid yang mencapai 85% sekali sahaja sudah
//      layak untuk lencana Perak — walaupun kertas seterusnya lebih lemah.
//      Lencana yang hilang akan mengajar dia bahawa lencana itu bukan milik
//      dia.
//
//   2. Lencana **tidak hilang**. Satu jawapan salah tidak boleh
//      membuang lencana yang sudah diperoleh.
//
// Latih tubi (sepuluh soalan) tidak boleh memberikan lencana markah —
// nilainya tidak boleh dibandingkan dengan kertas 70 markah.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulangkaji_upkk/models/lencana.dart';
import 'package:ulangkaji_upkk/services/kemajuan.dart';

RekodPercubaan _rekod({
  required int markah,
  int penuh = 70,
  bool latihan = false,
  String subjekId = 'adab',
  DateTime? tarikh,
}) {
  return RekodPercubaan(
    tarikh: tarikh ?? DateTime.now(),
    subjekId: subjekId,
    kertasId: 'kertas-uji',
    tajuk: 'Kertas Ujian',
    markah: markah,
    markahPenuh: penuh,
    saat: 600,
    latihan: latihan,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Kemajuan.instance.muat();
    await Kemajuan.instance.padamSemua();
  });

  group('hierarki lencana markah', () {
    test('peratus menentukan lencana yang layak', () {
      expect(Kemajuan.tahapLayak(0), isEmpty);
      expect(Kemajuan.tahapLayak(69), isEmpty);
      expect(
        Kemajuan.tahapLayak(70).map((t) => t.tajuk),
        ['Gangsa'],
      );
      expect(
        Kemajuan.tahapLayak(85).map((t) => t.tajuk),
        ['Gangsa', 'Perak'],
      );
      expect(
        Kemajuan.tahapLayak(90).map((t) => t.tajuk),
        ['Gangsa', 'Perak', 'Emas'],
      );
      // akan mengajar murid bahawa ia bukan milik dia.
      // akan teaching murid bahawa ia bukan milik dia.
      expect(
        Kemajuan.tahapLayak(94).map((t) => t.tajuk),
        ['Gangsa', 'Perak', 'Emas'],
      );
      expect(
        Kemajuan.tahapLayak(95).map((t) => t.tajuk),
        ['Gangsa', 'Perak', 'Emas', 'Sempurna'],
      );
      expect(
        Kemajuan.tahapLayak(100).map((t) => t.tajuk),
        ['Gangsa', 'Perak', 'Emas', 'Sempurna'],
      );
    });

    test('kertas 95% memberikan lencana Sempurna', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 67)); // 95%

      final baru = await Kemajuan.instance.semakLencana();

      expect(baru.map((l) => l.tajuk), contains('Sempurna'));
      expect(Kemajuan.instance.adaLencana(
        DaftarLencana.kunciSubjek('adab', TahapLencana.sempurna),
      ), isTrue);
    });

    test('kertas 85% memberikan lencana Gangsa dan Perak', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 60)); // 85%

      final baru = await Kemajuan.instance.semakLencana();

      expect(
        baru.map((l) => l.tajuk),
        containsAll(['Gangsa', 'Perak']),
      );
      expect(Kemajuan.instance.adaLencana(
        DaftarLencana.kunciSubjek('adab', TahapLencana.gangsa),
      ), isTrue);
      expect(Kemajuan.instance.adaLencana(
        DaftarLencana.kunciSubjek('adab', TahapLencana.emas),
      ), isFalse);
    });

    test('lencana tidak hilang apabila markah kemudian turun', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 60)); // 85%
      await Kemajuan.instance.semakLencana();

      // Kertas seterusnya jauh lebih lemah.
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 20)); // 28%
      await Kemajuan.instance.semakLencana();

      expect(Kemajuan.instance.adaLencana(
        DaftarLencana.kunciSubjek('adab', TahapLencana.perak),
      ), isTrue);
    });

    test('lencana yang sama tidak diumumkan dua kali', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 60)); // 85%

      final pertama = await Kemajuan.instance.semakLencana();
      final kedua = await Kemajuan.instance.semakLencana();

      expect(pertama, isNotEmpty);
      expect(kedua, isEmpty);
    });

    test('latih tubi tidak memberikan lencana markah', () async {
      await Kemajuan.instance.simpanPercubaan(
        _rekod(markah: 10, penuh: 10, latihan: true),
      );

      final baru = await Kemajuan.instance.semakLencana();

      // Lencana global mungkin diperoleh (contoh "Kilat"), tetapi **markah**
      // tidak boleh — latih tubi 10/10 bukan 100% daripada 70 markah.
      for (final l in baru) {
        expect(l.peratus, isNull, reason: 'lencana markah diperoleh: ${l.tajuk}');
      }
      expect(Kemajuan.instance.adaLencana(
        DaftarLencana.kunciSubjek('adab', TahapLencana.sempurna),
      ), isFalse);
    });

    test('kunci lencana setiap subjek dan tahap adalah unik', () {
      final kunci = <String>{};
      for (final s in ['adab', 'akidah', 'arab', 'ibadah', 'jawi', 'sirah']) {
        for (final t in TahapLencana.values) {
          final k = DaftarLencana.kunciSubjek(s, t);
          expect(kunci.add(k), isTrue, reason: 'kunci berulang: $k');
        }
      }
      expect(kunci.length, 6 * TahapLencana.values.length);
    });
  });

  group('lencana global', () {
    test('rentetan sepuluh jawapan betul memberikan lencana Kilat', () async {
      await Kemajuan.instance.catatRentetan(10);
      final baru = await Kemajuan.instance.semakLencana();
      expect(baru.map((l) => l.id), contains('g-kilat'));
    });

    test('rentetan di bawah sepuluh tidak memberikan lencana Kilat', () async {
      await Kemajuan.instance.catatRentetan(9);
      final baru = await Kemajuan.instance.semakLencana();
      expect(baru.map((l) => l.id), isNot(contains('g-kilat')));
    });

    test('rekod rentetan hanya naik', () async {
      await Kemajuan.instance.catatRentetan(12);
      await Kemajuan.instance.catatRentetan(3);
      expect(Kemajuan.instance.rentetanTerpanjang, 12);
    });

    test('tiga kertas 70% berturut-turut memberikan lencana Konsisten',
        () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 49)); // 70%
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 49));
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 49));
      final baru = await Kemajuan.instance.semakLencana();
      expect(baru.map((l) => l.id), contains('g-konsisten'));
    });

    test('tiga hari berturut-turut memberikan lencana Rajin', () async {
      final hariIni = DateTime.now();
      for (var i = 0; i < 7; i++) {
        await Kemajuan.instance.simpanPercubaan(
          _rekod(markah: 10, tarikh: hariIni.subtract(Duration(days: i))),
        );
      }
      final baru = await Kemajuan.instance.semakLencana();
      expect(baru.map((l) => l.id), contains('g-rajin'));
    });
  });

  group('rekod jawapan', () {
    test('jumlah jawapan betul hanya membesar', () async {
      await Kemajuan.instance.tambahBetul(12);
      await Kemajuan.instance.tambahBetul(5);
      expect(Kemajuan.instance.jumlahBetul, 17);
    });

    test('bilangan kertas sempurna dikira betul', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 70)); // 100%
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 60));
      expect(Kemajuan.instance.kertasSempurna, 1);
    });

    test('padam rekod turut menghapus lencana dan rekod jawapan', () async {
      await Kemajuan.instance.simpanPercubaan(_rekod(markah: 60));
      await Kemajuan.instance.semakLencana();
      await Kemajuan.instance.tambahBetul(9);
      await Kemajuan.instance.catatRentetan(5);

      await Kemajuan.instance.padamSemua();

      expect(Kemajuan.instance.lencanaDiperoleh, isEmpty);
      expect(Kemajuan.instance.jumlahBetul, 0);
      expect(Kemajuan.instance.rentetanTerpanjang, 0);
    });
  });
}
