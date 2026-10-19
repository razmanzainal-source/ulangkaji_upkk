// Ujian enjin pemarkahan dan penggredan UPKK.
//
// Dua bahagian app ini menentukan markah yang dilihat murid, dan kedua-duanya
// penuh dengan kes tepi yang senang tersalah:
//
//   * [Pemarkah] cuba mengenali isi jawapan walaupun murid menulis imbuhan,
//     sinonim atau salah eja sedikit — tetapi tidak boleh terlalu longgar
//     sehingga jawapan kosong pun mendapat markah.
//   * [Gred] memetakan peratus kepada gred rasmi UPKK, dan had julatnya
//     (80, 60, 40) mesti tepat pada satu peratus.
//
// Ujian ini menulis kes tepi itu secara jelas supaya kelonggaran yang sengaja
// dibuat tidak hilang tanpa disedari semasa kod diubah.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/gred.dart';
import 'package:ulangkaji_upkk/models/rubrik.dart';
import 'package:ulangkaji_upkk/services/pemarkah.dart';

/// Bina rubrik ringkas: setiap rentetan menjadi satu idea dengan satu kata kunci.
Rubrik _rubrik(List<String> kataKunci) => Rubrik([
      for (final k in kataKunci) Idea(maksud: k, kata: [k]),
    ]);

