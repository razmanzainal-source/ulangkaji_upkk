import 'package:flutter/foundation.dart';

import '../models/rubrik.dart';

/// Hasil pemarkahan satu jawapan bertulis.
class Markah {
  const Markah({
    required this.diperoleh,
    required this.penuh,
    required this.ideaDijumpai,
  });

  /// Bilangan idea yang dijumpai dalam jawapan murid.
  final int diperoleh;

  /// Markah penuh soalan (bilangan idea dalam rubrik).
  final int penuh;

  /// Sama panjang dengan `rubrik.idea` — benar bagi idea yang dijumpai.
  final List<bool> ideaDijumpai;

  /// Jawapan dianggap betul hanya apabila semua idea dijumpai, sama seperti
  /// skema pemarkahan UASA: murid perlu menyatakan kesemua isi yang diminta.
  bool get betul => penuh > 0 && diperoleh == penuh;

  bool get adaMarkah => diperoleh > 0;

  static const Markah kosong = Markah(penuh: 0, diperoleh: 0, ideaDijumpai: []);
}

/// Enjin pemarkahan soalan bertulis (`taip`) — berjalan sepenuhnya luar talian.
///
/// Pemarkahan meniru skema pemarkahan UASA: **1 idea = 1 markah**. Enjin ini
/// mencari setiap isi rubrik dalam jawapan murid, dengan tiga kelonggaran supaya
/// murid Tahun 5 tidak dihukum kerana perkara yang bukan kesalahannya:
///
/// 1. **Imbuhan diabaikan** — "mengangkut" dikira sama dengan "angkut",
///    "peredaran" sama dengan "edar" (lihat [varian]).
/// 2. **Sinonim diterima** — senarai `kata` setiap idea boleh memuatkan
///    beberapa pilihan, contohnya `["udara", "oksigen"]`.
/// 3. **Salah eja bertoleransi** — jarak Levenshtein kecil diterima
///    ("pepru" dikira "peparu"), mengikut panjang perkataan.
/// 4. **Angka dikekalkan** — jawapan seperti tahun ("1950") ditanda, tetapi
///    mesti tepat: padanan kabur hanya bermula pada lima huruf.
/// 5. **Jawi dan Arab difahami** — murid menaip jawapan dalam tulisan Jawi
///    melalui papan kekunci dalam app. Tanda baris (harakat) diabaikan, dan
///    kod huruf yang berbeza bagi bunyi yang sama disamakan (lihat
///    [normalHuruf]) supaya jawapan Jawi yang betul tidak mendapat sifar
///    markah hanya kerana kaf Jawi dan kaf Arab ialah dua kod berlainan.
///
/// Enjin ini **tidak** menilai tatabahasa atau mutu ayat, dan tidak boleh
/// memahami ayat yang maksudnya betul tetapi tidak memakai mana-mana perkataan
/// rubrik. Oleh itu UI mesti sentiasa memaparkan jawapan contoh selepas
/// menyemak supaya murid tetap belajar walaupun markahnya tersasar.
class Pemarkah {
  const Pemarkah._();

  /// Kesan setiap idea rubrik dalam [jawapan] murid.
  static Markah semak(Rubrik rubrik, String jawapan) {
    if (!rubrik.ada) return Markah.kosong;

    final senaraiKata = perkataan(jawapan);
    // Setiap perkataan murid diterjemah kepada bentuk dasarnya sekali sahaja —
    // satu jawapan boleh dibandingkan dengan berpuluh idea dan sinonim.
    final calon = [for (final k in senaraiKata) varian(k)];

    final dijangka = [
      for (final idea in rubrik.idea) _ideaDijumpai(idea, calon, jawapan),
    ];

    return Markah(
      diperoleh: dijangka.where((d) => d).length,
      penuh: rubrik.markah,
      ideaDijumpai: dijangka,
    );
  }

