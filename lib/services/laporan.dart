import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gred.dart';
import 'bank_kertas.dart';
import 'kemajuan.dart';
import 'tetapan.dart';

/// Satu baris ringkasan bagi satu subjek, dikira daripada rekod setempat.
class BarisLaporan {
  const BarisLaporan({
    required this.nama,
    required this.percubaan,
    required this.terbaik,
    required this.purata,
    required this.perubahan,
  });

  final String nama;
  final int percubaan;

  /// Peratus markah terbaik (0–100).
  final int terbaik;

  /// Purata peratus semua percubaan.
  final int purata;

  /// Beza peratus antara percubaan terakhir dan pertama.
  final int perubahan;
}

/// Laporan Ibu Bapa — ringkasan kemajuan murid dalam bentuk PDF.
///
/// Semua data datang daripada rekod setempat (`Kemajuan`). Tiada apa-apa
/// dihantar ke mana-mana pelayan; PDF dijana di dalam peranti.
class Laporan {
  const Laporan._();

  /// Kira ringkasan bagi setiap subjek yang mempunyai rekod percubaan.
  static List<BarisLaporan> ringkasan() {
    final hasil = <BarisLaporan>[];
    for (final s in BankKertas.instance.subjek) {
      final rekod = Kemajuan.instance
          .rekodSubjek(s.id)
          .where((r) => !r.latihan)
          .toList();
      if (rekod.isEmpty) continue;

      final peratus = [
        for (final r in rekod)
          if (r.markahPenuh > 0) (r.markah * 100) ~/ r.markahPenuh,
      ];
      if (peratus.isEmpty) continue;

      final terbaik = peratus.reduce((a, b) => a > b ? a : b);
      final purata = peratus.reduce((a, b) => a + b) ~/ peratus.length;
      hasil.add(BarisLaporan(
        nama: s.nama,
        percubaan: rekod.length,
        terbaik: terbaik,
        purata: purata,
        perubahan: peratus.last - peratus.first,
      ));
    }
    return hasil;
  }

  /// Subjek yang perlu diberi perhatian (purata terendah).
  static BarisLaporan? perluPerhatian(List<BarisLaporan> baris) {
    if (baris.isEmpty) return null;
    return baris.reduce((a, b) => a.purata <= b.purata ? a : b);
  }

  /// Gred rasmi UPKK (A/B/C/D) — **satu sumber kebenaran**: model [Gred].
  ///
  /// Laporan tidak boleh mengira gred sendiri; dulu ia menggunakan skala lima
  /// gred yang berbeza, sehingga markah 55% dipaparkan sebagai D dalam app
  /// tetapi E dalam laporan.
  static String gred(int peratus) => Gred.dariPeratus(peratus).huruf;

