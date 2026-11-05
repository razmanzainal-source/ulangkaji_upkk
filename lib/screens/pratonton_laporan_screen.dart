import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/laporan.dart';
import '../services/tetapan.dart';
import '../tema.dart';

/// Pratonton PDF laporan sebelum dikongsi atau dicetak.
///
/// Dua pilihan kongsi disediakan:
///   * **PDF** — pilihan utama (Mail, Drive, cetak).
///   * **Gambar** — jalan kedua apabila WhatsApp menolak fail PDF.
class PratontonLaporanScreen extends StatelessWidget {
  const PratontonLaporanScreen({super.key, required this.pdf});

  final Uint8List pdf;

  String get _nama {
    final n = Tetapan.instance.namaAnak.trim();
    return n.isEmpty ? 'murid' : n;
  }

  Future<void> _kongsi() => Laporan.kongsi(pdf: pdf, namaMurid: _nama);

  Future<void> _kongsiImej() =>
      Laporan.kongsiImej(pdf: pdf, namaMurid: _nama);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.latarSkrin,
      appBar: AppBar(
        backgroundColor: Warna.utama,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pratonton laporan', style: Teks.sederhana),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (_) async => pdf,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              // Toolbar terbina dimatikan: hanya satu baris tindakan di bawah,
              // supaya ikon tidak bertindih.
              allowSharing: false,
              allowPrinting: false,
              pdfFileName: 'laporan-upkk.pdf',
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: Warna.utama),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('kongsi-pdf'),
                      onPressed: _kongsi,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text(
                        'Kongsi PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Warna.utama,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('kongsi-imej'),
                      onPressed: _kongsiImej,
                      icon: const Icon(Icons.image_rounded, size: 19),
                      label: const Text(
                        'Kongsi sebagai gambar',
                        style: Teks.biasa,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Warna.utama,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Guna “gambar” jika WhatsApp tidak menerima fail PDF.',
                    style: Teks.kecil.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