  static bool _ideaDijumpai(
    Idea idea,
    List<Set<String>> calon,
    String jawapanMentah,
  ) {
    for (final kata in idea.kata) {
      // Kata kunci boleh mengandungi beberapa perkataan ("basuh muka"). Setiap
      // perkataan itu hanya perlu **ada** dalam jawapan murid — jadi murid yang
      // menulis "muka dibasuh" tetap dikira menjumpai isi "basuh muka".
      final perlu = perkataan(kata);
      if (perlu.isEmpty) {
        // Soalan "tulis tanda baca" menjadikan tanda baca itu sendiri sebagai
        // kata kunci ("؟", ".", ":"). Tanda baca dibuang semasa memecahkan
        // perkataan, jadi tiada apa yang tinggal untuk dibandingkan — ia
        // dibandingkan terus dengan jawapan murid.
        final tanda = kata.trim();
        if (tanda.isNotEmpty && jawapanMentah.contains(tanda)) return true;
        continue;
      }
      if (perlu.every((p) => _adaDalam(calon, varian(p)))) return true;
    }
    return false;
  }

  /// Benar apabila mana-mana bentuk [dasar] ada dalam senarai calon.
  static bool _adaDalam(List<Set<String>> calon, Set<String> dasar) {
    for (final c in calon) {
      if (dasar.any(c.contains)) return true;
      if (_adaYangHampir(dasar, c)) return true;
    }
    return false;
  }

  /// Benar apabila ada sepasang bentuk kata yang hampir sama ejaannya.
  static bool _adaYangHampir(Set<String> a, Set<String> b) {
    for (final x in a) {
      for (final y in b) {
        if (hampirSama(x, y)) return true;
      }
    }
    return false;
  }

  /// Pecahkan teks kepada perkataan huruf kecil tanpa tanda baca.
  ///
  /// Sengkang dan noktah dikira pemisah, jadi "paru-paru" menjadi perkataan
  /// "paru" dan "paru" — sama seperti murid menulis "paru paru". Angka
  /// dikekalkan supaya jawapan seperti tahun ("1950") boleh ditanda.
  ///
  /// Setiap perkataan melalui [normalHuruf], jadi "تنداکن" yang ditaip tanpa
  /// baris tetap sama dengan "تنداکن" yang bertanda baris dalam rubrik.
  @visibleForTesting
  static List<String> perkataan(String teks) {
    final bersih = _asingkan(teks);
    if (bersih.isEmpty) return const [];
    final keluar = <String>[];
    for (final mentah in bersih.split(' ')) {
      final p = normalHuruf(mentah);
      if (p.isNotEmpty) keluar.add(p);
    }
    return keluar;
  }

  /// Buang tanda baca, kekalkan huruf Latin, angka dan huruf Arab/Jawi.
  ///
  /// Tanda baca Arab mesti dibuang **sebelum** penapis huruf, kerana koma
  /// Arab (U+060C) dan koma bertitik (U+061B) berada di dalam julat kod
  /// tulisan Arab dan akan terlepas daripada penapis itu. Tanpa langkah ini,
  /// "بَيْتٌ،" menjadi perkataan "بيت،" dan tidak lagi sepadan dengan kata
  /// kunci "بَيْتٌ" — jawapan penuh murid hanya mendapat markah item terakhir,
  /// iaitu item yang tiada koma di hujungnya.
  static String _asingkan(String teks) => teks
      .toLowerCase()
      .replaceAll(_tandaBacaArab, ' ')
      .replaceAll(_bukanHuruf, ' ')
      .trim();

