// Ujian **latih tubi** sebagai modul latihan — bukan kertas percubaan.
//
// Empat peraturan dikunci di sini kerana semuanya mudah hilang semasa kod
// lain diubah, dan semuanya mengubah pengalaman murid:
//
//   * latih tubi boleh **ditinggalkan bila-bila masa** tanpa dialog "Keluar
//     kertas?" — ia bukan kertas, jadi tiada jawapan yang "hilang";
//   * latihan yang tamat berakhir pada skrin **tanpa markah, peratus atau
//     gred** — menanda latihan menjadikan latihan terasa seperti ujian;
//   * setiap pilihan jawapan ada **butang speaker**, dan bunyinya hanya
//     bermula apabila butang itu ditekan (memilih jawapan tidak berbunyi);
//   * kertas percubaan **tiada** butang speaker langsung: kertas sebenar tidak
//     membacakan soalan atau pilihan kepada murid.
//
// Ujian tidak boleh mendengar audio, jadi ia memeriksa niat yang direkod oleh
// `Suara.ayatTerakhir`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/models/rubrik.dart';
import 'package:ulangkaji_upkk/screens/kertas_screen.dart';
import 'package:ulangkaji_upkk/screens/latihan_selesai_screen.dart';
import 'package:ulangkaji_upkk/services/suara.dart';
import 'package:ulangkaji_upkk/widgets/butang_pilihan.dart';
import 'package:ulangkaji_upkk/widgets/papan_taip.dart';

import 'bantuan/audio_palsu.dart';
import 'bantuan/saiz_telefon.dart';

