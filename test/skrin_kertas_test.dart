// Ujian paparan muka kertas percubaan bagi **kesemua** subjek.
//
// Ujian penjana (`jana_kertas_test.dart`) membuktikan kertas yang dijana
// berjumlah 70 markah dan tidak mengulang soalan. Ujian ini membawa perkara itu
// satu langkah lebih jauh: ia benar-benar membuka setiap soalan dalam kertas itu
// pada skrin, satu demi satu, dan memastikan setiap muka boleh dilukis.
//
// Sebabnya mudah: kertas boleh betul pada kertas (maafkan permainan kata) tetapi
// skrinnya rosak — jenis soalan yang belum pernah dijana, papan jawapan yang
// tidak dikenali, atau label yang tersalah kira. Murid tidak akan melaporkan
// "widget gagal dibina"; dia hanya akan berhenti menjawab.
//
// Peraturan Rumi juga dikunci di sini untuk setiap subjek: kertas percubaan
// menanggalkan Rumi, kerana kertas UPKK sebenar 100% Jawi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/screens/kertas_screen.dart';
import 'package:ulangkaji_upkk/services/jana_kertas.dart';
import 'package:ulangkaji_upkk/widgets/butang_pilihan.dart';
import 'package:ulangkaji_upkk/widgets/papan_betul_salah.dart';
import 'package:ulangkaji_upkk/widgets/papan_padan.dart';
import 'package:ulangkaji_upkk/widgets/papan_susun.dart';
import 'package:ulangkaji_upkk/widgets/papan_taip.dart';
import 'package:ulangkaji_upkk/widgets/papan_tempat_kosong.dart';

import 'bantuan/audio_palsu.dart';
import 'bantuan/saiz_telefon.dart';

/// Laluan akar projek — ujian berjalan dari akar projek.
const String _akar = '.';

