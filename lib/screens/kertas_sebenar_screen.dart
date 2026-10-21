import 'package:flutter/material.dart';

import 'kertas_screen.dart';
import '../models/kertas.dart';
import '../services/bank_kertas.dart';
import '../tema.dart';
import '../widgets/maskot.dart';
import '../widgets/pembaca_imej.dart';

/// Skrin "Kertas Sebenar" — senarai imbasan kertas UPKK tahun lepas.
///
/// Kertas ini ialah **imbasan sebenar** kertas UPKK 2024 dan 2025 yang
/// dibundelkan bersama app. Ia bukan soalan yang ditulis semula — murid melihat
/// kertas yang sama seperti yang akan dipegangnya di dewan peperiksaan, termasuk
/// susun atur, arahan dan bentuk soalan.
///
/// Tahun yang transkripnya lengkap (dengan skema jawapan rasmi) boleh **dijawab
/// terus dalam app** — butang "Jawab" muncul di sebelah tahun tersebut. Tahun
/// lain kekal sebagai imbasan gambar sahaja.
class SenaraiKertasSebenar extends StatelessWidget {
  const SenaraiKertasSebenar({super.key});

  @override
  Widget build(BuildContext context) {
    final subjek = BankKertas.instance.subjek;

    return Scaffold(
      backgroundColor: Warna.latarSkrin,
      appBar: AppBar(
        backgroundColor: Warna.utama,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kertas Sebenar', style: Teks.sederhana),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _KadPengenalan(),
          const SizedBox(height: 16),
          for (final s in subjek) ...[
            _KadSubjek(subjek: s),
            const SizedBox(height: 12),
          ],
          if (subjek.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Tiada kertas sebenar dibundelkan.', style: Teks.biasa),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kepala halaman — menerangkan apa itu "kertas sebenar".
class _KadPengenalan extends StatelessWidget {
  const _KadPengenalan();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Maskot(saiz: 76, mood: MoodMaskot.gembira),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kertas UPKK sebenar',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Imbasan kertas UPKK 2024 dan 2025. Baca untuk kenal bentuk '
                  'kertas — susun atur, arahan dan jenis soalan. Kertas yang '
                  'sudah ditranskripkan boleh dijawab terus dalam app.',
                  style: Teks.label.copyWith(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu subjek, dengan cip tahun untuk setiap imbasan yang ada.
class _KadSubjek extends StatelessWidget {
  const _KadSubjek({required this.subjek});

  final Subjek subjek;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: subjek.warna.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: subjek.warna.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(subjek.ikon, style: Teks.gambar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjek.nama,
                        style: Teks.sederhana.copyWith(color: subjek.warna),
                      ),
                      Text(
                        '${subjek.kod} • ${subjek.kertasSebenar.length} kertas',
                        style: Teks.label.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subjek.kertasSebenar.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in subjek.kertasSebenar)
                    _CipTahun(subjek: subjek, kertas: k),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Butang satu tahun kertas — ketik untuk membuka pembaca.
class _CipTahun extends StatelessWidget {
  const _CipTahun({required this.subjek, required this.kertas});

  final Subjek subjek;
  final KertasSebenar kertas;

  @override
  Widget build(BuildContext context) {
    final jawab = BankKertas.instance.kertasJawab(kertas.folder);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: subjek.warna.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('cip-${subjek.id}-${kertas.tahun}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PembacaKertasSebenar(
                  tajuk: '${subjek.nama} ${kertas.tahun}',
                  imej: [
                    for (var i = 1; i <= kertas.muka; i++) kertas.laluan(i),
                  ],
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 17, color: subjek.warna),
                  const SizedBox(width: 6),
                  Text(
                    '${kertas.tahun}',
                    style: Teks.sederhana.copyWith(
                      color: subjek.warna,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${kertas.muka} muka',
                    style: Teks.label.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (jawab != null) ...[
          const SizedBox(width: 8),
          Material(
            color: subjek.warna,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: ValueKey('jawab-${subjek.id}-${kertas.tahun}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => KertasScreen(kertas: jawab)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Jawab',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
