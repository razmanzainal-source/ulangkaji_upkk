// Ujian fungsi kongsi keputusan.
//
// Fungsi kongsi senang rosak tanpa disedari: butang tetap kelihatan, skrin
// tetap terbuka, tetapi gambar yang sampai ke WhatsApp boleh jadi kosong,
// hitam, atau terpotong separuh. Ujian ini menangkap kad keputusan yang
// **sebenar** dan memeriksa bait PNG yang keluar, supaya kerosakan itu
// ditangkap sebelum ibu bapa terima gambar yang rosak.
//
// Kad juga mesti membawa nama app dan kredit pencipta — penerima gambar di
// WhatsApp tidak melihat app, jadi kredit pada kad ialah satu-satunya jalan
// mereka tahu dari mana keputusan itu datang.
//
// Bunyi dimatikan dalam ujian skrin keputusan: enjin audio tidak wujud dalam
// ujian, dan had masa yang dipasang `Suara` akan kekal sebagai timer yang
// belum selesai — ujian Flutter menggagalkan ujian yang meninggalkan timer.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/gred.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/keputusan_screen.dart';
import 'package:ulangkaji_upkk/screens/kongsi_screen.dart';
import 'package:ulangkaji_upkk/services/kongsi.dart';
import 'package:ulangkaji_upkk/services/tetapan.dart';
import 'package:ulangkaji_upkk/tarikh.dart';
import 'package:ulangkaji_upkk/widgets/kad_keputusan.dart';

import 'bantuan/audio_palsu.dart';

/// PNG 1×1 yang sah — dipakai sebagai gambar tiruan pada skrin kongsi.
final Uint8List _pngKecil = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Satu soalan bertulis mudah — cukup untuk membina kertas ujian.
SoalanKertas _soalan(String id, String bahagian, int nombor, int markah) {
  return SoalanKertas(
    id: id,
    bahagian: bahagian,
    nombor: nombor,
    jenis: JenisKertas.tulis,
    soalan: 'توليس جوافن اندا',
    rumi: 'Tulis jawapan anda',
    markah: markah,
  );
}

/// Kertas dua bahagian yang kecil — hanya untuk menguji paparan keputusan.
Kertas _kertas() {
  return Kertas(
    id: 'uji-percubaan-1',
    subjekId: 'adab',
    tajuk: 'Adab — Percubaan 1',
    sumber: 'Bank soalan Ulangkaji UPKK',
    jenisSumber: 'percubaan',
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: 10,
        arahan: 'توليس جوافن',
        arahanRumi: 'Tulis jawapan',
        soalan: [_soalan('uji-a1', 'A', 1, 5), _soalan('uji-a2', 'A', 2, 5)],
      ),
      BahagianKertas(
        nama: 'B',
        markah: 20,
        arahan: 'توليس جوافن',
        arahanRumi: 'Tulis jawapan',
        soalan: [_soalan('uji-b1', 'B', 1, 10), _soalan('uji-b2', 'B', 2, 10)],
      ),
    ],
  );
}

/// Kad keputusan untuk diuji — markah ditetapkan terus supaya gred dan
/// pujian boleh diperiksa tanpa bergantung pada penanda jawapan.
Widget _kad({int markah = 63, int penuh = 70, int peratus = 90, String? masa}) {
  return KadKeputusan(
    kertas: _kertas(),
    jawapan: const {},
    markah: markah,
    penuh: penuh,
    peratus: peratus,
    gred: Gred.dariPeratus(peratus),
    nama: 'Aisyah',
    tarikh: '19 Oktober 2026',
    masa: masa,
  );
}

/// Kertas penuh 70 markah bertulis — kadnya lebih tinggi daripada skrin telefon.
Kertas _kertasBesar() {
  BahagianKertas bahagian(String nama, int bilangan, int markah) {
    return BahagianKertas(
      nama: nama,
      markah: bilangan * markah,
      arahan: 'توليس جوافن',
      arahanRumi: 'Tulis jawapan',
      soalan: [
        for (var i = 0; i < bilangan; i++)
          _soalan('$nama$i', nama, i + 1, markah),
      ],
    );
  }

  return Kertas(
    id: 'uji-percubaan-besar',
    subjekId: 'adab',
    tajuk: 'Kertas Percubaan Adab',
    sumber: 'Bank soalan Ulangkaji UPKK',
    jenisSumber: 'percubaan',
    bahagian: [
      bahagian('A', 10, 1),
      bahagian('B', 10, 1),
      bahagian('C', 8, 5),
      bahagian('D', 7, 5),
    ],
  );
}

Widget _bingkai(Widget anak) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: anak)),
);

