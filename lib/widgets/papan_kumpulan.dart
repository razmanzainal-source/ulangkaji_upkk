import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan `kumpulan` — kelaskan setiap pernyataan.
///
/// Kertas UPKK memakai bentuk ini pada soalan seperti
///
///     Suaikan pernyataan bahagian (ا) dengan bahagian (ب).
///     (ا) جاڠن مڠهرتيديق مريک
///     (ب) (a) ادب دڠن کلوارک   (b) عاقبت تيدق برادب دڠن کلوارک
///
/// Ia **bukan** padanan satu dengan satu: dua pernyataan boleh tergolong dalam
/// kategori yang sama, dan kategori itu tidak "habis" apabila dipakai. Kerana
/// itu `papan_padan` tidak sesuai — ia memadam pasangan yang sudah dipadankan.
///
/// Setiap pernyataan bernilai satu markah, jadi markah separa dikira.
class PapanKumpulan extends StatelessWidget {
  const PapanKumpulan({
    super.key,
    required this.pernyataan,
    this.rumiPernyataan,
    required this.kategori,
    this.kategoriRumi,
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
  /// [pernyataan]); `null` bermakna tiada panduan Rumi.
  final List<String>? rumiPernyataan;

  /// Label setiap kategori, dalam tulisan kertas asal.
  final List<String> kategori;

  /// Transliterasi Rumi bagi setiap kategori.
  final List<String>? kategoriRumi;

  /// Kategori yang dipilih murid bagi setiap pernyataan; `-1` belum dipilih.
  final List<int> jawapan;

  /// Kategori sebenar bagi setiap pernyataan — kosong semasa menjawab.
  final List<int> jawapanSebenar;

  /// Warna unit untuk sorotan pilihan.
  final Color warna;

  /// Dipanggil apabila murid memilih kategori bagi satu pernyataan.
  final void Function(int indeks, int kategori) onJawab;

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
    final dipilih = i < jawapan.length ? jawapan[i] : -1;

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
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var k = 0; k < kategori.length; k++)
                  _butang(i, k, dipilih: dipilih == k),
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

  Widget _butang(int i, int k, {required bool dipilih}) {
    final betulSebenar = _betulSebenar(i);
    final disemak = betul != null;
    final tepat = k == betulSebenar;

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

    final rumi = k < (kategoriRumi?.length ?? 0) ? kategoriRumi![k] : '';

    return Material(
      color: warnaLatar,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: lumpuh ? null : () => onJawab(i, k),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: warnaLatarTepi, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kategori[k],
                textAlign: TextAlign.center,
                style: Teks.jawiKecil.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              if (rumi.trim().isNotEmpty)
                Text(
                  rumi,
                  textAlign: TextAlign.center,
                  style: Teks.kecil.copyWith(color: Colors.black54),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kategori sebenar pernyataan [i] (untuk paparan selepas semakan).
  int _betulSebenar(int i) =>
      i < jawapanSebenar.length ? jawapanSebenar[i] : -1;
}