Subjek _bacaSubjek(String id) {
  final data = jsonDecode(
    File('$_akar/assets/content/subjek.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final senarai = (data['subjek'] as List).cast<Map<String, dynamic>>();
  return Subjek.dariJson(senarai.firstWhere((s) => s['id'] == id));
}

List<SoalanKertas> _bacaBank(String id) {
  final data = jsonDecode(
    File('$_akar/assets/content/bank/$id.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (data['soalan'] as List)
      .cast<Map<String, dynamic>>()
      .asMap()
      .entries
      .map(
        (e) => SoalanKertas.dariJson(
          e.value,
          bahagian: (e.value['bahagian'] as String?) ?? '',
          nombor: e.key + 1,
        ),
      )
      .toList();
}

/// Semua subjek yang banknya sudah ada dalam projek.
List<String> _subjekAdaBank() {
  final data = jsonDecode(
    File('$_akar/assets/content/subjek.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final semua = (data['subjek'] as List).cast<Map<String, dynamic>>().map(
    (s) => s['id'] as String,
  );
  return [
    for (final id in semua)
      if (File('$_akar/assets/content/bank/$id.json').existsSync()) id,
  ];
}

/// Papan jawapan yang mesti muncul untuk setiap jenis soalan.
///
/// Kalau satu jenis soalan tiada papan, soalan itu tidak boleh dijawab langsung.
Type _papan(JenisKertas jenis) => switch (jenis) {
  JenisKertas.bulat || JenisKertas.objektif => ButangPilihan,
  JenisKertas.betulSalah => PapanBetulSalah,
  JenisKertas.suai => PapanPadan,
  JenisKertas.susun => PapanSusun,
  JenisKertas.tempatKosong => PapanTempatKosong,
  JenisKertas.tulis || JenisKertas.huraian => PapanTaip,
};

/// Lepaskan widget supaya pemasa kertas dan pemasa audio berhenti.
///
/// Timer yang masih hidup semasa ujian tamat menggagalkan ujian, walaupun app
/// berkelakuan betul — jadi masa dimajukan sehingga semua had tamat.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

Future<void> _buka(WidgetTester tester, Kertas kertas) async {
  gunaSaizTelefon(tester);
  await tester.pumpWidget(MaterialApp(home: KertasScreen(kertas: kertas)));
  await tester.pump();
}

void main() {
  setUpAll(pasangAudioPalsu);

  for (final id in _subjekAdaBank()) {
    final subjek = _bacaSubjek(id);
    final bank = _bacaBank(id);

    testWidgets('$id: kulit kertas percubaan menunjukkan format rasmi', (
      tester,
    ) async {
      final kertas = JanaKertas.percubaan(
        subjek: subjek,
        bank: bank,
        giliran: 0,
      );
      await _buka(tester, kertas);

      expect(find.text('Mula menjawab'), findsOneWidget);
      // Kertas percubaan memperingatkan masa bermula; latih tubi tidak.
      expect(
        find.textContaining('Bersedia?'),
        findsOneWidget,
        reason: 'kulit kertas percubaan patut menyebut masa menjawab',
      );

      // Jadual bahagian berada di hujung kulit kertas, dan kulit kertas ialah
      // `ListView` — anak yang jauh di bawah belum dibina, jadi ia perlu
      // digulung masuk dahulu.
      await tester.dragUntilVisible(
        find.text('Bahagian kertas ini'),
        find.byType(ListView).first,
        const Offset(0, -260),
        maxIteration: 30,
      );

      // Jadual bahagian pada kulit kertas mesti menepati kertas yang dijana.
      // (Dua bahagian boleh berkongsi bilangan atau markah yang sama, jadi
      // setiap teks dituntut sekurang-kurangnya sekali, bukan sekali sahaja.)
      for (final b in kertas.bahagian) {
        expect(
          find.text('${b.soalan.length} soalan'),
          findsWidgets,
          reason: 'bahagian ${b.nama}',
        );
        expect(
          find.text('${b.markah} markah'),
          findsWidgets,
          reason: 'bahagian ${b.nama}',
        );
      }

      // Kertas UPKK sebenar bernilai 70 markah. Kulit kertas mesti menunjukkan
      // jumlah yang sama, bukan jumlah yang diteka.
      final jumlah = kertas.bahagian.fold<int>(
        0,
        (a, b) => a + b.markahTersedia,
      );
      expect(jumlah, 70, reason: 'kertas $id bernilai $jumlah markah');

      await _tutup(tester);
    });

    testWidgets('$id: setiap soalan percubaan boleh dibuka', (tester) async {
      final kertas = JanaKertas.percubaan(
        subjek: subjek,
        bank: bank,
        giliran: 0,
      );
      final semua = kertas.semuaSoalan;

      await _buka(tester, kertas);
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      // Soalan terakhir pun berlubang "Seterusnya" — halaman semakan hanya
      // muncul selepas ditekan, dan "Hantar kertas" hanya ada di situ.
      var muka = 0;
      while (find.text('Seterusnya').evaluate().isNotEmpty) {
        final s = semua[muka];

        expect(
          find.text('Soalan ${muka + 1} daripada ${semua.length}'),
          findsOneWidget,
          reason: 'label bar atas pada muka ${muka + 1}',
        );
        expect(
          find.byType(_papan(s.jenis)),
          findsWidgets,
          reason: '${s.id} (jenis ${s.jenis}) tiada papan jawapan',
        );
        // Kertas sebenar 100% Jawi: baris Rumi soalan ditanggalkan.
        expect(
          find.text(s.rumi),
          findsNothing,
          reason: '${s.id} masih memaparkan Rumi',
        );

        await tester.tap(find.text('Seterusnya'));
        await tester.pump();
        muka++;
        expect(
          muka,
          lessThanOrEqualTo(semua.length),
          reason: 'kertas tidak tamat',
        );
      }

      expect(
        muka,
        semua.length,
        reason: 'hanya $muka daripada ${semua.length} soalan boleh dibuka',
      );
      expect(find.text('Semak jawapan'), findsWidgets);
      expect(find.text('Hantar kertas'), findsOneWidget);

      await _tutup(tester);
    });
  }

  testWidgets('butang Sebelum dan Seterusnya sama lebar pada telefon kecil', (
    tester,
  ) async {
    final id = _subjekAdaBank().first;
    final kertas = JanaKertas.percubaan(
      subjek: _bacaSubjek(id),
      bank: _bacaBank(id),
    );

    await _buka(tester, kertas);
    await tester.tap(find.text('Mula menjawab'));
    await tester.pump();

    for (final saiz in const [Size(430, 932), Size(360, 740)]) {
      tester.view.physicalSize = saiz * 3;
      tester.view.devicePixelRatio = 3;
      await tester.pump();

      final sebelum = tester.getSize(
        find.widgetWithText(OutlinedButton, 'Sebelum'),
      );
      final seterusnya = tester.getSize(
        find.widgetWithText(FilledButton, 'Seterusnya'),
      );

      expect(
        sebelum.width,
        closeTo(seterusnya.width, 0.5),
        reason: 'butang tidak sama lebar pada skrin ${saiz.width}',
      );
      expect(sebelum.height, seterusnya.height);

      // Label mesti satu baris: "Sebelum" tidak boleh terpotong jadi
      // "Sebelu/m" pada telefon sempit.
      final label = tester.widget<Text>(find.text('Sebelum'));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
    }

    await _tutup(tester);
  });
}
