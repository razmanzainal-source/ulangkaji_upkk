// Audit: setiap soalan mesti ada jawapan yang boleh dipaparkan dan markah
// yang boleh diperoleh. Cikgu KAFA melaporkan ada soalan yang muncul tanpa
// jawapan selepas dijawab — ujian ini menangkap semua kes itu.
import 'package:flutter_test/flutter_test.dart';
import 'package:ulangkaji_upkk/models/kertas.dart';
import 'package:ulangkaji_upkk/services/bank_kertas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semua soalan ada jawapan dan markah', () async {
    await BankKertas.instance.muat();
    final gagal = <String>[];
    var jumlah = 0;

    void semak(String label, SoalanKertas s) {
      jumlah++;
      if (s.markahBolehDapat <= 0) {
        gagal.add('$label ${s.id}: markah boleh dapat 0');
      }
      if (s.jawapanPenuhTeks.trim().isEmpty) {
        gagal.add('$label ${s.id} [${s.jenis.teks}]: jawapan kosong');
      }
    }

    for (final subjek in BankKertas.instance.subjek) {
      for (final s in BankKertas.instance.bank(subjek.id)) {
        semak('bank/${subjek.id}', s);
      }
    }
    for (final folder in [
      'adab-2024', 'adab-2025', 'akidah-2024', 'akidah-2025',
      'arab-2024', 'arab-2025', 'ibadah-2024', 'ibadah-2025',
      'jawi-2024', 'jawi-2025', 'sirah-2024', 'sirah-2025',
    ]) {
      final k = BankKertas.instance.kertasJawab(folder);
      if (k == null) continue;
      for (final b in k.bahagian) {
        for (final s in b.soalan) {
          semak(folder, s);
        }
      }
    }

    // ignore: avoid_print
    print('Soalan diperiksa: $jumlah | bermasalah: ${gagal.length}');
    // ignore: avoid_print
    for (final g in gagal.take(40)) {
      print('  $g');
    }
    expect(gagal, isEmpty, reason: gagal.join('\n'));
  });
}
