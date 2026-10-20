// Bank soalan tidak boleh menawarkan dua pilihan yang sama.
//
// Ini pernah berlaku: seluruh Bahagian A dan B subjek Jawi memaparkan pilihan
// yang **serupa** — `ݢيݢي` dua kali, `باتو` dua kali, `ماکن` empat kali. Soalan
// seperti itu tidak boleh dijawab: apa pun yang ditekan, murid tidak belajar
// apa-apa, dan markahnya tidak bermakna.
//
// Punca asalnya ialah penjana soalan yang menyalin jawapan betul ke dalam
// setiap slot pengganggu. Ujian ini memeriksa **data**, bukan penjana, supaya
// kesilapan yang sama tidak boleh masuk semula melalui suntingan manual.
//
// Pilihan dibandingkan selepas tanda baca dan ruang dirapatkan, kerana
// `ب و ک و` dan `ب  و  ک  و` ialah pilihan yang sama bagi murid.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Semua fail bank soalan.
List<File> _failBank() {
  final folder = Directory('assets/content/bank');
  expect(folder.existsSync(), isTrue, reason: 'folder bank tidak dijumpai');
  return folder
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Bentuk perbandingan bagi satu teks pilihan.
String _normal(String teks) =>
    teks.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

void main() {
  test('tiada soalan yang menawarkan pilihan berulang', () {
    final masalah = <String>[];

    for (final fail in _failBank()) {
      final data = jsonDecode(fail.readAsStringSync()) as Map<String, dynamic>;
      final nama = fail.uri.pathSegments.last;

      for (final soalan in (data['soalan'] as List?) ?? const []) {
        if (soalan is! Map<String, dynamic>) continue;
        final id = soalan['id'] ?? '(tanpa id)';
        final item = (soalan['item'] as List?) ?? const [];

        for (var i = 0; i < item.length; i++) {
          final it = item[i];
          if (it is! Map<String, dynamic>) continue;

          final pilihan = <String>[
            for (final p in (it['pilihan'] as List?) ?? const [])
              if (p is Map<String, dynamic> && p['teks'] is String)
                _normal(p['teks'] as String),
          ].where((t) => t.isNotEmpty).toList();

          final unik = pilihan.toSet();
          if (unik.length != pilihan.length) {
            masalah.add(
              '$nama $id item ${i + 1}: ${pilihan.join(" | ")}',
            );
          }
        }
      }
    }

    expect(
      masalah,
      isEmpty,
      reason: 'Pilihan berulang menjadikan soalan tidak boleh dijawab:\n'
          '${masalah.join("\n")}',
    );
  });

  test('setiap soalan objektif ada sekurang-kurangnya dua pilihan berbeza', () {
    final masalah = <String>[];

    for (final fail in _failBank()) {
      final data = jsonDecode(fail.readAsStringSync()) as Map<String, dynamic>;
      final nama = fail.uri.pathSegments.last;

      for (final soalan in (data['soalan'] as List?) ?? const []) {
        if (soalan is! Map<String, dynamic>) continue;
        final jenis = soalan['jenis'];
        if (jenis != 'bulat' && jenis != 'objektif') continue;

        final id = soalan['id'] ?? '(tanpa id)';
        final item = (soalan['item'] as List?) ?? const [];

        for (var i = 0; i < item.length; i++) {
          final it = item[i];
          if (it is! Map<String, dynamic>) continue;
          final pilihan = (it['pilihan'] as List?) ?? const [];
          if (pilihan.length < 2) {
            masalah.add('$nama $id item ${i + 1}: hanya ${pilihan.length} pilihan');
          }
        }
      }
    }

    expect(masalah, isEmpty, reason: masalah.join("\n"));
  });
}
