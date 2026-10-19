import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan `padan` — padankan item kiri dengan item kanan.
///
/// Widget ini tidak menyimpan keadaan: skrin yang menguruskan padanan, dan
/// widget ini hanya melaporkan ketukan. Cara guna: ketik satu item kiri
/// (ia bertukar warna), kemudian ketik padanannya di senarai bawah.
class PapanPadan extends StatelessWidget {
  const PapanPadan({
    super.key,
    required this.kiri,
    required this.kanan,
    required this.indeksKanan,
    required this.padanan,
    required this.warna,
    required this.onPilihKiri,
    required this.onPilihKanan,
    this.onDengarKiri,
    this.onDengarKanan,
    this.rumiKiri,
    this.rumiKanan,
    this.terpilih,
    this.lumpuh = false,
    this.betul,
  });

  /// Label lajur kiri — susunan asal, tidak dikocok.
  final List<String> kiri;

  /// Label lajur kanan mengikut susunan paparan (dikocok).
  final List<String> kanan;

  /// Indeks pasangan asal bagi setiap slot [kanan].
  final List<int> indeksKanan;

  /// Padanan semasa: indeks kiri (asal) ke indeks kanan (asal).
  final Map<int, int> padanan;

  /// Warna unit untuk sorotan item yang dipilih.
  final Color warna;

  /// Dipanggil dengan indeks kiri (asal) apabila item kiri diketuk.
  final ValueChanged<int> onPilihKiri;

  /// Dipanggil dengan indeks kanan (asal) apabila item kanan diketuk.
  final ValueChanged<int> onPilihKanan;

  /// Butang dengar bagi item kiri (indeks asal). `null` menyembunyikannya.
  final ValueChanged<int>? onDengarKiri;

  /// Butang dengar bagi item kanan (indeks asal). `null` menyembunyikannya.
  final ValueChanged<int>? onDengarKanan;

  /// Transliterasi Rumi bagi setiap item [kiri] (indeks sama).
  ///
  /// Jika ia tiada atau panjangnya tidak sepadan, item kiri dipaparkan
  /// dalam Jawi sahaja.
  final List<String>? rumiKiri;

  /// Transliterasi Rumi bagi setiap slot [kanan] mengikut susunan paparan.
  ///
  /// Skrin mengocok [kanan], jadi ia mesti mengocok senarai ini serentak —
  /// pasangan Jawi–Rumi akan tersasar jika kedua-duanya tidak sepadan.
  final List<String>? rumiKanan;

  /// Indeks kiri (asal) yang sedang dipilih, jika ada.
  final int? terpilih;

  /// Benar apabila jawapan tidak boleh diubah lagi.
  final bool lumpuh;

  /// `null` belum disemak; `true`/`false` keputusan semakan.
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
        children: [
          for (var i = 0; i < kiri.length; i++) _barisKiri(i),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  terpilih == null
                      ? 'Ketik satu item di atas, kemudian pilih padanannya.'
                      : 'Sekarang pilih padanan untuk item yang berwarna.',
                  style: Teks.kecil,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (var j = 0; j < kanan.length; j++) _cipKanan(j)],
          ),
        ],
      ),
    );
  }

  Widget _barisKiri(int i) {
    final dipilih = terpilih == i;
    final padanAsal = padanan[i];
    final slot = padanAsal == null ? null : indeksKanan.indexOf(padanAsal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: dipilih ? warna.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: lumpuh ? null : () => onPilihKiri(i),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dipilih ? warna : warna.withValues(alpha: 0.28),
                width: dipilih ? 3 : 2,
              ),
            ),
            child: Row(
              children: [
                _nomborKiri(i + 1, dipilih),
                const SizedBox(width: 10),
                // Teks dan cip padanan disusun menegak: label yang panjang
                // mengalir ke bawah, bukan menghimpit teks sebelahnya.
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Dwibahasa(
                        jawi: kiri[i],
                        rumi: Dwibahasa.rumiSelari(rumiKiri, i, kiri.length),
                      ),
                      if (slot != null) ...[
                        const SizedBox(height: 6),
                        _cipPadan(
                          kanan[slot],
                          Dwibahasa.rumiSelari(rumiKanan, slot, kanan.length),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDengarKiri != null)
                  IconButton(
                    onPressed: () => onDengarKiri!(i),
                    iconSize: 22,
                    color: warna,
                    tooltip: 'Dengar',
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nomborKiri(int nombor, bool dipilih) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dipilih ? warna : Colors.white,
        border: Border.all(color: warna.withValues(alpha: 0.35), width: 2),
      ),
      child: Text(
        '$nombor',
        style: Teks.lencana.copyWith(
          color: dipilih ? Colors.white : Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _cipPadan(String teks, String? rumi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      // IntrinsicWidth: cip ini nota padanan, jadi ia mengekalkan saiz
      // kandungannya. Tanpanya Dwibahasa akan meluaskan cip sehingga penuh.
      child: IntrinsicWidth(
        child: Dwibahasa(
          jawi: teks,
          rumi: rumi,
          // Cip kecil — guna saiz `jawiKecil` dari tema supaya ia kekal
          // sebagai nota padanan di bawah item kiri, bukan menandingi teks
          // utama item itu.
          gayaJawi: Teks.jawiKecil,
        ),
      ),
    );
  }

  Widget _cipKanan(int j) {
    final asal = indeksKanan[j];
    final digunakan = padanan.containsValue(asal);

    return Material(
      color: digunakan ? warnaLatarCipDigunakan : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: (lumpuh || digunakan) ? null : () => onPilihKanan(asal),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: digunakan
                  ? Colors.black.withValues(alpha: 0.12)
                  : warna.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (digunakan) ...[
                const Icon(Icons.check_rounded, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                // IntrinsicWidth: pil kanan kekal sebesar kandungannya —
                // tanpanya baris Rumi akan meluaskan pil sehingga penuh.
                child: IntrinsicWidth(
                  child: Dwibahasa(
                    jawi: kanan[j],
                    rumi: Dwibahasa.rumiSelari(rumiKanan, j, kanan.length),
                    gayaJawi: Teks.jawi.copyWith(
                      color: digunakan
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (onDengarKanan != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => onDengarKanan!(asal),
                  iconSize: 20,
                  color: warna,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Dengar',
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const Color warnaLatarCipDigunakan = Color(0xFFECEFF1);
}
