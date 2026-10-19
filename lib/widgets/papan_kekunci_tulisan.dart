import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema.dart';
import '../tulisan.dart';

/// Gaya teks satu kekunci.
///
/// Huruf Jawi/Arab mesti menggunakan font Jawi — tanpa itu, huruf seperti ڠ
/// dan ݢ dipaparkan sebagai kotak kosong. Huruf Rumi pula **tidak** boleh
/// menggunakan font itu, kerana font Naskh tidak mempunyai glif Latin.
TextStyle _gayaKekunci(String teks, double saiz, Color warna) {
  final asas = bertulisanArab(teks) ? Teks.jawiTaip : const TextStyle();
  return asas.copyWith(
    fontSize: saiz,
    height: 1.1,
    color: warna,
    fontWeight: FontWeight.w600,
  );
}

/// Tulisan yang diperlukan oleh satu soalan bertulis.
///
/// Perbezaannya bukan sekadar hiasan. Jawi memerlukan huruf tambahan Melayu
/// (چ ڠ ڤ ݢ ۏ ڽ ک) dan **tidak** memakai tanda baris, manakala jawapan Bahasa
/// Arab di dalam bank ini bertanda baris penuh (بَيْتٌ) — tanpa tanda baris,
/// jawapan yang betul tidak akan sepadan dengan skema pemarkahan.
enum TulisanKekunci {
  jawi('Jawi'),
  arab('Arab');

  const TulisanKekunci(this.nama);

  /// Nama tulisan untuk dipaparkan kepada ibu bapa.
  final String nama;
}

/// Halaman papan kekunci.
///
/// Kanak-kanak menjawab dalam Jawi, jadi halaman huruf ialah halaman utama.
/// Halaman Rumi dan nombor ialah jalan samping, bukan jalan utama.
enum _Halaman { huruf, nombor, rumi }

/// Papan kekunci Jawi/Arab dalam app.
///
/// **Mengapa app membina papan kekuncinya sendiri.** Flutter tidak boleh
/// menukar bahasa papan kekunci sistem — papan kekunci itu milik pengguna, dan
/// tiada API untuk menukarnya. Kalau app bergantung pada papan kekunci telefon,
/// murid yang telefonnya hanya mempunyai papan kekunci Latin tidak boleh
/// menulis satu huruf Jawi pun, dan **292 soalan bertulis** dalam bank ini
/// menjadi mustahil dijawab. Papan kekunci sendiri juga menjadikan app ini
/// berfungsi sepenuhnya luar talian dan kelihatan sama pada setiap peranti.
///
/// Susunan huruf mengikut abjad hijaiyah (seperti yang murid hafal), bukan
/// susunan papan kekunci komputer. Murid mencari huruf mengikut bunyinya, dan
/// susunan hafalan itulah yang dia kenal.
class PapanKekunciTulisan extends StatefulWidget {
  const PapanKekunciTulisan({
    super.key,
    required this.tulisan,
    required this.warna,
    required this.onAksara,
    required this.onHapus,
    required this.onSelesai,
  });

  /// Tulisan jawapan yang diperlukan oleh soalan semasa.
  ///
  /// Skrin menetapkan nilai ini daripada medan `bahasa` soalan, bukan daripada
  /// soalan itu sendiri — app ini menolak jawapan Rumi pada soalan Jawi, dan
  /// menolak jawapan tanpa tanda baris pada soalan Bahasa Arab.
  final TulisanKekunci tulisan;

  /// Warna subjek — supaya papan kekunci jelas milik soalan yang sedang dibuka.
  final Color warna;

  /// Dipanggil dengan satu aksara untuk dimasukkan ke dalam medan jawapan.
  final ValueChanged<String> onAksara;

  /// Dipanggil untuk memadam aksara sebelum kedudukan kursor.
  final VoidCallback onHapus;

  /// Dipanggil apabila murid menekan kekunci "Siap".
  final VoidCallback onSelesai;

  @override
  State<PapanKekunciTulisan> createState() => _PapanKekunciTulisanState();
}

class _PapanKekunciTulisanState extends State<PapanKekunciTulisan> {
  /// Tinggi satu kekunci huruf.
  static const double _tinggiKunci = 34;

  /// Jarak antara kekunci.
  static const double _jarak = 4;

  /// Bilangan baris yang sentiasa dipaparkan.
  ///
  /// Setiap halaman diisi sehingga bilangan ini. Tanpa pengisian, menukar
  /// halaman akan mengubah tinggi panel dan menolak seluruh skrin naik-turun.
  static const int _bilanganBaris = 6;

  /// Tanda baris yang dipaparkan di atas bulatan kosong supaya kelihatan.
  ///
  /// Tanda baris (fathah, kasrah, dammah) ialah tanda gabungan — dicetak
  /// bersendirian ia cuma menunjukkan bulatan kosong ◌. Bulatan itu hanya
  /// untuk paparan dan **tidak** dimasukkan ke dalam jawapan murid.
  static const String _bulatan = '\u25CC';