  /// Kod huruf yang mewakili **bunyi yang sama** dalam Jawi dan Arab.
  ///
  /// Bank soalan tidak konsisten: ia menulis kaf Jawi (U+06A9) 3,531 kali dan
  /// kaf Arab (U+0643) 372 kali untuk bunyi yang sama. Murid yang menaip huruf
  /// yang betul dengan kod yang berbeza tidak sepatutnya dihukum, jadi kedua-
  /// duanya disamakan sebelum sebarang perbandingan.
  static const Map<String, String> _samaHuruf = {
    '\u0643': '\u06A9', // ك kaf Arab        -> ک kaf Jawi
    '\u06CC': '\u064A', // ی ya Farsi        -> ي ya
    '\u0649': '\u064A', // ى alif maksura    -> ي ya
    '\u067E': '\u06A4', // پ peh Farsi       -> ڤ pa Jawi
    '\u06AF': '\u0762', // گ gaf Farsi       -> ݢ ga Jawi
  };

  static final RegExp _polaArab = RegExp(
    '[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
  );

  /// Tanda baca yang berada di dalam julat kod tulisan Arab.
  ///
  /// Koma Arab (U+060C), koma bertitik (U+061B), tanda soal (U+061F), noktah
  /// Urdu (U+06D4) dan pemisah angka Arab (U+066B, U+066C) ialah tanda baca,
  /// bukan huruf.
  static final RegExp _tandaBacaArab = RegExp(
    '[\u060C\u061B\u061F\u066A-\u066D\u06D4\u06DD\u06DE]',
  );

  /// Semua aksara yang bukan huruf Latin, angka atau huruf Arab/Jawi.
  static final RegExp _bukanHuruf = RegExp(
    '[^a-z0-9\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]+',
  );

  /// Benar apabila [teks] mengandungi sekurang-kurangnya satu huruf Arab/Jawi.
  static bool _adaHurufArab(String teks) => _polaArab.hasMatch(teks);

  /// Bentuk perbandingan bagi satu perkataan Arab/Jawi.
  ///
  /// Tanda baris (harakat) dan tatweel dibuang. Murid Tahun 5 tidak menaip
  /// baris dengan tekun, dan Jawi memang lazim ditulis tanpa baris — jadi
  /// "تنداکن" dan "تنداقن" yang bertanda baris mesti dikira sama.
  static String normalHuruf(String teks) {
    final buf = StringBuffer();
    for (final unit in teks.codeUnits) {
      if (unit == 0x0640 || _tandaBaris(unit)) continue;
      buf.write(_samaHuruf[String.fromCharCode(unit)] ?? String.fromCharCode(unit));
    }
    return buf.toString();
  }

  /// Benar bagi tanda baris (harakat) dan tanda bacaan Quran — semuanya
  /// mengubah sebutan, bukan huruf.
  static bool _tandaBaris(int unit) =>
      (unit >= 0x064B && unit <= 0x065F) ||
      unit == 0x0670 ||
      (unit >= 0x06D6 && unit <= 0x06ED);


  /// Semua bentuk kata dasar yang mungkin bagi satu perkataan.
  ///
  /// Contohnya "mengangkut" menghasilkan {"mengangkut", "angkut"}, dan
  /// "peredaran" menghasilkan {"peredaran", "redaran", "peredar", "edar"}.
  ///
  /// Bentuk yang lebih pendek daripada [_panjangMinimum] dibuang — ini
  /// menghalang potongan imbuhan yang terlalu agresif ("kelas" menjadi "elas")
  /// daripada disalah anggap sebagai perkataan lain.
  @visibleForTesting
  static Set<String> varian(String perkataan) {
    // Perkataan Arab/Jawi tidak mengikut sistem imbuhan Melayu: "meN-" bukan
    // imbuhan, dan kata tiga huruf seperti "نية" ialah kata penuh, bukan
    // bentuk yang terlalu pendek untuk dipotong. Ia dikembalikan sebagaimana
    // adanya supaya kata kunci Jawi dalam rubrik tidak hilang.
    if (_adaHurufArab(perkataan)) {
      return perkataan.isEmpty ? const <String>{} : {perkataan};
    }

    final hasil = <String>{perkataan};
    final asas = <String>{perkataan};

    for (final awalan in _awalan) {
      if (!perkataan.startsWith(awalan)) continue;
      final baki = perkataan.substring(awalan.length);
      if (baki.isEmpty) continue;
      asas.add(baki);

      // meN-/peN- menelan huruf pertama kata dasar (k, p, s, t) — pulihkan.
      final pulih = _pulih[awalan];
      if (pulih != null && _vokal.contains(baki[0])) asas.add('$pulih$baki');
    }

    // Akhiran dibuang daripada **setiap** bentuk asas, termasuk bentuk yang
    // dipulihkan. Tanpa langkah ini, "menyejukkan" hanya menghasilkan
    // "sejukkan" dan tidak pernah sepadan dengan kata kunci "sejuk".
    for (final bentuk in asas.toList()) {
      for (final akhiran in _akhiran) {
        if (bentuk.length > akhiran.length && bentuk.endsWith(akhiran)) {
          asas.add(bentuk.substring(0, bentuk.length - akhiran.length));
        }
      }
    }

    for (final bentuk in asas) {
      if (bentuk.length >= _panjangMinimum) hasil.add(bentuk);
    }
    return hasil;
  }

