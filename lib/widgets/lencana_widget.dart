import 'package:flutter/material.dart';

import '../models/lencana.dart';
import '../services/kemajuan.dart';
import '../tema.dart';

/// Baris empat lencana markah bagi satu subjek.
///
/// Lencana yang belum diperoleh dilgreykan dan berkunci — ia masih kelihatan
/// supaya murid tahu apa yang perlu dikejar, bukan sekadar hilang.
class BarisLencanaMarkah extends StatelessWidget {
  const BarisLencanaMarkah({
    super.key,
    required this.subjekId,
    required this.namaSubjek,
    this.ukuran = 34,
  });

  final String subjekId;
  final String namaSubjek;

  /// Saiz bulatan lencana.
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final ada = Kemajuan.instance.lencanaDiperoleh;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (final tahap in TahapLencana.values) ...[
          _Bulatan(
            ikon: tahap.ikon,
            warna: tahap.warna,
            diperoleh: ada.contains(
              DaftarLencana.kunciSubjek(subjekId, tahap),
            ),
            ukuran: ukuran,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Satu keping lencana dalam koleksi lencana.
class PetakLencana extends StatelessWidget {
  const PetakLencana({
    super.key,
    required this.lencana,
    this.diperoleh = true,
  });

  final Lencana lencana;

  /// Benar apabila lencana ini sudah diperoleh.
  final bool diperoleh;

  @override
  Widget build(BuildContext context) {
    final warna = diperoleh ? lencana.warna : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: diperoleh ? lencana.warna.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: diperoleh
              ? lencana.warna.withValues(alpha: 0.35)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            diperoleh ? lencana.ikon : Icons.lock_outline_rounded,
            size: 26,
            color: warna,
          ),
          const SizedBox(height: 5),
          Text(
            lencana.tajuk,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Teks.label.copyWith(
              color: diperoleh ? lencana.warna : Colors.grey.shade500,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulatan satu lencana di baris subjek.
class _Bulatan extends StatelessWidget {
  const _Bulatan({
    required this.ikon,
    required this.warna,
    required this.diperoleh,
    required this.ukuran,
  });

  final IconData ikon;
  final Color warna;
  final bool diperoleh;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final warnaLencana = diperoleh ? warna : Colors.grey.shade300;
    return Tooltip(
      message: diperoleh ? 'Lencana diperoleh' : 'Lencana belum diperoleh',
      child: Container(
        width: ukuran,
        height: ukuran,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: diperoleh ? warna.withValues(alpha: 0.14) : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: diperoleh ? warna.withValues(alpha: 0.45) : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          diperoleh ? ikon : Icons.lock_rounded,
          size: ukuran * 0.52,
          color: warnaLencana,
        ),
      ),
    );
  }
}
