// Soalan `senarai` — jawapan yang **semuanya** diterima skema.
//
// Kertas sebenar UPKK Bahagian D berbunyi seperti ini:
//
//     Jelaskan dua adab di majlis keramaian. (4 markah)
//     i.  ______________________________________
//     ii. ______________________________________
//
// Skema jawapannya menyenaraikan dua isi contoh dan menulis "(mana-mana 2
// jawapan yang betul diterima)". Markah 4 dibahagi dua, jadi setiap isi
// bernilai 2 markah — bukan 1 markah seperti soalan `huraian`.
//
// Ujian ini mengunci tiga perkara yang senang tersilap:
//
// 1. Markah mesti dibahagi sama rata antara isi, bukan dikira satu-satu.
// 2. Isi yang sama tidak boleh dikira dua kali.
// 3. Murid yang memberi isi dengan ayat sendiri (sedikit berbeza daripada
//    skema) tetap mendapat markah, tetapi menulis satu perkataan sahaja tidak.

import 'package:flutter_test/flutter_test.dart';

import 'package:ulangkaji_upkk/models/jawapan.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/pemarkah.dart';

/// Soalan Bahagian D contoh: "Jelaskan dua adab di majlis keramaian (4 markah)".
SoalanKertas _soalan({int markah = 4, int bilangan = 2}) =>
    SoalanKertas.dariJson(
      {
        'id': 'adab-d1',
        'jenis': 'senarai',
        'soalan': 'جلاسکن دوا ادب دممجليس کراماين.',
        'rumi': 'Jelaskan dua adab di majlis keramaian.',
        'markah': markah,
        'bilanganJawapan': bilangan,
        'jawapanContoh': [
          'ممبري سلام سمسار تيبا دمجليس',
          'دودوق دڠن ترتيب دان سوڤن',
        ],
        'jawapanContohRumi': [
          'Memberi salam sebaik tiba di majlis',
          'Duduk dengan tertib dan sopan',
        ],
      },
      bahagian: 'D',
      nombor: 1,
    );

void main() {
  group('model senarai', () {
    test('jenis dibaca daripada JSON', () {
      expect(_soalan().jenis, JenisKertas.senarai);
      expect(JenisKertas.dariTeks('senarai'), JenisKertas.senarai);
      expect(JenisKertas.senarai.teks, 'senarai');
    });

    test('markah penuh diambil daripada kertas, bukan bilangan isi', () {
      expect(_soalan().markahBolehDapat, 4);
      expect(_soalan(markah: 2, bilangan: 2).markahBolehDapat, 2);
    });

    test('dua isi betul mendapat markah penuh', () {
      final s = _soalan();
      final jawapan = JawapanTaip(
        'ممبري سلام سمسار تيبا دمجليس\nدودوق دڠن ترتيب دان سوڤن',
      );
      expect(s.markahDiperoleh(jawapan), 4);
      expect(s.betulPenuh(jawapan), isTrue);
    });

    test('satu isi sahaja mendapat separuh markah', () {
      final s = _soalan();
      final jawapan =
          JawapanTaip('ممبري سلام سمسار تيبا دمجليس\n');
      expect(s.markahDiperoleh(jawapan), 2);
      expect(s.betulPenuh(jawapan), isFalse);
    });

    test('isi yang sama diulang tidak dikira dua kali', () {
      final s = _soalan();
      final jawapan = JawapanTaip(
        'ممبري سلام سمسار تيبا دمجليس\nممبري سلام سمسار تيبا دمجليس',
      );
      expect(s.markahDiperoleh(jawapan), 2);
    });

    test('jawapan kosong tidak mendapat markah', () {
      final s = _soalan();
      expect(s.markahDiperoleh(null), 0);
      expect(s.markahDiperoleh(const JawapanTaip('')), 0);
      expect(s.markahDiperoleh(const JawapanTaip('\n')), 0);
    });

    test('murid perlu mengisi setiap ruang sebelum soalan dianggap lengkap', () {
      final s = _soalan();
      expect(s.lengkap(const JawapanTaip('ممبري سلام')), isFalse);
      expect(
        s.lengkap(const JawapanTaip('ممبري سلام\nدودوق دڠن ترتيب')),
        isTrue,
      );
    });

    test('markah 2 markah dibahagi antara dua isi menjadi 1 setiap satu', () {
      final s = _soalan(markah: 2, bilangan: 2);
      final satu = JawapanTaip('دودوق دڠن ترتيب دان سوڤن\n');
      expect(s.markahDiperoleh(satu), 1);
    });
  });

  group('padanan senarai', () {
    final diterima = [
      'ممبري سلام سمسار تيبا دمجليس',
      'دودوق دڠن ترتيب دان سوڤن',
    ];

    test('ayat yang sedikit berbeza tetap sepadan', () {
      // "duduk dengan tertib" — dua daripada tiga perkataan penting.
      final baris = Pemarkah.semakSenarai(
        diterima: diterima,
        jawapan: ['دودوق دڠن ترتيب', ''],
      );
      expect(baris, [true, false]);
    });

    test('satu perkataan sahaja tidak memadai', () {
      final baris = Pemarkah.semakSenarai(
        diterima: diterima,
        jawapan: ['سلام', ''],
      );
      expect(baris, [false, false]);
    });

    test('had bilangan isi dipatuhi', () {
      final bilangan = Pemarkah.bilanganSenarai(
        diterima: diterima,
        jawapan: [
          'ممبري سلام سمسار تيبا دمجليس',
          'دودوق دڠن ترتيب دان سوڤن',
        ],
        had: 1,
      );
      expect(bilangan, 1);
    });

    test('ejaan Jawi berkod huruf berbeza tetap diterima', () {
      // Murid menaip kaf Arab (U+0643) kerana papan kekunci telefon.
      final baris = Pemarkah.semakSenarai(
        diterima: ['دودوق دڠن ترتيب دان سوڤن'],
        jawapan: ['دودوق دڠن ترتيب دان سوڤن'.replaceAll('ک', '\u0643')],
      );
      expect(baris, [true]);
    });
  });
}
