import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan `betul_salah_set` — gaya UASA Bahagian B.
///
/// Murid menandakan setiap pernyataan sebagai BETUL atau SALAH, sama seperti
/// menanda (✓) atau (✗) pada kertas peperiksaan. Setiap pernyataan bernilai
/// satu markah, jadi markah separa dikira.
class PapanBetulSalah extends StatelessWidget {
  const PapanBetulSalah({
    super.key,
    required this.pernyataan,
    this.rumiPernyataan,
    required this.jawapan,
    required this.warna,
    required this.onJawab,
    this.jawapanSebenar = const [],
    this.onDengar,
    this.lumpuh = false,
    this.betul,
  });

  /// Teks setiap pernyataan.
  final List<String> pernyataan;

  /// Transliterasi Rumi bagi setiap pernyataan (indeks sama dengan
  /// [pernyataan]).
  ///
  /// Ini panduan bacaan sahaja — bukan data jawapan. Jika ia tiada atau
  /// panjangnya tidak sepadan, pernyataan dipaparkan dalam Jawi sahaja.
  final List<String>? rumiPernyataan;

  /// Jawapan murid bagi setiap pernyataan: `true` = BETUL, `false` = SALAH,
  /// `null` = belum ditanda.
  final List<bool?> jawapan;

  /// Jawapan sebenar bagi setiap pernyataan.
  ///
  /// Diberi oleh skrin pemilik selepas jawapan disemak; kosong semasa menjawab
  /// (ketika itu tiada sorotan hijau/merah).
  final List<bool> jawapanSebenar;

  /// Warna unit untuk sorotan pilihan.
  final Color warna;

  /// Dipanggil apabila murid menandakan sesuatu pernyataan.
  final void Function(int indeks, bool nilai) onJawab;

  /// Butang dengar bagi setiap pernyataan. `null` menyembunyikannya.
  final ValueChanged<int>? onDengar;

  /// Benar apabila jawapan tidak boleh diubah lagi.
  final bool lumpuh;

  /// `null` belum disemak; `true`/`false` keputusan keseluruhan.
  final bool? betul;

  @override
  Widget build(BuildContext context) {
    final tanah = switch (betul) {
      null => Colors.transparent,
      true => Warna.latarBetul,
      false => Warna.latarSalah,
    };
    final tepi = switch (betul) {
      null => null,
      true => Warna.betul,
      false => Warna.salah,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tanah,
        borderRadius: BorderRadius.circular(22),
        border: tepi == null ? null : Border.all(color: tepi, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < pernyataan.length; i++) _baris(i)],
      ),
    );
  }

  Widget _baris(int i) {
    final dipilih = i < jawapan.length ? jawapan[i] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: warna.withValues(alpha: 0.28), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nombor(i + 1),
                const SizedBox(width: 10),
                Expanded(
                  child: Dwibahasa(
                    jawi: pernyataan[i],
                    rumi: Dwibahasa.rumiSelari(
                      rumiPernyataan,
                      i,
                      pernyataan.length,
                    ),
                  ),
                ),
                if (onDengar != null)
                  IconButton(
                    onPressed: () => onDengar!(i),
                    iconSize: 22,
                    color: warna,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: 'Dengar',
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _butang(i, nilai: true, dipilih: dipilih == true),
                const SizedBox(width: 8),
                _butang(i, nilai: false, dipilih: dipilih == false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bulatan nombor pernyataan.
  Widget _nombor(int nombor) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: warna.withValues(alpha: 0.10),
        border: Border.all(color: warna.withValues(alpha: 0.35), width: 2),
      ),
      child: Text(
        '$nombor',
        style: Teks.lencana.copyWith(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _butang(int i, {required bool nilai, required bool dipilih}) {
    final ikon = nilai ? Icons.check_rounded : Icons.close_rounded;
    final label = nilai ? 'BETUL' : 'SALAH';

    // Selepas disemak, jawapan yang betul disorot hijau dan jawapan salah
    // murid disorot merah — supaya murid nampak item mana yang tersasar.
    final betulSebenar = _betulSebenar(i);
    final disemak = betul != null;
    final tepat = nilai == betulSebenar;

    final Color warnaLatar;
    final Color warnaLatarTepi;
    if (disemak) {
      if (dipilih && tepat) {
        warnaLatar = Warna.latarBetul;
        warnaLatarTepi = Warna.betul;
      } else if (dipilih && !tepat) {
        warnaLatar = Warna.latarSalah;
        warnaLatarTepi = Warna.salah;
      } else if (!dipilih && tepat) {
        warnaLatar = Warna.latarBetul.withValues(alpha: 0.6);
        warnaLatarTepi = Warna.betul.withValues(alpha: 0.6);
      } else {
        warnaLatar = Colors.white;
        warnaLatarTepi = Colors.black.withValues(alpha: 0.12);
      }
    } else if (dipilih) {
      warnaLatar = warna.withValues(alpha: 0.16);
      warnaLatarTepi = warna;
    } else {
      warnaLatar = Colors.white;
      warnaLatarTepi = warna.withValues(alpha: 0.4);
    }

    return Expanded(
      child: Material(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: lumpuh ? null : () => onJawab(i, nilai),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: warnaLatarTepi, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ikon,
                  size: 20,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Teks.kecil.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Jawapan sebenar pernyataan [i] (untuk paparan selepas semakan).
  bool _betulSebenar(int i) =>
      i < jawapanSebenar.length ? jawapanSebenar[i] : true;
}