  _Halaman _halaman = _Halaman.huruf;

  @override
  void didUpdateWidget(PapanKekunciTulisan lama) {
    super.didUpdateWidget(lama);
    // Bertukar daripada soalan Jawi kepada soalan Arab (atau sebaliknya) mesti
    // bermula semula pada halaman huruf — kalau tidak, murid terpandang
    // halaman nombor yang ditinggalkan soalan sebelumnya.
    if (lama.tulisan != widget.tulisan) {
      _halaman = _Halaman.huruf;
    }
  }

  // --- Susunan kekunci ------------------------------------------------------

  static const List<List<String>> _hurufJawi = [
    ['ا', 'ب', 'ت', 'ث', 'ج', 'چ', 'ح', 'خ'],
    ['د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض'],
    ['ط', 'ظ', 'ع', 'غ', 'ڠ', 'ف', 'ڤ', 'ق'],
    ['ک', 'ݢ', 'ل', 'م', 'ن', 'و', 'ۏ', 'ه'],
    ['ي', 'ڽ', 'ء', 'أ', 'إ', 'آ', 'ؤ', 'ئ'],
    ['ة', 'ى', '،', '؟'],
  ];

  /// Abjad Arab penuh, dengan tanda baris pada baris terakhir.
  ///
  /// Jawapan Bahagian C subjek Bahasa Arab bertanda baris penuh (بَيْتٌ،
  /// مَدْرَسَةٌ), jadi tanda baris mesti ada pada papan kekunci — ia bukan
  /// pilihan tambahan.
  static const List<List<String>> _hurufArab = [
    ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د'],
    ['ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط'],
    ['ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م'],
    ['ن', 'ه', 'و', 'ي', 'ء', 'ة', 'ى', 'أ'],
    ['إ', 'آ', 'ؤ', 'ئ'],
    ['َ', 'ِ', 'ُ', 'ْ', 'ّ', 'ً', 'ٍ', 'ٌ'],
  ];

  /// Angka Arab-Indic dan tanda baca, seperti yang tercetak pada kertas UPKK.
  ///
  /// Tanda baca ada di sini kerana soalan Jawi Bahagian D memang meminta murid
  /// **menulis tanda baca** — tanpa kekunci ini, soalan itu tidak boleh
  /// dijawab langsung.
  static const List<List<String>> _nombor = [
    ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧'],
    ['٨', '٩', '؟', '،', '!', '.', ':', '-'],
  ];

