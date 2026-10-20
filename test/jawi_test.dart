// Ujian ejaan Jawi — mengunci peraturan yang **tidak boleh dilanggar**.
//
// Teks Jawi dalam bank ditulis oleh model bahasa, dan model bahasa boleh
// menghasilkan ejaan yang kelihatan betul tetapi salah pada satu dua huruf
// (`کفد` untuk *kepada*, `تاغن` untuk *tangan*, `نياتکن` untuk *nyatakan*).
// Kesilapan itu tidak kelihatan kepada pembaca yang belum lancar Jawi — tetapi
// ia diajar kepada murid.
//
// Ujian ini menyemak dua perkara yang tidak memerlukan padanan perkataan:
//
// 1. **Huruf yang salah untuk bunyi Melayu.** `ك` (kaf Arab), `گ` (gaf Parsi),
//    `پ` (peh Parsi) dan `ی` (yeh Parsi) tidak pernah betul dalam Jawi Melayu.
//    Huruf yang betul ialah `ک`, `ݢ`, `ڤ` dan `ي`.
//
// 2. **Huruf Arab sahaja.** `ث ذ ص ض ط ظ ع ة ى` hanya sah dalam kata pinjaman
//    Arab. Setiap bentuk Jawi yang mengandungi huruf itu mesti tersenarai dalam
//    `tools/jawi_diterima.txt` — senarai yang disemak manusia. Bentuk baharu
//    tanpa semakan akan menggagalkan ujian ini.
//
// Semakan padanan penuh (contohnya /p/ mesti ditulis ڤ) dibuat oleh
// `tools/semak_jawi.py`, yang memadankan perkataan Rumi dengan Jawi. Ia tidak
// dimasukkan di sini kerana Rumi kadang-kadang terjemahan, bukan transliterasi.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Harakat, tasydid, sukun dan tatweel dibuang sebelum semakan.
final RegExp _harakat = RegExp('[\u064B-\u0655\u0670\u0640]');

/// Tanda baca yang boleh melekat pada perkataan.
final RegExp _tanda = RegExp(r"""[\u060C\u061B\u061F.,!?؟:;"'()\[\]«»–—\-…_]""");

/// Huruf Arab yang hanya sah dalam kata pinjaman.
const String _arabSahaja = 'ثذصضطظعةى';

/// Huruf Arab yang salah untuk bunyi Melayu.
const Map<String, String> _salahHuruf = {
  '\u0643': 'kaf Arab (ك) — Jawi Melayu guna ک',
  '\u06AF': 'gaf Parsi (گ) — Jawi Melayu guna ݢ',
  '\u067E': 'peh Parsi (پ) — Jawi Melayu guna ڤ',
  '\u06CC': 'yeh Parsi (ی) — Jawi Melayu guna ي',
};

const String _akar = '.';

Map<String, dynamic> _json(String laluan) =>
    jsonDecode(File(laluan).readAsStringSync()) as Map<String, dynamic>;

List<String> _tokenJawi(String teks) => teks
    .replaceAll(_harakat, '')
    .replaceAll(_tanda, ' ')
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty)
    .toList();

/// Semua medan Jawi dalam satu soalan, berserta id untuk mesej kegagalan.
Iterable<(String, String)> _medan(String sid, Map<String, dynamic> soalan) sync* {
  final soalanTeks = soalan['soalan'];
  if (soalanTeks is String) yield (sid, soalanTeks);
  for (final it in (soalan['item'] as List?) ?? const []) {
    if (it is! Map<String, dynamic>) continue;
    final teks = it['teks'];
    if (teks is String) yield (sid, teks);
    for (final p in (it['pilihan'] as List?) ?? const []) {
      if (p is Map<String, dynamic> && p['teks'] is String) {
        yield (sid, p['teks'] as String);
      }
    }
  }
  for (final p in (soalan['pasangan'] as List?) ?? const []) {
    if (p is! Map<String, dynamic>) continue;
    if (p['kiri'] is String) yield (sid, p['kiri'] as String);
    if (p['kanan'] is String) yield (sid, p['kanan'] as String);
  }
  for (final k in const ['bank', 'urutan', 'jawapanContoh']) {
    for (final v in (soalan[k] as List?) ?? const []) {
      if (v is String) yield (sid, v);
    }
  }
  for (final idea in (soalan['idea'] as List?) ?? const []) {
    if (idea is! Map<String, dynamic>) continue;
    for (final v in (idea['kata'] as List?) ?? const []) {
      if (v is String) yield (sid, v);
    }
    if (idea['maksud'] is String) yield (sid, idea['maksud'] as String);
  }
}

/// Subjek dan teks Jawi yang perlu disemak. Bahasa Arab ditulis dalam tulisan
/// Arab — kaf Arab dan ta marbutah betul di sana, jadi ia dikecualikan.
Iterable<(String, String, String)> _semuaTeks() sync* {
  final subjek = _json('$_akar/assets/content/subjek.json');
  for (final s in (subjek['subjek'] as List).cast<Map<String, dynamic>>()) {
    final id = s['id'] as String;
    if (id == 'arab') continue;
    final fail = File('$_akar/assets/content/bank/$id.json');
    if (!fail.existsSync()) continue;
    for (final soalan in (_json(fail.path)['soalan'] as List)) {
      final q = soalan as Map<String, dynamic>;
      final sid = (q['id'] as String?) ?? '?';
      for (final (_, teks) in _medan(sid, q)) {
        yield (id, sid, teks);
      }
    }
  }
}

void main() {
  final diterima = {
    for (final baris in File('$_akar/tools/jawi_diterima.txt').readAsLinesSync())
      if (baris.trim().isNotEmpty && !baris.startsWith('#')) baris.trim(),
  };

  test('ejaan Jawi menepati peraturan huruf', () {
    final masalah = <String>[];
    final bentukBaharu = <String>{};
    var token = 0;

    for (final (subjek, sid, teks) in _semuaTeks()) {
      for (final t in _tokenJawi(teks)) {
        token++;
        // Kata pinjaman Arab mengekalkan ejaan Arabnya, termasuk ك.
        final pinjaman = diterima.contains(t);
        for (final e in pinjaman ? const <String, String>{}.entries : _salahHuruf.entries) {
          if (t.contains(e.key)) {
            masalah.add('$subjek:$sid  "$t"  ← ${e.value}');
          }
        }
        if (t.split('').any(_arabSahaja.contains) && !diterima.contains(t)) {
          bentukBaharu.add(t);
        }
      }
    }

    expect(token, greaterThan(5000), reason: 'semakan tidak berjalan');

    expect(
      masalah,
      isEmpty,
      reason:
          'Huruf yang salah untuk bunyi Melayu mesti dibetulkan sebelum ia '
          'diajar kepada murid.\n\n${masalah.take(20).join('\n')}',
    );

    expect(
      bentukBaharu,
      isEmpty,
      reason:
          'Bentuk Jawi baharu ini mengandungi huruf Arab sahaja (ث ذ ص ض ط ظ ع '
          'ة ى) dan belum disemak. Sahkan ejaannya terhadap kamus atau kertas '
          'sebenar, kemudian tambah ke `tools/jawi_diterima.txt`:\n\n'
          '${(bentukBaharu.toList()..sort()).take(30).join('\n')}',
    );
  });
}