void main() {
  group('Gred UPKK', () {
    test('had julat rasmi tepat pada satu peratus', () {
      expect(Gred.dariPeratus(100), Gred.a);
      expect(Gred.dariPeratus(80), Gred.a);
      expect(Gred.dariPeratus(79), Gred.b);
      expect(Gred.dariPeratus(60), Gred.b);
      expect(Gred.dariPeratus(59), Gred.c);
      expect(Gred.dariPeratus(40), Gred.c);
      expect(Gred.dariPeratus(39), Gred.d);
      expect(Gred.dariPeratus(1), Gred.d);
    });

    test('markah sifar tetap diberi gred supaya paparan tidak kosong', () {
      // Kertas UPKK tidak memberi gred kepada calon yang tidak hadir, tetapi
      // skrin keputusan app mesti sentiasa memaparkan sesuatu.
      expect(Gred.dariPeratus(0), Gred.d);
    });

    test('julat teks sepadan dengan had grad', () {
      expect(Gred.a.julatTeks, '80–100%');
      expect(Gred.b.julatTeks, '60–79%');
      expect(Gred.c.julatTeks, '40–59%');
      expect(Gred.d.julatTeks, '1–39%');
    });

    test('gred tertinggi tidak naik lagi', () {
      expect(Gred.a.seterusnya, Gred.a);
      expect(Gred.d.seterusnya, Gred.c);
    });

    test('empat gred sahaja — UPKK tiada gred E', () {
      expect(Gred.values.length, 4);
    });
  });

  group('Pemarkah.varian — bentuk kata dasar', () {
    test('imbuhan awalan dan akhiran dibuang', () {
      expect(Pemarkah.varian('mengangkut'), contains('angkut'));
      expect(Pemarkah.varian('menyejukkan'), contains('sejuk'));
      expect(Pemarkah.varian('berlari'), contains('lari'));
    });

    test('perkataan pendek tidak dipotong menjadi perkataan lain', () {
      // "kelas" tidak boleh menjadi "elas" — kalau tidak, soalan tentang kelas
      // akan mendapat markah daripada jawapan yang tidak berkaitan.
      expect(Pemarkah.varian('kelas'), isNot(contains('elas')));
    });

    test('kata asal itu sendiri sentiasa disertakan', () {
      expect(Pemarkah.varian('air'), contains('air'));
    });
  });

  group('Pemarkah.hampirSama — toleransi salah eja', () {
    test('perkataan empat huruf ke bawah mesti tepat', () {
      // "air" dan "ais" hanya berbeza satu huruf, tetapi kedua-duanya perkataan
      // sebenar yang berlainan maksud.
      expect(Pemarkah.hampirSama('air', 'ais'), isFalse);
      expect(Pemarkah.hampirSama('air', 'air'), isTrue);
    });

    test('perkataan lima huruf ke atas boleh tersalah satu huruf', () {
      expect(Pemarkah.hampirSama('peparu', 'pepru'), isTrue);
      expect(Pemarkah.hampirSama('udara', 'udala'), isTrue);
    });

    test('perkataan jauh berbeza tidak diterima', () {
      expect(Pemarkah.hampirSama('sekolah', 'masjid'), isFalse);
    });
  });

  group('Pemarkah.semak — satu idea satu markah', () {
    test('rubrik kosong memberi markah kosong, bukan markah penuh', () {
      final m = Pemarkah.semak(Rubrik.kosong, 'apa-apa jawapan');
      expect(m.penuh, 0);
      expect(m.diperoleh, 0);
      expect(m.betul, isFalse);
    });

    test('jawapan kosong tidak mendapat markah', () {
      final m = Pemarkah.semak(_rubrik(['udara', 'peparu']), '');
      expect(m.diperoleh, 0);
      expect(m.adaMarkah, isFalse);
    });

    test('semua idea dijumpai bermakna betul sepenuhnya', () {
      final m = Pemarkah.semak(
        _rubrik(['udara', 'peparu']),
        'Udara masuk ke dalam peparu.',
      );
      expect(m.diperoleh, 2);
      expect(m.penuh, 2);
      expect(m.betul, isTrue);
      expect(m.ideaDijumpai, [true, true]);
    });

    test('idea yang tidak disebut tidak dikira', () {
      final m = Pemarkah.semak(
        _rubrik(['udara', 'peparu', 'darah']),
        'Udara masuk ke dalam peparu.',
      );
      expect(m.diperoleh, 2);
      expect(m.penuh, 3);
      expect(m.betul, isFalse);
      expect(m.ideaDijumpai, [true, true, false]);
    });

    test('imbuhan dalam jawapan murid diterima', () {
      expect(
        Pemarkah.semak(_rubrik(['angkut']), 'Darah mengangkut oksigen.').betul,
        isTrue,
      );
      expect(
        Pemarkah.semak(_rubrik(['sejuk']), 'Air itu menyejukkan badan.').betul,
        isTrue,
      );
    });

    test('tanda baca dan huruf besar tidak mengganggu pemarkahan', () {
      final m = Pemarkah.semak(_rubrik(['udara']), 'UDARA!');
      expect(m.betul, isTrue);
    });

    test('sengkang dikira pemisah perkataan', () {
      expect(
        Pemarkah.semak(_rubrik(['paru']), 'paru-paru').betul,
        isTrue,
      );
    });

    test('sinonim diterima apabila disenaraikan dalam rubrik', () {
      final rubrik = Rubrik([
        const Idea(maksud: 'Oksigen', kata: ['udara', 'oksigen']),
      ]);
      expect(Pemarkah.semak(rubrik, 'Kita perlukan oksigen.').betul, isTrue);
      expect(Pemarkah.semak(rubrik, 'Kita perlukan udara.').betul, isTrue);
      expect(Pemarkah.semak(rubrik, 'Kita perlukan air.').betul, isFalse);
    });

    test('tahun mesti tepat — padanan kabur tidak terpakai pada angka', () {
      final rubrik = _rubrik(['1950']);
      expect(Pemarkah.semak(rubrik, 'Tanah Melayu merdeka pada 1950.').betul,
          isTrue);
      expect(Pemarkah.semak(rubrik, 'Tanah Melayu merdeka pada 1951.').betul,
          isFalse);
    });

    test('salah eja sedikit diterima untuk perkataan panjang', () {
      expect(
        Pemarkah.semak(_rubrik(['peparu']), 'Oksigen masuk ke pepru.').betul,
        isTrue,
      );
    });

    test('perkataan pendek tidak diterima jika berlainan maksud', () {
      expect(Pemarkah.semak(_rubrik(['air']), 'Saya minum ais.').betul, isFalse);
    });
  });

  group('Pemarkah.perkataan', () {
    test('huruf kecil, tanpa tanda baca', () {
      expect(Pemarkah.perkataan('Udara, Masuk!'), ['udara', 'masuk']);
    });

    test('teks kosong menghasilkan senarai kosong', () {
      expect(Pemarkah.perkataan('   '), isEmpty);
      expect(Pemarkah.perkataan('!!!'), isEmpty);
    });
  });
}
