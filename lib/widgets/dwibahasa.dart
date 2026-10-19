import 'package:flutter/material.dart';

import '../tema.dart';

/// Teks Jawi dengan baris transliterasi Rumi di bawahnya.
///
/// Kertas UPKK ditulis dalam tulisan Jawi. Murid dan ibu bapa yang belum
/// lancar Jawi memerlukan panduan Rumi, tetapi ayat Jawi mesti kekal sebagai
/// teks utama — jadi baris Rumi sengaja lebih kecil, lebih lembut warnanya,
/// dan tidak pernah menggantikan ayat Jawi.
///
/// Dua penjajaran digunakan serentak: Jawi mengikut [selaras] (lalai kanan,
/// kerana Jawi dibaca kanan ke kiri) manakala Rumi sentiasa kiri. Kanak-kanak
/// menyapu pandangan dari satu baris ke baris seterusnya, jadi setiap teks
/// mesti bermula pada pangkal bacaannya sendiri.
///
/// Baris Rumi dipaparkan mengikut [TunjukRumi]: latih tubi mengekalkannya
/// sebagai panduan belajar, manakala kertas percubaan menanggalkannya supaya
/// paparan menyerupai kertas UPKK sebenar.
class Dwibahasa extends StatelessWidget {
  const Dwibahasa({
    super.key,
    required this.jawi,
    this.rumi,
    this.gayaJawi,
    this.gayaRumi,
    this.selaras = TextAlign.right, // Jawi dibaca kanan ke kiri.
    this.kananKeKiri = true,
  });

  /// Ayat Jawi — teks utama.
  final String jawi;

  /// Transliterasi Rumi. `null` atau kosong menyembunyikan baris ini.
  final String? rumi;

  /// Ganti gaya Jawi; `null` menggunakan [Teks.jawi] daripada tema.
  final TextStyle? gayaJawi;

  /// Ganti saiz dan ketebalan baris Rumi. Warnanya kekal [warnaRumi]
  /// supaya baris panduan ini tidak pernah kelihatan seperti teks utama.
  final TextStyle? gayaRumi;

  /// Penjajaran teks Jawi.
  final TextAlign selaras;

  /// Arah tulisan Jawi — `true` (lalai) kerana Jawi ditulis kanan ke kiri.
  final bool kananKeKiri;

  /// Warna baris Rumi — hitam lembut, bukan hitam penuh.
  static const Color warnaRumi = Colors.black54;

  /// Gaya baris Rumi, dikongsi dengan papan yang melukis barisnya sendiri.
  ///
  /// Contohnya ayat tempat kosong mengadun cip jawapan di dalam ayat, jadi
  /// ayatnya tidak boleh melalui [Dwibahasa]; baris Rumi di bawahnya masih
  /// perlu kelihatan sama seperti di tempat lain.
  static TextStyle gayaBarisRumi([TextStyle? ganti]) =>
      (ganti ?? Teks.rumi).copyWith(color: warnaRumi);

  /// Baris Rumi pada kedudukan [i], atau `null` jika tiada padanan.
  ///
  /// Senarai Rumi mesti **selari** dengan senarai Jawi: panjang sama dan
  /// susunan sama. Bank soalan lama langsung tiada medan Rumi, dan data
  /// separuh siap pula senarainya mungkin tidak sepadan. Dalam semua kes itu
  /// papan jawapan jatuh balik kepada teks Jawi sahaja — paparan yang
  /// berkurang lebih baik daripada papan yang tidak dapat dimuatkan.
  static String? rumiSelari(List<String>? senarai, int i, int bilanganJawi) {
    if (senarai == null || senarai.length != bilanganJawi) return null;
    if (i < 0 || i >= senarai.length) return null;
    return senarai[i];
  }

  bool get _adaRumi => rumi != null && rumi!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final teksJawi = Text(
      jawi,
      textAlign: selaras,
      textDirection: kananKeKiri ? TextDirection.rtl : null,
      style: gayaJawi ?? Teks.jawi,
    );

    // Semasa murid menjawab kertas (bukan latih tubi) baris Rumi
    // disembunyikan — lihat [TunjukRumi].
    if (!_adaRumi || !TunjukRumi.of(context)) return teksJawi;

    // Kedua-dua baris dibiarkan memenuhi lebar yang ada — hanya dengan
    // begitu penjajaran kanan (Jawi) dan kiri (Rumi) benar-benar kelihatan
    // apabila ayat berpindah ke baris kedua.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        teksJawi,
        const SizedBox(height: 2),
        Text(rumi!, textAlign: TextAlign.left, style: gayaBarisRumi(gayaRumi)),
      ],
    );
  }
}

/// Menentukan sama ada baris Rumi dipaparkan kepada widget di bawahnya.
///
/// Kertas UPKK sebenar **langsung tiada** Rumi: keseluruhan kertas ditulis
/// dalam Jawi, dan arahan pada kulit kertasnya berbunyi "calon dikehendaki
/// menjawab semua soalan dalam tulisan Jawi". Jadi semasa murid menjawab
/// kertas, paparan dibuat menyerupai kertas sebenar — baris Rumi ditanggalkan
/// supaya dia benar-benar berlatih membaca Jawi.
///
/// Latih tubi pula mengekalkan Rumi: tujuannya mengajar, bukan meniru
/// peperiksaan. Skrin yang tidak menyediakan [TunjukRumi] (halaman semak dan
/// skrin keputusan) kekal memaparkan Rumi.
class TunjukRumi extends InheritedWidget {
  const TunjukRumi({super.key, required this.tunjuk, required super.child});

  /// Benar apabila baris Rumi patut dipaparkan.
  final bool tunjuk;

  /// Nilai semasa; lalai `true` apabila tiada [TunjukRumi] di atasnya.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TunjukRumi>()?.tunjuk ?? true;

  @override
  bool updateShouldNotify(TunjukRumi lama) => lama.tunjuk != tunjuk;
}
