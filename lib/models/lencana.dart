import 'package:flutter/material.dart';

import '../tema.dart';

/// Tahap lencana bagi satu subjek — ikut **markah terbaik** satu kertas.
///
/// Lencana tidak pernah hilang: sekali diperoleh, ia kekal sehingga
/// rekod dipadam. Ini penting untuk murid — sekeping lencana yang hilang
/// apabila kertas seterusnya kurang baik akan mengajar dia bahawa lencana
/// itu bukan milik dia.
///
/// | Tahap | Syarat | Nama |
/// | --- | --- | --- |
/// | `gangsa` | ≥ 70% | Gangsa |
/// | `perak` | ≥ 80% | Perak |
/// | `emas` | ≥ 90% | Emas |
/// | `sempurna` | ≥ 95% | Sempurna |
///
/// Tahap tertinggi **95%**, bukan 100%. Kertas UPKK mempunyai 70 markah,
/// jadi 100% bermaksud tiada satu pun markah hilang - standard yang
/// nyaris tidak boleh dicapai oleh murid yang baru mula. 95% masih tinggi,
/// tetapi boleh dicapai, dan lencana yang mustahil akan mengajar murid
/// bahawa ia bukan milik dia.
enum TahapLencana {
  gangsa(
    peratus: 70,
    tajuk: 'Gangsa',
    penerangan: 'Mencapai 70% dalam subjek ini.',
    ikon: Icons.workspace_premium_rounded,
    warna: Color(0xFFB0713C),
  ),
  perak(
    peratus: 80,
    tajuk: 'Perak',
    penerangan: 'Mencapai 80% dalam subjek ini.',
    ikon: Icons.military_tech_rounded,
    warna: Color(0xFF8E9AAF),
  ),
  emas(
    peratus: 90,
    tajuk: 'Emas',
    penerangan: 'Mencapai 90% dalam subjek ini.',
    ikon: Icons.emoji_events_rounded,
    warna: Color(0xFFD4A017),
  ),
  sempurna(
    peratus: 95,
    tajuk: 'Sempurna',
    penerangan: 'Mencapai 95% dalam subjek ini.',
    ikon: Icons.diamond_rounded,
    warna: Warna.utama,
  );

  const TahapLencana({
    required this.peratus,
    required this.tajuk,
    required this.penerangan,
    required this.ikon,
    required this.warna,
  });

  /// Peratus markah minimum untuk lencana ini diperoleh.
  final int peratus;

  /// Nama lencana — dipaparkan pada kad dan dalam koleksi.
  final String tajuk;

  /// Penerangan ringkas — dipakai pada skrin Pencapaian.
  final String penerangan;

  /// Ikon lencana.
  final IconData ikon;

  /// Warna lencana.
  final Color warna;

  /// Adakah peratus [n] sudah cukup untuk lencana ini?
  bool cukup(int n) => n >= peratus;

  /// Lencana seterusnya yang lebih tinggi — `null` bagi tahap tertinggi.
  TahapLencana? get seterusnya {
    final i = TahapLencana.values.indexOf(this);
    return i + 1 < TahapLencana.values.length ? TahapLencana.values[i + 1] : null;
  }
}

/// Satu lencana yang telah diperoleh.
class Lencana {
  const Lencana({
    required this.id,
    required this.tajuk,
    required this.penerangan,
    required this.ikon,
    required this.warna,
    this.subjekId,
    this.peratus,
  });

  /// Pengenalan unik lencana — disimpan dalam rekod murid.
  ///
  /// Lencana subjek: `subjek-<id subjek>-<tahap>`, contoh
  /// `subjek-arab-emas`. Lencana global: `g-<nama>`.
  final String id;

  final String tajuk;
  final String penerangan;
  final IconData ikon;
  final Color warna;

  /// Subjek yang berkaitan — `null` bagi lencana global.
  final String? subjekId;

  /// Peratus yang diperlukan — `null` bagi lencana global.
  final int? peratus;
}

/// Katalog lencana — sumber tunggal bagi semua lencana dalam app.
///
/// Lencana **subjek** bergantung pada markah terbaik satu kertas percubaan
/// bagi subjek itu. Lencana **global** bergantung pada tabiat mengulang kaji,
/// dan ia dihitung daripada latih tubi **dan** kertas percubaan.
class DaftarLencana {
  DaftarLencana._();

  /// Awalan kunci lencana subjek.
  static const String awalanSubjek = 'subjek-';

  /// Awalan kunci lencana global.
  static const String awalanGlobal = 'g-';

  /// Lencana global — tabiat, bukan markah.
  static const List<Lencana> global = [
    Lencana(
      id: 'g-rajin',
      tajuk: 'Rajin',
      penerangan: 'Belajar tujuh hari berturut-turut.',
      ikon: Icons.local_fire_department_rounded,
      warna: Color(0xFFFF7043),
    ),
    Lencana(
      id: 'g-kilat',
      tajuk: 'Kilat',
      penerangan: 'Sepuluh jawapan betul berturut-turut.',
      ikon: Icons.bolt_rounded,
      warna: Color(0xFFFFC107),
    ),
    Lencana(
      id: 'g-pujangga',
      tajuk: 'Pujangga',
      penerangan: 'Seratus soalan dijawab dengan betul.',
      ikon: Icons.auto_stories_rounded,
      warna: Color(0xFF7E57C2),
    ),
    Lencana(
      id: 'g-konsisten',
      tajuk: 'Konsisten',
      penerangan: 'Tiga kertas berturut-turut mendapat 70% ke atas.',
      ikon: Icons.trending_up_rounded,
      warna: Color(0xFF26A69A),
    ),
    Lencana(
      id: 'g-juara',
      tajuk: 'Juara',
      penerangan: 'Empat lencana markah diperoleh dalam semua subjek.',
      ikon: Icons.stars_rounded,
      warna: Warna.utama,
    ),
  ];

  /// Kunci lencana bagi satu tahap dalam satu subjek.
  static String kunciSubjek(String subjekId, TahapLencana tahap) =>
      '$awalanSubjek$subjekId-${tahap.name}';

  /// Semua lencana bagi satu subjek — daripada tahap terendah ke tertinggi.
  static List<Lencana> subjek(String subjekId, String namaSubjek) => [
        for (final t in TahapLencana.values)
          Lencana(
            id: kunciSubjek(subjekId, t),
            tajuk: t.tajuk,
            penerangan: '$namaSubjek — ${t.penerangan}',
            ikon: t.ikon,
            warna: t.warna,
            subjekId: subjekId,
            peratus: t.peratus,
          ),
      ];

  /// Cari lencana daripada kuncinya.
  ///
  /// Kunci yang tidak dikenali mengembalikan `null` — ini berlaku bila rekod lama
  /// mengandungi lencana yang sudah dibuang daripada katalog, dan lencana itu
  /// hanya perlu dilupakan, bukan membuat app rosak.
  static Lencana? dariKunci(String kunci, {Map<String, String> namaSubjek = const {}}) {
    for (final l in global) {
      if (l.id == kunci) return l;
    }
    for (final id in namaSubjek.keys) {
      for (final t in TahapLencana.values) {
        if (kunci == kunciSubjek(id, t)) {
          return Lencana(
            id: kunci,
            tajuk: t.tajuk,
            penerangan: '${namaSubjek[id]} — ${t.penerangan}',
            ikon: t.ikon,
            warna: t.warna,
            subjekId: id,
            peratus: t.peratus,
          );
        }
      }
    }
    return null;
  }
}