  /// Bina dokumen PDF laporan.
  static Future<Uint8List> bina({DateTime? tarikh}) async {
    final hari = tarikh ?? DateTime.now();
    final nama = Tetapan.instance.namaAnak.trim().isEmpty
        ? 'Murid'
        : Tetapan.instance.namaAnak.trim();
    final baris = ringkasan();
    final fokus = perluPerhatian(baris);

    final doc = pw.Document();
    final teksBiasa = pw.TextStyle(fontSize: 10, lineSpacing: 2);
    final teksKecil = pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 36),
        header: (contexto) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.pink300, width: 1.2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ulangkaji UPKK',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.pink800)),
              pw.Text('Laporan Ibu Bapa', style: teksKecil),
            ],
          ),
        ),
        footer: (contexto) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dijana pada ${_tarikh(hari)}', style: teksKecil),
              pw.Text('Halaman ${contexto.pageNumber} / ${contexto.pagesCount}',
                  style: teksKecil),
            ],
          ),
        ),
        build: (contexto) => [
          pw.SizedBox(height: 6),
          pw.Text('Nama murid: $nama',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(
            'Jumlah percubaan: ${Kemajuan.instance.rekodKertas.length} · '
            'Hari berturut: ${Kemajuan.instance.rentetanHari} · '
            'Jawapan betul: ${Kemajuan.instance.jumlahBetul}',
            style: teksBiasa,
          ),
          pw.SizedBox(height: 14),
          if (baris.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.yellow50,
                border: pw.Border.all(color: PdfColors.orange300, width: 0.8),
              ),
              child: pw.Text(
                'Belum ada percubaan yang direkodkan. Mulakan dengan satu '
                'kertas percubaan dalam app, kemudian jana laporan ini semula.',
                style: teksBiasa,
              ),
            )
          else ...[
            pw.Text('Prestasi mengikut subjek',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Subjek',
                'Percubaan',
                'Terbaik',
                'Purata',
                'Gred',
                'Perubahan',
              ],
              data: [
                for (final b in baris)
                  [
                    b.nama,
                    '${b.percubaan}',
                    '${b.terbaik}%',
                    '${b.purata}%',
                    gred(b.terbaik),
                    b.perubahan == 0
                        ? '-'
                        : '${b.perubahan > 0 ? '+' : ''}${b.perubahan}%',
                  ],
              ],
              headerStyle: pw.TextStyle(
                  fontSize: 9.5, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.pink50),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 14),
            if (fokus != null) ...[
              pw.Text('Cadangan',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Beri tumpuan kepada ${fokus.nama} (purata ${fokus.purata}%). '
                'Gunakan Latih tubi subjek ini sekurang-kurangnya 10 soalan '
                'sehari, kemudian cuba satu Kertas Percubaan semula.',
                style: teksBiasa,
              ),
              pw.SizedBox(height: 8),
            ],
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
              ),
              child: pw.Text(
                'Nota: markah soalan bertulis dinilai mengikut isi jawapan '
                '(rubrik kata kunci), bukan ayat yang disalin bulat-bulat. '
                'Jawapan contoh dipaparkan selepas murid menjawab.',
                style: teksKecil,
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// Kongsi PDF melalui lembaran kongsi sistem.
  ///
  /// Fail ditulis ke **direktori Dokumen** aplikasi (bukan folder sementara).
  /// WhatsApp di iOS menolak fail daripada folder sementara kerana ia tidak
  /// dapat membaca laluan itu selepas salinan dibuat — gejala yang dilaporkan
  /// ialah "Couldn't send message".
  static Future<void> kongsi({
    required Uint8List pdf,
    required String namaMurid,
  }) async {
    final namaFail =
        'laporan-upkk-${_namaFail(namaMurid)}-${_tarikhFail(DateTime.now())}.pdf';

    final dir = await getApplicationDocumentsDirectory();
    // Buang laporan lama supaya storan tidak membesar.
    for (final lama in dir.listSync()) {
      final n = lama.path.split('/').last;
      if (n.startsWith('laporan-upkk-') && n.endsWith('.pdf')) {
        try {
          lama.deleteSync();
        } catch (_) {}
      }
    }

    final fail = File('${dir.path}/$namaFail');
    await fail.writeAsBytes(pdf, flush: true);

    // **Jangan** sertakan `text` bersama fail. WhatsApp di iOS menerima fail
    // tetapi gagal menghantarnya apabila teks disertakan serentak — gejala
    // "Couldn't send message". Hantar fail sahaja; `subject` digunakan oleh
    // aplikasi e-mel.
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Laporan Ulangkaji UPKK',
        files: [XFile(fail.path, mimeType: 'application/pdf')],
      ),
    );
  }

  /// Kongsi laporan sebagai **gambar PNG** (satu fail bagi setiap halaman).
  ///
  /// WhatsApp di sesetengah peranti menolak fail PDF walaupun PDF itu sah —
  /// gambar sentiasa diterima. Ini jalan kedua apabila PDF gagal.
  static Future<void> kongsiImej({
    required Uint8List pdf,
    required String namaMurid,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    for (final lama in dir.listSync()) {
      final n = lama.path.split('/').last;
      if (n.startsWith('laporan-upkk-') &&
          (n.endsWith('.pdf') || n.endsWith('.png'))) {
        try {
          lama.deleteSync();
        } catch (_) {}
      }
    }

    final asas = _namaFail(namaMurid);
    final fail = <XFile>[];
    var halaman = 0;
    await for (final raster in Printing.raster(pdf, dpi: 200)) {
      halaman++;
      final nama = 'laporan-upkk-$asas-$halaman.png';
      final f = File('${dir.path}/$nama');
      await f.writeAsBytes(await raster.toPng(), flush: true);
      fail.add(XFile(f.path, mimeType: 'image/png'));
    }
    if (fail.isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        subject: 'Laporan Ulangkaji UPKK',
        files: fail,
      ),
    );
  }

  static String _tarikhFail(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _tarikh(DateTime d) =>
      '${d.day} ${_bulan[d.month - 1]} ${d.year}';

  static String _namaFail(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  static const List<String> _bulan = [
    'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
    'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember',
  ];
}