  /// Papan kekunci Rumi, untuk murid yang menjawab dalam Rumi.
  ///
  /// Susunan QWERTY biasa — bukan abjad — kerana murid sudah kenal susunan ini
  /// daripada telefon dan komputer.
  static const List<List<String>> _rumi = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', "'", '-'],
  ];

  /// Tanda baris tunggal — dipaparkan di atas bulatan kosong.
  static const Set<String> _tandaBaris = {
    '\u064B', '\u064C', '\u064D', '\u064E', '\u064F',
    '\u0650', '\u0651', '\u0652',
  };

  List<List<String>> get _barisSemasa {
    final baris = switch (_halaman) {
      _Halaman.huruf =>
        widget.tulisan == TulisanKekunci.arab ? _hurufArab : _hurufJawi,
      _Halaman.nombor => _nombor,
      _Halaman.rumi => _rumi,
    };
    final penuh = <List<String>>[...baris];
    while (penuh.length < _bilanganBaris) {
      penuh.add(const <String>[]);
    }
    return penuh;
  }

  void _tekan(String aksara) {
    // Getaran pendek: murid tahu hurufnya sudah masuk walaupun matanya pada
    // papan kekunci, bukan pada kotak jawapan.
    HapticFeedback.selectionClick();
    widget.onAksara(aksara);
  }

  void _tukarHalaman(_Halaman halaman) {
    HapticFeedback.selectionClick();
    setState(() {
      // Menekan halaman yang sudah terbuka bermakna "kembali ke huruf".
      _halaman = _halaman == halaman ? _Halaman.huruf : halaman;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E4E9),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: LayoutBuilder(
            builder: (konteks, kendala) {
              final baris = _barisSemasa;
              var terpanjang = 1;
              for (final b in baris) {
                if (b.length > terpanjang) terpanjang = b.length;
              }
              // Lebar kekunci diira sekali untuk keseluruhan halaman supaya
              // setiap baris tersusun rapi, walaupun bilangan kekuncinya
              // berbeza (baris huruf 8 kekunci, baris Rumi 10).
              final lebarAda = kendala.maxWidth - _jarak * (terpanjang - 1);
              final lebar = (lebarAda / terpanjang).clamp(26.0, 46.0).toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final satuBaris in baris) _barisKek(satuBaris, lebar),
                  const SizedBox(height: 3),
                  _barisKawalan(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _barisKek(List<String> baris, double lebar) {
    if (baris.isEmpty) {
      return const SizedBox(height: _tinggiKunci + _jarak);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: _jarak),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final aksara in baris)
            _Kekunci(
              paparan: _tandaBaris.contains(aksara) ? '$_bulatan$aksara' : aksara,
              lebar: lebar,
              tinggi: _tinggiKunci,
              onTekan: () => _tekan(aksara),
            ),
        ],
      ),
    );
  }

  Widget _barisKawalan() {
    final tinggi = _tinggiKunci + 4;
    final rumi = _halaman == _Halaman.rumi;

    return Row(
      children: [
        // Tukar halaman. Butang yang sedang aktif diwarnakan penuh supaya
        // murid nampak halaman mana yang terbuka, dan tahu tekan sekali lagi
        // untuk kembali.
        _KekunciKawalan(
          label: rumi ? 'ابج' : 'ABC',
          warna: widget.warna,
          tinggi: tinggi,
          lebar: 54,
          aktif: rumi,
          onTekan: () => _tukarHalaman(_Halaman.rumi),
        ),
        const SizedBox(width: _jarak),
        _KekunciKawalan(
          label: '١٢٣',
          warna: widget.warna,
          tinggi: tinggi,
          lebar: 52,
          aktif: _halaman == _Halaman.nombor,
          onTekan: () => _tukarHalaman(_Halaman.nombor),
        ),
        const SizedBox(width: _jarak),
        Expanded(
          child: _KekunciKawalan(
            ikon: Icons.space_bar_rounded,
            warna: widget.warna,
            tinggi: tinggi,
            onTekan: () => _tekan(' '),
          ),
        ),
        const SizedBox(width: _jarak),
        _KekunciKawalan(
          ikon: Icons.backspace_outlined,
          warna: widget.warna,
          tinggi: tinggi,
          lebar: 56,
          onTekan: () {
            HapticFeedback.selectionClick();
            widget.onHapus();
          },
        ),
        const SizedBox(width: _jarak),
        _KekunciKawalan(
          label: 'سياڤ',
          warna: widget.warna,
          tinggi: tinggi,
          lebar: 68,
          utama: true,
          onTekan: () {
            HapticFeedback.lightImpact();
            widget.onSelesai();
          },
        ),
      ],
    );
  }
}

/// Satu kekunci huruf atau angka.
class _Kekunci extends StatelessWidget {
  const _Kekunci({
    required this.paparan,
    required this.lebar,
    required this.tinggi,
    required this.onTekan,
  });

  /// Aksara yang dipaparkan pada kekunci.
  ///
  /// Berbeza daripada aksara yang dimasukkan hanya bagi tanda baris, yang
  /// dipaparkan di atas bulatan kosong.
  final String paparan;

  final double lebar;
  final double tinggi;
  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _PapanKekunciTulisanState._jarak / 2),
      child: SizedBox(
        width: lebar - _PapanKekunciTulisanState._jarak,
        height: tinggi,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 0.8,
          shadowColor: const Color(0x33000000),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTekan,
            child: Center(
              child: Text(
                paparan,
                textDirection: bertulisanArab(paparan)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: _gayaKekunci(
                  paparan,
                  (lebar * 0.55).clamp(15.0, 22.0),
                  Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kekunci kawalan: tukar halaman, ruang, padam dan siap.
class _KekunciKawalan extends StatelessWidget {
  const _KekunciKawalan({
    this.label,
    this.ikon,
    required this.warna,
    required this.tinggi,
    this.lebar,
    this.aktif = false,
    this.utama = false,
    required this.onTekan,
  });

  final String? label;
  final IconData? ikon;
  final Color warna;
  final double tinggi;
  final double? lebar;

  /// Benar apabila butang ini sedang mengawal halaman yang terbuka.
  final bool aktif;

  /// Benar untuk kekunci utama ("Siap") — diwarnakan supaya jelas.
  final bool utama;

  final VoidCallback onTekan;

  @override
  Widget build(BuildContext context) {
    final latar = utama || aktif
        ? warna
        : Colors.white;
    final depan = utama || aktif ? Colors.white : Colors.black87;

    return SizedBox(
      width: lebar,
      height: tinggi,
      child: Material(
        color: latar,
        borderRadius: BorderRadius.circular(9),
        elevation: utama ? 1.5 : 0.8,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTekan,
          child: Center(
            child: ikon != null
                ? Icon(ikon, size: 19, color: depan)
                : Text(
                    label ?? '',
                    textDirection: bertulisanArab(label ?? '')
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: _gayaKekunci(
                      label ?? '',
                      15,
                      depan,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