/// Kertas dua soalan; pilihan pertama setiap soalan ialah jawapan betul.
///
/// [jenisSumber] menentukan mod: `latihan` (latih tubi) atau `percubaan`.
Kertas _kertas({required String jenisSumber, int bilangan = 2}) {
  return Kertas(
    id: 'uji-latihan',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'A',
        markah: bilangan * 5,
        arahan: 'بولا تکن جوافن',
        arahanRumi: 'Bulatkan jawapan',
        soalan: [
          for (var i = 0; i < bilangan; i++)
            SoalanKertas(
              id: 'uji-a${i + 1}',
              bahagian: 'A',
              nombor: i + 1,
              jenis: JenisKertas.bulat,
              soalan: 'سأبارا فدوق؟',
              rumi: 'Sabara paduk?',
              markah: 5,
              item: [
                ItemKertas(
                  nombor: 1,
                  teks: 'سأبارا',
                  rumi: 'Sabara',
                  pilihan: const ['ساتو', 'دوا'],
                  pilihanRumi: const ['satu', 'dua'],
                  jawapan: 0,
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

/// Kertas satu soalan **bertulis** — untuk menguji panel pembetulan dan
/// butang speaker jawapan contoh.
///
/// Soalan `tulis` dengan jawapan contoh tiga baris, meniru soalan senarai
/// UPKK seperti "Nyatakan lima adab terhadap Allah".
Kertas _kertasTulis({required String jenisSumber}) {
  return Kertas(
    id: 'uji-tulis',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'C',
        markah: 3,
        arahan: 'سنارايکن تيچ ادب',
        arahanRumi: 'Senaraikan tiga adab',
        soalan: [
          SoalanKertas(
            id: 'uji-c1',
            bahagian: 'C',
            nombor: 1,
            jenis: JenisKertas.tulis,
            soalan: 'سنارايکن تيچ ادب ترهادڤ الله.',
            rumi: 'Senaraikan tiga adab terhadap Allah.',
            markah: 3,
            jawapanContoh: const ['ساتو', 'دوا', 'تيچ'],
            jawapanContohRumi: const ['satu', 'dua', 'tiga'],
          ),
        ],
      ),
    ],
  );
}

/// Kertas latihan dengan satu soalan `tulis` yang rubriknya mempunyai **tiga
/// isi**.
///
/// Kertas asal memberi satu ruang bernombor bagi setiap isi yang diminta, jadi
/// app turut memaparkan tiga kotak bernombor. `_kertasTulis` di atas tiada
/// rubrik, jadi ia kekal satu kotak besar — kedua-dua bentuk mesti diuji.
Kertas _kertasTulisIsi({
  required String jenisSumber,
  JenisKertas jenis = JenisKertas.tulis,
}) {
  return Kertas(
    id: 'uji-tulis-isi',
    subjekId: 'adab',
    tajuk: 'Adab — Ujian',
    sumber: 'Ujian',
    jenisSumber: jenisSumber,
    bahagian: [
      BahagianKertas(
        nama: 'C',
        markah: 3,
        arahan: 'سنارايکن تيچ ادب',
        arahanRumi: 'Senaraikan tiga adab',
        soalan: [
          SoalanKertas(
            id: 'uji-c1i',
            bahagian: 'C',
            nombor: 1,
            jenis: jenis,
            soalan: 'سنارايکن تيچ ادب ترهادڤ الله.',
            rumi: 'Senaraikan tiga adab terhadap Allah.',
            markah: 3,
            rubrik: const Rubrik([
              Idea(maksud: 'Isi satu', kata: ['ز']),
              Idea(maksud: 'Isi dua', kata: ['س']),
              Idea(maksud: 'Isi tiga', kata: ['ق']),
            ]),
            jawapanContoh: const ['ساتو', 'دوا', 'تيچ'],
            jawapanContohRumi: const ['satu', 'dua', 'tiga'],
          ),
        ],
      ),
    ],
  );
}

/// Lepaskan widget supaya pemasa kertas dan pemasa audio berhenti.
Future<void> _tutup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

/// Buka kertas sebagai **laluan baharu** di atas skrin lain.
///
/// Laluan diperlukan untuk menguji butang kembali: tanpa halaman di bawahnya,
/// `pageBack` tiada tempat untuk pulang.
Future<void> _bukaSebagaiLaluan(WidgetTester tester, Kertas kertas) async {
  gunaSaizTelefon(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (konteks) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(konteks).push(
                MaterialPageRoute<void>(
                  builder: (_) => KertasScreen(kertas: kertas),
                ),
              ),
              child: const Text('buka kertas'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka kertas'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Tekan "Mula menjawab", jawab soalan pertama dengan pilihan [pilihan].
Future<void> _jawabSatu(WidgetTester tester, {int pilihan = 0}) async {
  await tester.tap(find.text('Mula menjawab'));
  await tester.pump();
  await tester.tap(find.byType(ButangPilihan).at(pilihan));
  await tester.pump();
}

void main() {
  setUpAll(pasangAudioPalsu);

  setUp(() {
    Suara.instance.ayatTerakhir = null;
    Suara.instance.kesanTerakhir = null;
    Suara.instance.berhentiDipanggil = false;
  });

  group('keluar', () {
    testWidgets('latih tubi boleh ditinggalkan tanpa dialog', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));

      // Latih tubi memaparkan butang X, bukan anak panah kembali: ia bukan
      // kertas yang perlu dihantar. Satu ketukan terus keluar.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      // Animasi keluar laluan (300 ms) perlu beberapa bingkai sebelum widget
      // benar-benar ditanggalkan daripada pokok.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(
        find.text('Keluar kertas?'),
        findsNothing,
        reason: 'latih tubi bukan kertas — tiada apa yang perlu disahkan',
      );
      expect(
        find.byType(KertasScreen),
        findsNothing,
        reason: 'skrin latihan sepatutnya terus tertutup',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan masih bertanya sebelum keluar', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Keluar kertas?'),
        findsOneWidget,
        reason: 'jawapan kertas percubaan yang separuh siap akan hilang',
      );
      await _tutup(tester);
    });

    testWidgets('latih tubi ada butang tutup di bar atas', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await _tutup(tester);
    });
  });

  group('tamat latihan', () {
    testWidgets('butang terakhir ialah "Selesai", bukan "Hantar kertas"', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Hantar kertas'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('"Selesai" membuka penutup latihan tanpa markah atau gred', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      // Soalan kedua dijawab **salah** supaya skrin penutup ada dua nombor.
      await tester.tap(find.byType(ButangPilihan).at(1));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Hantar kertas?'),
        findsNothing,
        reason: 'latihan tidak sepatutnya meminta pengesahan seperti kertas',
      );
      expect(find.byType(LatihanSelesaiScreen), findsOneWidget);
      expect(find.text('1 daripada 2 soalan betul'), findsOneWidget);

      // Tiada markah, tiada peratus, tiada cop gred, tiada kad kongsi.
      expect(find.text('GRED'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Kongsi keputusan'), findsNothing);
      expect(find.text('Keputusan'), findsNothing);
      expect(find.textContaining('daripada 70 markah'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('skrin penutup menyenaraikan soalan untuk diulang', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(1));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Soalan untuk diulang'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      await _tutup(tester);
    });

    testWidgets('keputusan sederhana (50%): ayat sederhana, tiada "Syabas"', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      // Soalan kedua dijawab salah — 1 daripada 2 = 50%, bawah ambang syabas.
      await tester.tap(find.byType(ButangPilihan).at(1));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      // Padam rekod bunyi daripada jawab soalan supaya hanya bunyi penutup
      // yang dinilai di sini.
      Suara.instance.ayatTerakhir = null;

      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Tajuk kad mesti sama dengan ayat pertama bunyi penutup. (Bar skrin
      // turut menulis "Latihan selesai" — diperiksa pada kad sahaja.)
      expect(find.text('Latihan selesai!'), findsOneWidget);
      expect(
        find.textContaining('Syabas'),
        findsNothing,
        reason: 'keputusan yang banyak salah tidak layak mendapat "Syabas"',
      );

      for (var i = 0; i < 30 && Suara.instance.ayatTerakhir == null; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(Suara.instance.ayatTerakhir, Suara.kunciLatihanSederhana);
      // Tiada fanfar di atas markah yang banyak salah.
      expect(Suara.instance.kesanTerakhir, isNot(Suara.kesanHebat));
      await _tutup(tester);
    });

    testWidgets('keputusan lemah: ajakan ulang kaji, bukan "Syabas"', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester, pilihan: 1); // salah
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(1)); // salah
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      Suara.instance.ayatTerakhir = null;
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Syabas'), findsNothing);
      // Tajuk kad sepadan dengan ayat pertama bunyi penutup.
      expect(find.text('Latihan selesai!'), findsOneWidget);

      for (var i = 0; i < 30 && Suara.instance.ayatTerakhir == null; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(Suara.instance.ayatTerakhir, Suara.kunciLatihanUlang);
      expect(Suara.instance.kesanTerakhir, isNot(Suara.kesanHebat));
      await _tutup(tester);
    });

    testWidgets('semua betul (100%): "Syabas" + fanfar', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await tester.tap(find.byType(ButangPilihan).at(0)); // betul
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      Suara.instance.ayatTerakhir = null;
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Syabas'), findsOneWidget);
      expect(Suara.instance.kesanTerakhir, Suara.kesanHebat);

      for (var i = 0; i < 30 && Suara.instance.ayatTerakhir == null; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(Suara.instance.ayatTerakhir, Suara.kunciLatihanSelesai);
      await _tutup(tester);
    });

    testWidgets('ayat penutup tiada "ya" di hujung', (tester) async {
      // Runutan murid sendiri: hujung setiap ayat yang memujuk pernah didengar
      // berakhir dengan "ya" dan kedengaran janggal selepas jawapan salah yang
      // ke sepuluh dalam satu sesi.
      for (final ayat in [
        Suara.teksLatihanSelesai,
        Suara.teksLatihanSederhana,
        Suara.teksLatihanUlang,
        Suara.teksCubaLagi,
        'Cemerlang! Semua jawapan betul.',
        'Cemerlang! Markah kamu cemerlang.',
        'Bagus! Sedikit lagi usaha.',
        'Boleh lagi! Cuba sekali lagi.',
        'Jangan putus asa. Mari kita ulang kaji sekali lagi.',
      ]) {
        expect(
          ayat.trim(),
          isNot(endsWith('ya.')),
          reason: '"ya" di hujung ayat berbunyi seperti orang dewasa memujuk',
        );
      }
    });
  });

  group('ambang syabas', () {
    test('syabas bermula pada 70 peratus', () {
      expect(Suara.latihanSelesai(69).$1, Suara.kunciLatihanSederhana);
      expect(Suara.latihanSelesai(70).$1, Suara.kunciLatihanSelesai);
      expect(Suara.latihanSelesai(100).$1, Suara.kunciLatihanSelesai);
    });

    test('keputusan lemah mendapat ajakan ulang kaji', () {
      expect(Suara.latihanSelesai(40).$1, Suara.kunciLatihanSederhana);
      expect(Suara.latihanSelesai(39).$1, Suara.kunciLatihanUlang);
      expect(Suara.latihanSelesai(0).$1, Suara.kunciLatihanUlang);
    });
  });

  group('pembetulan jawapan', () {
    testWidgets('latih tubi: jawapan salah dipaparkan dengan pembetulan', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));

      // Pilihan pertama betul — sengaja pilih yang kedua.
      await _jawabSatu(tester, pilihan: 1);

      expect(
        find.text('Pembetulan — jawapan sebenar'),
        findsOneWidget,
        reason: 'latih tubi ialah tempat belajar — ✗ sahaja tidak membantu',
      );
      expect(
        find.text('ساتو').evaluate().length,
        greaterThan(1),
        reason: 'jawapan betul mesti dipaparkan semula pada panel pembetulan',
      );
      await _tutup(tester);
    });

    testWidgets('latih tubi: jawapan betul tiada pembetulan', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester, pilihan: 0);

      expect(find.text('Pembetulan — jawapan sebenar'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tiada pembetulan semasa menjawab', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await _jawabSatu(tester, pilihan: 1);

      expect(
        find.text('Pembetulan — jawapan sebenar'),
        findsNothing,
        reason: 'percubaan bukan tempat membetulkan diri sambil diperiksa',
      );
      await _tutup(tester);
    });
  });

  group('suara jawapan betul (latih tubi)', () {
    /// Tulis satu huruf Jawi lalu tekan "Siap" — jawapan sengaja salah.
    Future<void> tulisSalah(WidgetTester tester) async {
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();
      // Papan kekunci Jawi terbuka sendiri pada soalan bertulis.
      await tester.tap(find.text('س').first);
      await tester.pump();
      await tester.tap(find.text('سياڤ'));
      await tester.pump();
    }

    testWidgets('soalan tulis: panel pembetulan ada butang speaker', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertasTulis(jenisSumber: 'latihan'));
      await tulisSalah(tester);

      expect(find.text('Pembetulan — jawapan sebenar'), findsOneWidget);

      final speaker = find.byTooltip('Dengar jawapan betul');
      expect(
        speaker,
        findsOneWidget,
        reason: 'soalan bertulis tiada cara lain mendengar jawapan contoh',
      );

      await tester.ensureVisible(speaker);
      await tester.pump();
      await tester.tap(speaker);
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciPilihan('satu\ndua\ntiga'),
        reason: 'mesti dibaca dalam tulisan Rumi, bukan Jawi yang dipaparkan',
      );
      await _tutup(tester);
    });

    testWidgets('tekan "Siap": papan kekunci tutup, pembetulan tercapai', (
      tester,
    ) async {
      // Papan kekunci yang kekal terbuka selepas menaip akan menutup panel
      // pembetulan di belakangnya, sehingga butang speaker jawapan betul
      // tidak boleh ditekan tanpa menyembunyikan kekunci secara manual.
      await _bukaSebagaiLaluan(tester, _kertasTulis(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();
      expect(find.text('سياڤ'), findsOneWidget, reason: 'kekunci terbuka');

      await tester.tap(find.text('س').first);
      await tester.pump();
      await tester.tap(find.text('سياڤ'));
      await tester.pump();

      expect(
        find.text('سياڤ'),
        findsNothing,
        reason: 'kerja menaip sudah selesai, kekunci mesti tertutup',
      );

      // Butang speaker kini boleh ditekan terus, tanpa langkah tambahan.
      await tester.tap(find.byTooltip('Dengar jawapan betul'));
      await tester.pump();
      expect(Suara.instance.ayatTerakhir, Suara.kunciPilihan('satu\ndua\ntiga'));
      await _tutup(tester);
    });

    testWidgets('medan jawapan masih membuka semula kekunci', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertasTulis(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();
      await tester.tap(find.text('س').first);
      await tester.pump();
      await tester.tap(find.text('سياڤ'));
      await tester.pump();
      expect(find.text('سياڤ'), findsNothing);

      // Menutup kekunci secara automatik tidak boleh mengunci murid keluar
      // daripada medan taip.
      await tester.tap(find.byType(PapanTaip));
      await tester.pump();
      expect(
        find.text('سياڤ'),
        findsOneWidget,
        reason: 'menyentuh medan jawapan mesti membuka semula kekunci',
      );
      await _tutup(tester);
    });

    testWidgets('soalan objektif: tiada butang speaker kedua pada panel', (
      tester,
    ) async {
      // Jawapan betul bagi soalan objektif masih terpapar di skrin dengan
      // butang speaker sendiri. Butang kedua pada panel hanya mengulang
      // bunyi yang sama sambil memaksa app membundel klip hampir serupa.
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester, pilihan: 1);

      expect(find.text('Pembetulan — jawapan sebenar'), findsOneWidget);
      expect(
        find.byTooltip('Dengar jawapan betul'),
        findsNothing,
        reason: 'pilihan betul sudah ada butang speaker tersendiri',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tiada butang speaker pembetulan', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertasTulis(jenisSumber: 'percubaan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      expect(find.byTooltip('Dengar jawapan betul'), findsNothing);
      await _tutup(tester);
    });
  });

  group('bantuan suara pilihan jawapan', () {
    testWidgets('latih tubi: memilih jawapan tidak berbunyi', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await _jawabSatu(tester);

      expect(
        Suara.instance.ayatTerakhir,
        isNull,
        reason: 'memilih jawapan tidak sepatutnya membacakan pilihan itu',
      );
      await _tutup(tester);
    });

    testWidgets('latih tubi: butang speaker membaca pilihan yang ditekan', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      final kedua = find.byType(ButangPilihan).at(1);
      final speaker = find.descendant(
        of: kedua,
        matching: find.byIcon(Icons.volume_up_rounded),
      );
      expect(
        speaker,
        findsOneWidget,
        reason: 'setiap pilihan patut ada butang speaker dalam latih tubi',
      );

      await tester.tap(speaker);
      await tester.pump();

      expect(Suara.instance.ayatTerakhir, Suara.kunciPilihan('dua'));
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tiada butang speaker langsung', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      expect(
        find.byIcon(Icons.volume_up_rounded),
        findsNothing,
        reason: 'kertas sebenar tidak membacakan soalan atau pilihan',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: kunci pilihan tidak pernah diminta', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await _jawabSatu(tester);

      expect(Suara.instance.ayatTerakhir, isNull);
      await _tutup(tester);
    });
  });

  group('gate jawapan wajib (latih tubi)', () {
    testWidgets('"Seterusnya" tidak bergerak sebelum soalan dijawab', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      expect(
        find.text('Soalan 2 daripada 2'),
        findsNothing,
        reason: 'latih tubi mewajibkan satu jawapan bagi setiap soalan',
      );
      expect(find.text('Soalan 1 daripada 2'), findsOneWidget);
      await _tutup(tester);
    });

    testWidgets('gate menerangkan sebabnya, bukan hanya enggan bergerak', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      expect(find.text('Jawab soalan ini dahulu.'), findsNothing);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      // Petunjuk visual dan suara muncul serentak: kanak-kanak yang menekan
      // butang yang "rosak" berasa keliru tanpa penjelasan.
      expect(find.text('Jawab soalan ini dahulu.'), findsOneWidget);
      expect(Suara.instance.ayatTerakhir, Suara.kunciJawabDulu);
      await _tutup(tester);
    });

    testWidgets('petunjuk hilang sendiri selepas beberapa saat', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      expect(find.text('Jawab soalan ini dahulu.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Jawab soalan ini dahulu.'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('petunjuk hilang serta-merta apabila soalan dijawab', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      expect(find.text('Jawab soalan ini dahulu.'), findsOneWidget);

      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();
      expect(find.text('Jawab soalan ini dahulu.'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('jawapan salah tetap membenarkan "Seterusnya"', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'latihan'));
      // Sengaja jawab salah — gate menuntut **ada** jawapan, bukan betul.
      await _jawabSatu(tester, pilihan: 1);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      expect(find.text('Soalan 2 daripada 2'), findsOneWidget);
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: boleh melangkapi soalan', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertas(jenisSumber: 'percubaan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();

      expect(
        find.text('Soalan 2 daripada 2'),
        findsOneWidget,
        reason: 'peperiksaan sebenar membenarkan murid melangkapi dan kembali',
      );
      expect(
        find.text('Jawab soalan ini dahulu.'),
        findsNothing,
        reason: 'percubaan tidak mengunci soalan',
      );
      await _tutup(tester);
    });
  });

  group('pujian rentetan (latih tubi)', () {
    /// Jawab soalan semasa dengan pilihan [pilihan] lalu tekan "Seterusnya".
    Future<void> jawabDanTerus(
      WidgetTester tester, {
      int pilihan = 0,
    }) async {
      await tester.tap(find.byType(ButangPilihan).at(pilihan));
      await tester.pump();
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
    }

    testWidgets('dua betul berturut: tiada suara pujian', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'latihan', bilangan: 4),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      expect(Suara.instance.ayatTerakhir, isNull);
      await jawabDanTerus(tester);
      expect(Suara.instance.ayatTerakhir, isNull);

      await _tutup(tester);
    });

    testWidgets('tiga betul berturut: pujian bersuara pertama', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'latihan', bilangan: 4),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciRentetan1,
        reason: 'rentetan 3 layak mendapat pujian bersuara',
      );
      await _tutup(tester);
    });

    testWidgets('empat betul berturut: tiada pujian (bukan kelipatan 3)', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'latihan', bilangan: 5),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      Suara.instance.ayatTerakhir = null;

      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();

      expect(
        Suara.instance.ayatTerakhir,
        isNull,
        reason: 'pujian hanya pada kelipatan 3 supaya tidak menjadi bunyi latar',
      );
      await _tutup(tester);
    });

    testWidgets('rentetan putus selepas jawapan salah', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'latihan', bilangan: 7),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      // Salah — rentetan mesti bermula semula.
      await jawabDanTerus(tester, pilihan: 1);
      Suara.instance.ayatTerakhir = null;

      // Tiga betul berturut selepas putus. Kalau rentetan tidak diset semula,
      // pujian akan tiba pada soalan kelima (jumlah 5) — bukan keenam.
      await jawabDanTerus(tester);
      expect(Suara.instance.ayatTerakhir, isNull);
      await jawabDanTerus(tester);
      expect(Suara.instance.ayatTerakhir, isNull);
      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciRentetan1,
        reason: 'selepas putus, rentetan baharu bermula pada 3 — bukan 5',
      );
      await _tutup(tester);
    });

    testWidgets('ayat pujian bergilir supaya tidak berulang', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'latihan', bilangan: 7),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      await tester.tap(find.byType(ButangPilihan).at(0)); // rentetan 3
      await tester.pump();
      expect(Suara.instance.ayatTerakhir, Suara.kunciRentetan1);

      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      await jawabDanTerus(tester); // rentetan 4 — senyap
      await jawabDanTerus(tester); // rentetan 5 — senyap
      expect(Suara.instance.ayatTerakhir, Suara.kunciRentetan1);

      await tester.tap(find.byType(ButangPilihan).at(0)); // rentetan 6
      await tester.pump();

      expect(
        Suara.instance.ayatTerakhir,
        Suara.kunciRentetan2,
        reason: 'pujian kedua mesti berbeza daripada yang pertama',
      );
      await _tutup(tester);
    });

    testWidgets('kertas percubaan: tiada pujian bersuara langsung', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'percubaan', bilangan: 4),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      await jawabDanTerus(tester);
      await jawabDanTerus(tester);
      await tester.tap(find.byType(ButangPilihan).at(0));
      await tester.pump();

      expect(Suara.instance.ayatTerakhir, isNull);
      await _tutup(tester);
    });
  });

  // Soalan `tulis` yang rubriknya mempunyai beberapa isi dipaparkan sebagai
  // kotak bernombor yang berasingan, meniru ruang yang dicetak pada kertas
  // asal. Tiga perkara dikunci di sini kerana semuanya mudah hilang:
  //
  //   * bilangan kotak meniru bilangan isi;
  //   * papan kekunci dalam app menulis kepada **kotak yang dipilih**, bukan
  //     sentiasa kepada kotak pertama;
  //   * semua kotak digabungkan sebelum dinilai — kalau tidak, murid yang
  //     menulis isi ke baris 2 dan 3 akan kehilangan markahnya.
  group('kotak berbilang baris (tulis)', () {
    testWidgets('kotak mengikut isi, taipan ke kotak dipilih, markah digabungkan', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertasTulisIsi(jenisSumber: 'latihan'),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      final kotak = find.byType(TextField);
      expect(kotak, findsNWidgets(3), reason: 'satu kotak bagi setiap isi');
      for (final n in ['(1)', '(2)', '(3)']) {
        expect(
          find.text(n),
          findsOneWidget,
          reason: 'nombor ruang kertas asal',
        );
      }
      // Had aksara merentasi kesemua kotak: 3 x 120.
      expect(find.text('0 / 360 aksara'), findsOneWidget);

      // Kotak kedua mungkin berada di belakang papan kekunci app. Tanpa
      // ditatal ke hadapan, `tap` mendarat pada papan kekunci yang berada di
      // atasnya — huruf kemudian masuk ke kotak yang salah, dan dalam ujian
      // ini butang papan kekunci pula yang terkena.
      await tester.ensureVisible(kotak.at(1));
      await tester.pump();

      await tester.tap(kotak.at(1));
      await tester.pump();

      expect(
        tester.widget<TextField>(kotak.at(1)).controller!.text,
        isEmpty,
        reason: 'kotak kedua dipilih sebelum menaip',
      );

      await tester.tap(find.text('س').first);
      await tester.pump();

      expect(
        tester.widget<TextField>(kotak.at(0)).controller!.text,
        isEmpty,
        reason: 'kotak pertama tidak boleh menerima taipan kotak kedua',
      );
      expect(
        tester.widget<TextField>(kotak.at(1)).controller!.text,
        'س',
        reason: 'kotak dipilih mesti menerima taipan',
      );
      expect(tester.widget<TextField>(kotak.at(2)).controller!.text, isEmpty);
      expect(find.text('1 / 360 aksara'), findsOneWidget);

      await tester.ensureVisible(find.text('سياڤ'));
      await tester.pump();
      await tester.tap(find.text('سياڤ'));
      await tester.pump();

      // Hanya isi kedua (kata kunci 'س') yang dijumpai. Jika pemarkahan
      // menggunakan satu kotak sahaja ia akan melihat kotak pertama yang
      // kosong dan memberi 0/3 — itulah kerosakan yang dicegah oleh gabungan.
      expect(
        find.textContaining('1 / 3'),
        findsWidgets,
        reason: 'markah mesti mengira isi yang ditulis ke kotak kedua',
      );
      expect(find.textContaining('0 / 3'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('soalan tulis tanpa rubrik kekal satu kotak', (tester) async {
      await _bukaSebagaiLaluan(tester, _kertasTulis(jenisSumber: 'latihan'));
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('(1)'), findsNothing);
      await _tutup(tester);
    });

    testWidgets('soalan huraian juga memaparkan kotak berbilang', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertasTulisIsi(jenisSumber: 'latihan', jenis: JenisKertas.huraian),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      // Semua 139 soalan `huraian` dalam bank berbentuk "Jelaskan N ..." dengan
      // tepat N isi dan N markah — bukan karangan bebas. Gerbang yang lama
      // mengecualikannya hanya kerana nama bahagiannya, jadi soalan seperti
      // "Jelaskan lima akibat" menunjukkan satu petak besar sahaja walau
      // kertas asalnya memberi lima baris bernombor.
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('(1)'), findsOneWidget);
      expect(find.text('(3)'), findsOneWidget);
      // Had aksara kekal 120 bagi **satu** kotak, bukan 400 x 3 — ruang pada
      // kertas asal mempunyai saiz yang sama bagi setiap baris.
      expect(find.text('0 / 360 aksara'), findsOneWidget);
      await _tutup(tester);
    });
  });

  // Bunyi soalan dan bunyi jawapan betul boleh berjalan panjang. Jika murid
  // menekan "Seterusnya" di tengah-tengah bacaan, bunyi itu berterusan
  // menembusi soalan seterusnya dan bertindih dengan bacaan baharunya —
  // murid kemudiannya tidak tahu ayat mana yang sedang didengarinya.
  group('bunyi berhenti apabila halaman bertukar', () {
    testWidgets('Seterusnya dan Sebelum menghentikan bunyi', (tester) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'percubaan', bilangan: 3),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      Suara.instance.berhentiDipanggil = false;
      await tester.tap(find.text('Seterusnya'));
      await tester.pump();
      expect(
        Suara.instance.berhentiDipanggil,
        isTrue,
        reason: 'bunyi soalan tidak boleh menembusi soalan seterusnya',
      );

      Suara.instance.berhentiDipanggil = false;
      await tester.tap(find.text('Sebelum'));
      await tester.pump();
      expect(
        Suara.instance.berhentiDipanggil,
        isTrue,
        reason: 'soalan sebelum ini juga tidak patut ditindih bacaan lama',
      );
      await _tutup(tester);
    });

    testWidgets('Sebelum pada halaman pertama tidak menyentuh bunyi', (
      tester,
    ) async {
      await _bukaSebagaiLaluan(
        tester,
        _kertas(jenisSumber: 'percubaan', bilangan: 3),
      );
      await tester.tap(find.text('Mula menjawab'));
      await tester.pump();

      // Butang sudah mati pada halaman pertama, jadi tiada halaman bertukar —
      // dan bunyi yang sedang berjalan kekal relevan kepada murid.
      Suara.instance.berhentiDipanggil = false;
      await tester.tap(find.text('Sebelum'), warnIfMissed: false);
      await tester.pump();
      expect(Suara.instance.berhentiDipanggil, isFalse);
      await _tutup(tester);
    });
  });
}