  /// Benar apabila [a] dan [b] hampir sama ejaannya.
  ///
  /// Toleransi mengikut perkataan yang lebih pendek: perkataan empat huruf ke
  /// bawah mesti sama tepat ("air" tidak sama dengan "ais"), 5–7 huruf boleh
  /// tersalah satu huruf, dan 8 huruf ke atas dua huruf.
  ///
  /// Fungsi ini juga digunakan oleh model kertas untuk menilai jawapan bertulis
  /// yang tidak mempunyai rubrik, jadi ia bukan khusus untuk ujian.
  static bool hampirSama(String a, String b) {
    if (a == b) return true;
    final pendek = a.length < b.length ? a.length : b.length;
    if (pendek <= _panjangMinimum) return false;
    final had = pendek <= 7 ? 1 : 2;
    if ((a.length - b.length).abs() > had) return false;
    return jarak(a, b) <= had;
  }

  /// Jarak Levenshtein antara dua perkataan.
  @visibleForTesting
  static int jarak(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var sebelum = List<int>.generate(b.length + 1, (i) => i);
    var sekarang = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      sekarang[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final kos = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var nilai = sebelum[j - 1] + kos;
        if (sebelum[j] + 1 < nilai) nilai = sebelum[j] + 1;
        if (sekarang[j - 1] + 1 < nilai) nilai = sekarang[j - 1] + 1;
        sekarang[j] = nilai;
      }
      final sementara = sebelum;
      sebelum = sekarang;
      sekarang = sementara;
    }
    return sebelum[b.length];
  }

  /// Perkataan lebih pendek daripada ini tidak dipotong imbuhannya.
  static const int _panjangMinimum = 4;

  static const String _vokal = 'aeiou';

  /// Awalan yang dibuang, daripada yang terpanjang kepada yang terpendek.
  static const List<String> _awalan = [
    'memper', 'menge', 'penge', 'meng', 'meny', 'peng', 'peny',
    'mem', 'men', 'pem', 'pen', 'ber', 'ter', 'per', 'di', 'ke', 'se',
    'me', 'pe', 'be', 'te',
  ];

  /// Akhiran yang dibuang.
  static const List<String> _akhiran = ['nya', 'kan', 'an', 'i'];

  /// Huruf yang ditelan oleh awalan meN-/peN-, untuk dipulihkan.
  static const Map<String, String> _pulih = {
    'mem': 'p',
    'men': 't',
    'meny': 's',
    'meng': 'k',
    'pem': 'p',
    'pen': 't',
    'peny': 's',
    'peng': 'k',
  };
}

/// Had aksara jawapan bertulis.
///
/// Jawapan UASA Bahagian C hanya perlukan satu hingga dua baris ayat, jadi
/// kotak taip dihadkan supaya murid menulis isi, bukan karangan.
const int hadAksaraJawapan = 150;
