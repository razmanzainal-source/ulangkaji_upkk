import 'dart:ui' show Color;

/// Gred pencapaian UPKK.
///
/// Julat ini ialah penggredan rasmi Ujian Penilaian Kelas Al-Quran dan Fardu Ain
/// (UPKK) yang disenaraikan oleh Jabatan Agama Islam negeri:
///
/// | Gred | Tahap | Julat |
/// | --- | --- | --- |
/// | A | Cemerlang | 80–100 |
/// | B | Baik | 60–79 |
/// | C | Memuaskan | 40–59 |
/// | D | Kurang Memuaskan | 1–39 |
///
/// Kertas UPKK tidak menggunakan gred E — calon yang tidak hadir atau tidak
/// menjawab langsung tidak diberi gred, bukan diberi gred rendah.
enum Gred {
  a('A', 'Cemerlang', 80, 100, Color(0xFF2E7D32)),
  b('B', 'Baik', 60, 79, Color(0xFF1565C0)),
  c('C', 'Memuaskan', 40, 59, Color(0xFFEF6C00)),
  d('D', 'Kurang Memuaskan', 1, 39, Color(0xFFC62828));

  const Gred(this.huruf, this.nama, this.min, this.max, this.warna);

  /// Huruf gred seperti yang tercetak pada slip keputusan UPKK.
  final String huruf;

  /// Nama tahap dalam Bahasa Melayu.
  final String nama;

  final int min;
  final int max;
  final Color warna;

  /// Gred bagi satu peratus markah.
  ///
  /// Markah 0 tidak termasuk dalam mana-mana gred kerana calon yang tidak
  /// menjawab tidak diberi gred. Bagi kegunaan app, markah 0 dipaparkan sebagai
  /// gred D supaya paparan sentiasa ada gred dan tidak mengelirukan murid.
  static Gred dariPeratus(int peratus) {
    if (peratus >= 80) return Gred.a;
    if (peratus >= 60) return Gred.b;
    if (peratus >= 40) return Gred.c;
    return Gred.d;
  }

  /// Julat gred dalam bentuk teks, contohnya "80–100%".
  String get julatTeks => '$min–$max%';

  /// Adakah gred ini gred tertinggi?
  bool get cemerlang => this == Gred.a;

  /// Gred kelulusan terendah — UPKK menganggap gred D sebagai lulus.
  bool get lulus => true;

  /// Gred yang lebih tinggi, atau gred yang sama jika sudah tertinggi.
  Gred get seterusnya => switch (this) {
        Gred.d => Gred.c,
        Gred.c => Gred.b,
        Gred.b => Gred.a,
        Gred.a => Gred.a,
      };

  /// Bilangan gred — berguna untuk memaparkan rangkaian gred pada laporan.
  static int get bilangan => Gred.values.length;
}
