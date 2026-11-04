import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

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

  static String gred(int peratus) {
    if (peratus >= 80) return 'A';
    if (peratus >= 70) return 'B';
    if (peratus >= 60) return 'C';
    if (peratus >= 50) return 'D';
    return 'E';
  }

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
  static Future<ShareResult?> kongsi({
    required Uint8List pdf,
    required String namaMurid,
  }) async {
    final namaFail =
        'laporan-upkk-${_namaFail(namaMurid)}-${_tarikh(DateTime.now())}.pdf';
    try {
      return await SharePlus.instance.share(
        ShareParams(
          subject: 'Laporan Ulangkaji UPKK',
          text: 'Laporan kemajuan Ulangkaji UPKK.',
          files: [
            XFile.fromData(pdf, name: namaFail, mimeType: 'application/pdf'),
          ],
          fileNameOverrides: [namaFail],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static String _tarikh(DateTime d) =>
      '${d.day} ${_bulan[d.month - 1]} ${d.year}';

  static String _namaFail(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  static const List<String> _bulan = [
    'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
    'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember',
  ];
}
