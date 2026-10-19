import 'package:flutter/material.dart';

/// Perasaan maskot. Mengubah animasi dan lencana kecil di sudut.
enum MoodMaskot { biasa, gembira, fikir, insaf, hebat }

/// Kanak-kanak perempuan comel bernama **Raz** — rakan belajar anak.
///
/// Raz bertudung pink dan memeluk buku. Gambarnya ialah **lencana bulat**
/// yang dipotong daripada karya ikon app sendiri oleh `tools/potong_maskot.py`,
/// jadi warnanya (pink) sama dengan tema app dan tepinya bergelang putih —
/// boleh diletak atas latar putih mahupun pink tanpa nampak pelik.
///
/// Dua saiz aset dipakai (nama fail mengikut aset semasa dalam
/// `assets/gambar/`):
///   - `maskot_upkk_muka.png` — kepala sahaja, untuk saiz kecil (muka masih
///     jelas walaupun pada 48px);
///   - `maskot_upkk.png` — badan penuh, untuk saiz besar.
///
/// Perasaan ditunjukkan oleh lencana di sudut (lihat [_lencana]) dan oleh
/// denyutan skala.
class Maskot extends StatefulWidget {
  const Maskot({super.key, this.mood = MoodMaskot.biasa, this.saiz = 84});

  final MoodMaskot mood;
  final double saiz;

  @override
  State<Maskot> createState() => _MaskotState();
}

class _MaskotState extends State<Maskot> with SingleTickerProviderStateMixin {
  /// Di bawah saiz ini kepala sahaja dipakai — badan penuh jadi terlalu kecil
  /// untuk dilihat.
  static const double _ambangMuka = 84;

  /// Ikon memangkin tidak boleh mengisi seluruh kotak, kerana denyutan skala
  /// sampai 1.20 (lihat [_skalaMaksimum]). 0.82 x 1.20 = 0.98, jadi Raz tidak
  /// pernah terpotong oleh kotak induknya.
  static const double _nisbahIsi = 0.82;

  late final AnimationController _kawalan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _kawalan.dispose();
    super.dispose();
  }

  double get _skalaMaksimum => switch (widget.mood) {
    MoodMaskot.hebat => 1.26,
    MoodMaskot.gembira => 1.20,
    MoodMaskot.insaf => 1.03,
    MoodMaskot.fikir => 1.06,
    MoodMaskot.biasa => 1.08,
  };

  String get _gambar => widget.saiz < _ambangMuka
      ? 'assets/gambar/maskot_upkk_muka.png'
      : 'assets/gambar/maskot_upkk.png';

  String? get _lencana => switch (widget.mood) {
    MoodMaskot.hebat => '🏆',
    MoodMaskot.gembira => '🎉',
    MoodMaskot.fikir => '💭',
    MoodMaskot.insaf => '💡',
    MoodMaskot.biasa => null,
  };

  @override
  Widget build(BuildContext context) {
    final sisi = widget.saiz * _nisbahIsi;
    return SizedBox(
      width: widget.saiz,
      height: widget.saiz,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _kawalan,
            builder: (context, anak) {
              final t = Curves.easeInOut.transform(_kawalan.value);
              final skala = 1 + (_skalaMaksimum - 1) * t;
              return Transform.scale(scale: skala, child: anak);
            },
            child: Image.asset(
              _gambar,
              width: sisi,
              height: sisi,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (_lencana != null)
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                _lencana!,
                style: TextStyle(fontSize: widget.saiz * 0.34),
              ),
            ),
        ],
      ),
    );
  }
}
