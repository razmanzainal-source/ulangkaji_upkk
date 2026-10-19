// Ujian pemarkahan jawapan bertulis terhadap **bank sebenar**.
//
// Inilah ujian yang paling kuat bagi enjin pemarkahan: setiap soalan bertulis
// dalam bank sudah membawa `jawapanContoh` — jawapan penuh yang ditulis sendiri
// semasa bank itu dikarang. Jawapan itu **mesti** mendapat markah penuh.
//
// Tanpa ujian ini, kegagalan paling senang berlaku ialah pemarkahan Jawi:
// enjin lama membuang semua huruf Arab sebelum membandingkan, jadi setiap
// jawapan Jawi mendapat sifar markah — dan murid tidak tahu mengapa.
//
// Fail ini membaca bank terus daripada cakera (seperti `jana_kertas_test.dart`)
// supaya ia berjalan tanpa keadaan app Flutter.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/pemarkah.dart';

List<String> _subjekAdaBank() => [
  for (final f in Directory('assets/content/bank').listSync())
    if (f.path.endsWith('.json'))
      f.uri.pathSegments.last.replaceAll('.json', ''),
];

List<SoalanKertas> _bank(String id) {
  final data =
      jsonDecode(File('assets/content/bank/$id.json').readAsStringSync())
          as Map<String, dynamic>;
  return [
    for (final (i, s) in (data['soalan'] as List).indexed)
      SoalanKertas.dariJson(
        s as Map<String, dynamic>,
        bahagian: (s['bahagian'] as String?) ?? '',
        nombor: i + 1,
      ),
  ];
}

void main() {
  group('jawapan contoh bank ditanda betul', () {
    for (final id in _subjekAdaBank()) {
      test('$id: jawapan contoh mendapat markah penuh', () {
        final soalanBertulis = _bank(id)
            .where((s) => s.jenis == JenisKertas.tulis || s.jenis == JenisKertas.huraian)
            .toList();

        expect(
          soalanBertulis,
          isNotEmpty,
          reason: '$id sepatutnya mempunyai soalan bertulis',
        );

        final gagal = <String>[];
        for (final s in soalanBertulis) {
          // Jawapan contoh ialah senarai isi; murid menulisnya sebagai ayat.
          final jawapan = s.jawapanContohRumi.isEmpty
              ? s.jawapanContoh.join('\n')
              : s.jawapanContoh.join('\n');
          final markah = Pemarkah.semak(s.rubrik, jawapan);
          if (markah.diperoleh != markah.penuh) {
            gagal.add(
              '  ${s.id}: ${markah.diperoleh}/${markah.penuh} '
              '— ${s.jawapanContohFailsafe()}',
            );
          }
        }

        expect(
          gagal,
          isEmpty,
          reason: '$id: jawapan contoh tidak mendapat markah penuh:\n'
              '${gagal.join('\n')}',
        );
      });
    }
  });
}

extension on SoalanKertas {
  /// Ringkasan pendek untuk mesej kegagalan ujian.
  String jawapanContohFailsafe() {
    final teks = jawapanContoh.join(' / ');
    return teks.length <= 90 ? teks : '${teks.substring(0, 90)}…';
  }
}
