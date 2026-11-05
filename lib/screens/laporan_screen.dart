import 'package:flutter/material.dart';

import 'pratonton_laporan_screen.dart';
import '../services/kemajuan.dart';
import '../services/laporan.dart';
import '../services/tetapan.dart';
import '../tema.dart';
import '../widgets/maskot.dart';

/// Skrin Laporan Ibu Bapa — ringkasan kemajuan murid yang boleh dikongsi
/// sebagai PDF (untuk disimpan, dicetak atau dihantar kepada guru).
///
/// Semua data kekal di dalam peranti; PDF dijana secara setempat.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _menjana = false;
  String? _mesej;

  Future<void> _bukaPratonton() async {
    if (_menjana) return;
    setState(() {
      _menjana = true;
      _mesej = null;
    });
    try {
      final pdf = await Laporan.bina();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PratontonLaporanScreen(pdf: pdf)),
      );
    } catch (_) {
      if (mounted) setState(() => _mesej = 'Laporan tidak dapat dijana.');
    } finally {
      if (mounted) setState(() => _menjana = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baris = Laporan.ringkasan();
    final fokus = Laporan.perluPerhatian(baris);
    final nama = Tetapan.instance.namaAnak.trim();

    return Scaffold(
      backgroundColor: Warna.latarSkrin,
      appBar: AppBar(
        backgroundColor: Warna.utama,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Laporan Ibu Bapa', style: Teks.sederhana),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _kepala(nama),
          const SizedBox(height: 14),
          if (baris.isEmpty)
            _kosong()
          else ...[
            _jadual(baris),
            if (fokus != null) ...[
              const SizedBox(height: 14),
              _cadangan(fokus),
            ],
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('kongsi-laporan'),
              onPressed: _menjana ? null : _bukaPratonton,
              icon: _menjana
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _menjana ? 'Menjana…' : 'Lihat & kongsi laporan (PDF)',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Warna.utama,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (_mesej != null) ...[
            const SizedBox(height: 8),
            Text(_mesej!, style: Teks.biasa.copyWith(color: Warna.salah)),
          ],
          const SizedBox(height: 10),
          Text(
            'Laporan dijana di dalam telefon ini sahaja. Tiada data dihantar '
            'ke mana-mana. Kongsi hanya apabila anda memilih penerima.',
            style: Teks.kecil.copyWith(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _kepala(String nama) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Warna.utama, Warna.utamaMuda],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Maskot(saiz: 56, mood: MoodMaskot.gembira),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama.isEmpty ? 'Murid' : nama,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Kemajuan.instance.rekodKertas.length} percubaan · '
                  '${Kemajuan.instance.rentetanHari} hari berturut · '
                  '${Kemajuan.instance.jumlahBetul} jawapan betul',
                  style: Teks.label.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kosong() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_outlined, color: Warna.utama),
          const SizedBox(height: 10),
          Text('Belum ada percubaan',
              style: Teks.sederhana.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Selesaikan satu Kertas Percubaan dahulu. Selepas itu laporan ini '
            'akan menunjukkan markah, gred dan subjek yang perlu diberi '
            'tumpuan.',
            style: Teks.biasa.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _jadual(List<BarisLaporan> baris) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prestasi mengikut subjek',
              style: Teks.sederhana.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final b in baris) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(b.nama, style: Teks.biasa),
                  ),
                  Text('${b.terbaik}%',
                      style: Teks.biasa.copyWith(
                          fontWeight: FontWeight.w800,
                          color: b.terbaik >= 70
                              ? Warna.betul
                              : Warna.salah)),
                  const SizedBox(width: 8),
                  Container(
                    width: 26,
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Warna.utamaLembut,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      Laporan.gred(b.terbaik),
                      style: Teks.label.copyWith(
                          fontWeight: FontWeight.w800, color: Warna.utama),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
          ],
        ],
      ),
    );
  }

  Widget _cadangan(BarisLaporan fokus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFEF6C00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cadangan',
                    style: Teks.sederhana.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Beri tumpuan kepada ${fokus.nama} (purata ${fokus.purata}%). '
                  'Cuba 10 soalan Latih tubi subjek ini setiap hari, kemudian '
                  'ulang satu Kertas Percubaan.',
                  style: Teks.biasa.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