void main() {
  setUpAll(pasangAudioPalsu);

  group('kad keputusan', () {
    testWidgets('memaparkan markah, peratus dan gred', (tester) async {
      await tester.pumpWidget(_bingkai(_kad()));

      expect(find.text('63'), findsOneWidget);
      expect(find.text(' / 70'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Cemerlang'), findsOneWidget);
    });

    testWidgets('membawa nama app dan kredit pencipta', (tester) async {
      await tester.pumpWidget(_bingkai(_kad()));

      expect(find.text('ULANGKAJI UPKK'), findsOneWidget);
      expect(find.textContaining('Razman Zainal'), findsOneWidget);
      expect(find.textContaining('razman.zainal@gmail.com'), findsOneWidget);
      expect(find.textContaining('Adab'), findsWidgets);
    });

    testWidgets('memaparkan jadual markah setiap bahagian', (tester) async {
      await tester.pumpWidget(_bingkai(_kad()));

      expect(find.text('Untuk Kegunaan Pemeriksa'), findsOneWidget);
      // Nombor soalan berterusan merentas bahagian, seperti kertas cetak.
      expect(find.text('Soalan 1–2'), findsOneWidget);
      expect(find.text('Soalan 3–4'), findsOneWidget);

      final bahagianA = find.byKey(const ValueKey('bahagian-A'));
      final bahagianB = find.byKey(const ValueKey('bahagian-B'));
      expect(bahagianA, findsOneWidget);
      expect(bahagianB, findsOneWidget);
      // Jawapan kosong: markah sifar, tetapi penuhnya tetap dipaparkan supaya
      // ibu bapa nampak bentuk kertas sebenar.
      expect(
        find.descendant(of: bahagianA, matching: find.text('0/10')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bahagianB, matching: find.text('0/20')),
        findsOneWidget,
      );
    });

    testWidgets('memaparkan markah setiap soalan', (tester) async {
      await tester.pumpWidget(_bingkai(_kad()));

      expect(find.text('Markah setiap soalan'), findsOneWidget);

      // Empat soalan dalam kertas ujian ini, dinomborkan 1 hingga 4.
      for (var nombor = 1; nombor <= 4; nombor++) {
        final cip = find.byKey(ValueKey('cip-$nombor'));
        expect(cip, findsOneWidget);
        expect(
          find.descendant(of: cip, matching: find.text('$nombor')),
          findsOneWidget,
        );
      }

      // Soalan bertulis boleh mendapat markah separa, jadi pecahannya
      // dipaparkan (0/5 dan 0/10) dan bukan tanda ✓/✗.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cip-1')),
          matching: find.text('0/5'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cip-4')),
          matching: find.text('0/10'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('menukar gred dan namanya mengikut markah', (tester) async {
      await tester.pumpWidget(
        _bingkai(_kad(markah: 14, penuh: 70, peratus: 20)),
      );
      expect(find.text('D'), findsOneWidget);
      expect(find.text('Kurang Memuaskan'), findsOneWidget);

      await tester.pumpWidget(
        _bingkai(_kad(markah: 46, penuh: 70, peratus: 66)),
      );
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Baik'), findsOneWidget);
    });

    testWidgets('memaparkan masa menjawab pada kepala kad', (tester) async {
      await tester.pumpWidget(_bingkai(_kad(masa: '5:28')));
      expect(find.text('Masa 5:28'), findsOneWidget);
    });

    testWidgets('tidak memaparkan masa yang tidak diketahui', (tester) async {
      // Lebih baik tiada maklumat daripada masa yang salah — kad yang dibuka
      // tanpa data masa tidak boleh memaparkan "Masa 0:00" seolah-olah murid
      // menjawab dalam sekelip mata.
      await tester.pumpWidget(_bingkai(_kad()));
      expect(find.textContaining('Masa'), findsNothing);
    });
  });

  group('masa menjawab', () {
    test('dipaparkan dalam minit dan saat, atau jam apabila perlu', () {
      expect(masaTeks(0), '0:00');
      expect(masaTeks(59), '0:59');
      expect(masaTeks(328), '5:28');
      expect(masaTeks(4500), '1:15:00');
    });
  });

  group('penangkapan gambar', () {
    testWidgets('kad ditangkap menjadi PNG yang sah', (tester) async {
      final kunci = GlobalKey();
      await tester.pumpWidget(
        _bingkai(RepaintBoundary(key: kunci, child: _kad())),
      );
      await tester.pump();

      final imej = await tester.runAsync(() => Kongsi.tangkapImej(kunci));

      expect(imej, isNotNull, reason: 'kad gagal ditangkap');
      // Kepala fail PNG: 89 50 4E 47.
      expect(imej!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      // Kad yang benar-benar dilukis jauh lebih besar daripada kepala fail
      // kosong; gambar hitam atau kosong akan jauh lebih kecil.
      expect(imej.length, greaterThan(4000));
    });

    testWidgets('memulangkan null apabila kunci tidak melekat pada kad', (
      tester,
    ) async {
      await tester.pumpWidget(_bingkai(const SizedBox()));
      final imej = await tester.runAsync(() => Kongsi.tangkapImej(GlobalKey()));
      expect(imej, isNull);
    });
  });

  group('kapsyen kongsi', () {
    test('mengandungi tajuk, markah, gred dan nama app', () {
      final teks = Kongsi.kapsyenKeputusan(
        tajuk: 'Adab — Percubaan 1',
        markah: 63,
        penuh: 70,
        peratus: 90,
        gred: Gred.a,
        pecahan: 'Bahagian A 8/10  ·  Bahagian B 55/60',
      );

      expect(teks, contains('Adab — Percubaan 1'));
      expect(teks, contains('63/70'));
      expect(teks, contains('90%'));
      expect(teks, contains('Gred A'));
      expect(teks, contains('Bahagian A 8/10'));
      expect(teks, contains('Ulangkaji UPKK'));
    });

    test('memberi galakan berbeza mengikut markah', () {
      String kapsyen(int peratus) => Kongsi.kapsyenKeputusan(
        tajuk: 'Adab',
        markah: peratus,
        penuh: 100,
        peratus: peratus,
        gred: Gred.dariPeratus(peratus),
      );

      expect(kapsyen(90), contains('Cemerlang'));
      expect(kapsyen(65), contains('Bagus'));
      expect(kapsyen(30), contains('cuba lagi'));
    });

    test('tidak meletakkan nama anak dalam kapsyen', () {
      // Kad keputusan boleh tersebar lebih jauh daripada yang dijangkakan —
      // nama kanak-kanak tidak perlu bersama markahnya.
      final teks = Kongsi.kapsyenKeputusan(
        tajuk: 'Adab',
        markah: 63,
        penuh: 70,
        peratus: 90,
        gred: Gred.a,
      );
      expect(teks, isNot(contains('Aisyah')));
    });
  });

  group('skrin kongsi', () {
    testWidgets('memaparkan gambar dan kapsyen yang akan dihantar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KongsiScreen(
            imej: _pngKecil,
            teks: 'Adab — 63/70 markah (90%), Gred A',
            namaFail: 'keputusan-upkk-adab.png',
            namaSimpan: 'keputusan_upkk_adab',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsWidgets);
      expect(find.text('Kongsi keputusan'), findsOneWidget);
      expect(find.text('Kongsi'), findsOneWidget);
      expect(find.text('Simpan gambar'), findsOneWidget);
      expect(find.textContaining('63/70'), findsOneWidget);
    });
  });

  group('skrin keputusan', () {
    testWidgets('menyediakan butang kongsi', (tester) async {
      // Bunyi dimatikan supaya tiada had masa audio yang tinggal selepas ujian.
      await Tetapan.instance.tetapkanBunyi(false);

      // Skrin keputusan ialah senarai panjang; permukaan ujian dibesarkan
      // supaya butang di hujung senarai itu benar-benar dibina.
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: KeputusanScreen(kertas: _kertas(), jawapan: const {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Kongsi keputusan'), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);

      // Kad perkongsian hanya dilukis di luar skrin semasa gambar disediakan —
      // ia tidak boleh kelihatan semasa skrin biasa dibaca.
      expect(find.byType(KadKeputusan), findsNothing);
    });

    testWidgets('kad kongsi tidak dihadkan kepada tinggi skrin', (
      tester,
    ) async {
      // Bunyi dimatikan supaya tiada had masa audio yang tinggal selepas ujian.
      await Tetapan.instance.tetapkanBunyi(false);
      tester.view.physicalSize = const Size(430, 932) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: KeputusanScreen(
            kertas: _kertasBesar(),
            jawapan: const {},
            saat: 328,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Butang kongsi di bar atas mula melukis kad di luar skrin.
      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pump();

      final kad = find.byType(KadKeputusan);
      expect(kad, findsOneWidget);

      // Kad 35 soalan jauh lebih tinggi daripada skrin 932 pt. Jika kad itu
      // dihadkan kepada tinggi skrin, gambar yang dikongsi terpotong sebelum
      // sampai ke kaki kad — kredit pencipta hilang daripada gambar.
      final saiz = tester.getSize(kad);
      expect(saiz.width, 360);
      expect(saiz.height, greaterThan(932));

      // Biarkan aliran kongsi tamat (penangkapan gambar gagal dalam ujian,
      // dan itu dikendalikan dengan SnackBar).
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
