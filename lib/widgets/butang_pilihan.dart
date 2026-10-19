import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Keadaan satu butang pilihan jawapan.
enum KeadaanPilihan {
  /// Belum dipilih.
  biasa,

  /// Sedang dipilih (dalam mod peperiksaan, sebelum disemak).
  dipilih,

  /// Sudah disemak: jawapan betul.
  betul,

  /// Sudah disemak: jawapan salah.
  salah,
}

/// Butang pilihan jawapan berlabel A, B, C, D — seperti kertas peperiksaan.
///
/// Lencana huruf di sebelah kiri menjadikan pilihan jawapan kelihatan seperti
/// kertas soalan objektif sebenar, dan membantu anak yang belum lancar membaca
/// mengenal pasti pilihan mereka.
class ButangPilihan extends StatelessWidget {
  const ButangPilihan({
    super.key,
    required this.huruf,
    required this.teks,
    this.rumi,
    required this.warna,
    required this.keadaan,
    this.onPilih,
    this.onDengar,
    this.ruangStatus = false,
  });

  /// Huruf lencana: A, B, C, D.
  final String huruf;
  final String teks;

  /// Transliterasi Rumi bagi [teks], dipaparkan sebagai baris kecil di
  /// bawahnya. `null` untuk pilihan gambar — emoji tiada bacaan Rumi.
  final String? rumi;

  /// Warna unit — digunakan untuk keadaan biasa dan dipilih.
  final Color warna;
  final KeadaanPilihan keadaan;

  /// Butang dengar sebutan pilihan ini. `null` menyembunyikannya.
  final VoidCallback? onDengar;

  /// Dijalankan apabila pilihan ditekan. `null` melumpuhkan butang ini.
  final VoidCallback? onPilih;

  /// Simpan ruang untuk tanda ✓/✗ supaya susun atur tidak berganjak
  /// apabila jawapan disemak.
  final bool ruangStatus;

  static const Color _hijau = Color(0xFF2E7D32);
  static const Color _merah = Color(0xFFE53935);

  Color get _warnaTepi => switch (keadaan) {
    KeadaanPilihan.biasa => warna.withValues(alpha: 0.28),
    KeadaanPilihan.dipilih => warna,
    KeadaanPilihan.betul => _hijau,
    KeadaanPilihan.salah => _merah,
  };

  Color get _warnaLatar => switch (keadaan) {
    KeadaanPilihan.biasa => Colors.white,
    KeadaanPilihan.dipilih => warna.withValues(alpha: 0.12),
    KeadaanPilihan.betul => const Color(0xFFE8F5E9),
    KeadaanPilihan.salah => const Color(0xFFFFEBEE),
  };

  Color get _warnaLencana => switch (keadaan) {
    KeadaanPilihan.biasa => const Color(0xFFE0E0E0),
    KeadaanPilihan.dipilih => warna,
    KeadaanPilihan.betul => _hijau,
    KeadaanPilihan.salah => _merah,
  };

  bool get _lencanaTerisi => keadaan != KeadaanPilihan.biasa;

  double get _tepiTebal => keadaan == KeadaanPilihan.biasa ? 2 : 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _warnaLatar,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPilih,
          child: Container(
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _warnaTepi, width: _tepiTebal),
            ),
            child: Row(
              children: [
                _lencana(),
                const SizedBox(width: 12),
                Expanded(child: _teksPilihan()),
                if (onDengar != null)
                  IconButton(
                    onPressed: onDengar,
                    iconSize: 24,
                    color: warna,
                    tooltip: 'Dengar pilihan ini',
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                if (ruangStatus) _status(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lencana() {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _lencanaTerisi ? _warnaLencana : Colors.white,
        border: Border.all(
          color: _lencanaTerisi ? _warnaLencana : warna.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Text(
        huruf,
        style: Teks.lencana.copyWith(
          color: _lencanaTerisi
              ? Colors.white
              : Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  /// Benar apabila pilihan ini hanya gambar (emoji) tanpa perkataan.
  /// Pilihan gambar dipaparkan besar — pilihan teks sentiasa saiz biasa
  /// supaya saiz huruf konsisten antara semua jenis soalan.
  ///
  /// Tulisan Jawi juga dikira teks: huruf Jawi berada dalam blok Arab
  /// (U+0600–U+06FF), jadi pilihan Jawi tidak tersilap dianggap emoji dan
  /// dibesarkan seperti gambar.
  bool get _gambarSahaja => !_hurufAtauAngka.hasMatch(teks);
  static final RegExp _hurufAtauAngka = RegExp(r'[A-Za-z0-9\u0600-\u06FF]');

  Widget _teksPilihan() {
    if (_gambarSahaja) {
      // Emoji bukan ayat Jawi — tiada baris Rumi, dan saiz gambar dikekalkan.
      return Text(teks, textAlign: TextAlign.center, style: Teks.gambar);
    }
    return Dwibahasa(jawi: teks, rumi: rumi);
  }

  Widget _status() {
    return SizedBox(
      width: 34,
      child: switch (keadaan) {
        KeadaanPilihan.betul => const Icon(
          Icons.check_circle_rounded,
          color: _hijau,
          size: 28,
        ),
        KeadaanPilihan.salah => const Icon(
          Icons.cancel_rounded,
          color: _merah,
          size: 28,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
