import 'package:flutter/material.dart';

import '../models/kertas.dart';
import '../models/lencana.dart';
import '../services/kemajuan.dart';
import '../tema.dart';

/// Kad koleksi lencana — versi yang boleh dikongsi sebagai gambar.
///
/// Kad ini berbeza daripada slip markah: ia menunjukkan
/// **pencapaian**, bukan markah. Murid yang belum mendapat gred A masih boleh
/// menunjukkan lencana yang dia kumpulkan — dan lencana yang belum
/// diperoleh kelihatan kelabu supaya ada sesuatu untuk dikejar.
class KadLencana extends StatelessWidget {
  const KadLencana({
    super.key,
    required this.nama,
    required this.tarikh,
    required this.subjek,
  });

  /// Nama murid — kosong bermakna belum ditetapkan.
  final String nama;

  /// Tarikh paparan, cth "22 Oktober 2026".
  final String tarikh;

  /// Subjek yang ada dalam app.
  final List<Subjek> subjek;

  /// Lebar kad. Ketinggian mengikut kandungan — kad ini mengandungi senarai
  /// lencana yang panjang, jadi Tingginya tidak dikunci.
  static const double lebar = 360;

  @override
  Widget build(BuildContext context) {
    final kemajuan = Kemajuan.instance;
    final ada = kemajuan.lencanaDiperoleh;
    final jumlah = subjek.length * TahapLencana.values.length +
        DaftarLencana.global.length;

    return Container(
      width: lebar,
      color: Warna.latarSkrin,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _kepala(),
            const SizedBox(height: 6),
            _baris('Nama', nama.trim().isEmpty ? '—' : nama.trim()),
            _baris('Tarikh', tarikh),
            const SizedBox(height: 12),
            _kira(ada.length, jumlah),
            const SizedBox(height: 14),
            for (final s in subjek) ...[
              _barisSubjek(s, ada),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 2),
            _barisGlobal(ada),
            const SizedBox(height: 14),
            _kaki(kemajuan),
          ],
        ),
      ),
    );
  }

  Widget _kepala() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Warna.utama.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 22,
            color: Warna.utama,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KOLEKSI LENCANA',
              style: Teks.cop.copyWith(color: Warna.dakwat),
            ),
            Text(
              'Ulangkaji UPKK',
              style: Teks.sederhana.copyWith(color: Warna.utama),
            ),
          ],
        ),
      ],
    );
  }

  Widget _baris(String label, String nilai) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: Teks.cop.copyWith(color: Colors.black54),
              ),
            ),
            Expanded(
              child: Text(
                nilai,
                style: Teks.kecil.copyWith(
                  color: Colors.black.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _kira(int diperoleh, int jumlah) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Warna.utamaLembut,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 20, color: Warna.utama),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$diperoleh daripada $jumlah lencana diperoleh',
              style: Teks.kecil.copyWith(
                color: Warna.dakwat,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisSubjek(Subjek s, Set<String> ada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(s.ikon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              s.nama,
              style: Teks.label.copyWith(
                color: s.warna,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final t in TahapLencana.values) ...[
              _bulat(t, ada.contains(DaftarLencana.kunciSubjek(s.id, t))),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _barisGlobal(Set<String> ada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LENCANA GLOBAL',
          style: Teks.cop.copyWith(color: Warna.dakwat),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final l in DaftarLencana.global)
              _bulatLencana(l, ada.contains(l.id)),
          ],
        ),
      ],
    );
  }

  Widget _bulat(TahapLencana t, bool diperoleh) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: diperoleh ? t.warna.withValues(alpha: 0.14) : Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: diperoleh ? t.warna.withValues(alpha: 0.5) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Icon(
        diperoleh ? t.ikon : Icons.lock_rounded,
        size: 19,
        color: diperoleh ? t.warna : Colors.grey.shade400,
      ),
    );
  }

  Widget _bulatLencana(Lencana l, bool diperoleh) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: diperoleh
                ? l.warna.withValues(alpha: 0.14)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: diperoleh
                  ? l.warna.withValues(alpha: 0.5)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            diperoleh ? l.ikon : Icons.lock_rounded,
            size: 19,
            color: diperoleh ? l.warna : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l.tajuk,
          style: Teks.cop.copyWith(
            color: diperoleh ? l.warna : Colors.grey.shade500,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _kaki(Kemajuan kemajuan) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Warna.latarNota,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _angka('${kemajuan.rentetanTerpanjang}', 'terbaik\nberturut'),
          ),
          Expanded(
            child: _angka('${kemajuan.jumlahBetul}', 'jawapan\nbetul'),
          ),
          Expanded(
            child: _angka('${kemajuan.rentetanHari}', 'hari\nberturut'),
          ),
        ],
      ),
    );
  }

  Widget _angka(String nilai, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nilai,
          style: Teks.sederhana.copyWith(
            color: Warna.dakwat,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Teks.cop.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}
