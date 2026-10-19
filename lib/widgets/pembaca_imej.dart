import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema.dart';

/// Latar gelap pembaca kertas sebenar.
///
/// Pembaca sengaja gelap supaya helaian imbasan putih menonjol — sama seperti
/// membaca di atas meja gelap. Warna ini bukan warna tema, jadi ia kekal
/// gelap walaupun warna tema app berubah.
const Color _latarGelap = Color(0xFF17141D);

/// Permukaan bar kawalan dan jalur thumbnail — sedikit lebih cerah daripada
/// latar supaya kawalan kelihatan berasingan tanpa mencuri tumpuan daripada
/// kertas.
const Color _permukaanGelap = Color(0xFF262130);

/// Satu muka surat yang boleh dizum dengan jari.
///
/// Imej disarung dalam kad putih supaya kelihatan seperti helaian kertas.
/// `InteractiveViewer` membolehkan anak mengezum sampai 5 kali untuk membaca
/// tulisan Jawi yang kecil pada imbasan, kemudian kembali ke saiz asal.
class PembacaImej extends StatelessWidget {
  const PembacaImej({super.key, required this.laluan});

  /// Laluan aset imej, contoh `assets/kertas/adab-2024/muka01.jpg`.
  final String laluan;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InteractiveViewer(
        // 1.0 ialah saiz asal. Mengecilkan lagi tidak berguna kerana butiran
        // imbasan terus kabur, dan 5.0 cukup untuk tulisan Jawi terkecil.
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image(
              // Guna pembina lalai (bukan `Image.asset`) kerana hanya ia
              // menyokong `loadingBuilder` — imbasan saiz penuh mengambil
              // masa untuk dinyahkod selepas fail aset dibaca.
              image: AssetImage(laluan),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              // Beri tanda kemajuan supaya anak tahu muka surat sedang
              // dimuatkan dan bukan tergantung.
              loadingBuilder: (context, anak, kemajuan) {
                if (kemajuan == null) return anak;
                return const Center(child: CircularProgressIndicator());
              },
              // Kegagalan imej tidak boleh meninggalkan skrin kosong — kad
              // mesej dipaparkan sebagai ganti supaya anak tahu apa berlaku
              // dan boleh teruskan ke muka surat lain.
              errorBuilder: (context, ralat, jejak) => const _KadImejGagal(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kad mesej apabila satu muka surat gagal dimuatkan.
///
/// Dipaparkan di dalam kad putih pembaca, jadi teks hitam kekal mudah dibaca.
class _KadImejGagal extends StatelessWidget {
  const _KadImejGagal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              size: 46,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 10),
            Text(
              'Imej tidak dapat dimuatkan',
              textAlign: TextAlign.center,
              style: Teks.biasa.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Muka surat ini tiada atau tidak dapat dibaca. Teruskan ke muka '
              'surat lain.',
              textAlign: TextAlign.center,
              style: Teks.label.copyWith(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pembaca satu kertas peperiksaan: satu muka surat satu halaman.
///
/// Anak boleh menatal dengan jari (PageView), mengezum (InteractiveViewer),
/// melompat melalui gelangsar atau jalur thumbnail ("Kertas penuh"), dan
/// menggunakan anak panah papan kekunci pada web atau desktop.
class PembacaKertasSebenar extends StatefulWidget {
  const PembacaKertasSebenar({
    super.key,
    required this.tajuk,
    required this.imej,
  });

  /// Tajuk bar atas, contoh "Adab 2024".
  final String tajuk;

  /// Laluan imej setiap muka surat, mengikut susunan fail asal.
  final List<String> imej;

  @override
  State<PembacaKertasSebenar> createState() => _PembacaKertasSebenarState();
}

class _PembacaKertasSebenarState extends State<PembacaKertasSebenar> {
  /// Mengawal PageView. Dicipta sekali sahaja supaya kedudukan semasa tidak
  /// hilang apabila `setState` berlaku (contoh: ketika membuka jalur anak).
  final PageController _kawalanMuka = PageController();

  /// Indeks muka surat semasa (0 bermaksud muka surat pertama).
  int _muka = 0;

  /// Sama ada jalur thumbnail "Kertas penuh" sedang terbuka.
  bool _jalurTerbuka = false;

  int get _jumlah => widget.imej.length;

  /// Gaya butang besar mesra kanak-kanak: sasaran ketuk tinggi dan teks
  /// daripada skala `Teks` yang sama seperti seluruh app.
  final ButtonStyle _gayaButang = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    backgroundColor: Warna.utama,
    foregroundColor: Colors.white,
    disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
    textStyle: Teks.sederhana,
    padding: const EdgeInsets.symmetric(horizontal: 10),
  );

  @override
  void dispose() {
    _kawalanMuka.dispose();
    super.dispose();
  }

  /// Pergi ke muka surat lain.
  ///
  /// `lancar: false` digunakan oleh gelangsar supaya halaman mengikut jari
  /// tanpa animasi berganda yang menyekat gelangsar.
  void _pergiKe(int indeks, {bool lancar = true}) {
    if (indeks < 0 || indeks >= _jumlah) return;
    if (indeks == _muka) return;
    if (lancar) {
      _kawalanMuka.animateToPage(
        indeks,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    } else {
      _kawalanMuka.jumpToPage(indeks);
    }
    setState(() => _muka = indeks);
  }

  void _sebelum() => _pergiKe(_muka - 1);

  void _seterusnya() => _pergiKe(_muka + 1);

  /// Anak panah kiri/kanan papan kekunci (web dan desktop).
  ///
  /// Hanya `KeyDownEvent` diterima — `KeyRepeatEvent` diabaikan supaya
  /// menahan anak panah tidak meluru melepasi banyak muka surat sekaligus.
  KeyEventResult _kunci(FocusNode nod, KeyEvent peristiwa) {
    if (peristiwa is! KeyDownEvent) return KeyEventResult.ignored;
    if (peristiwa.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _sebelum();
      return KeyEventResult.handled;
    }
    if (peristiwa.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seterusnya();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _latarGelap,
      appBar: AppBar(
        backgroundColor: _latarGelap,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.tajuk,
          style: Teks.sederhana.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Focus(
          // Autofocus supaya anak panah terus berfungsi tanpa perlu mengetik
          // pemapar dahulu.
          autofocus: true,
          onKeyEvent: _kunci,
          child: Column(
            children: [
              _nota(),
              if (_jalurTerbuka) _jalurAnak(),
              Expanded(child: _halaman()),
              _barKawalan(),
            ],
          ),
        ),
      ),
    );
  }

  /// Nota kecil di atas pembaca — supaya ibu bapa faham imbasan ini asli dan
  /// nombor muka mengikut susunan fail, bukan nombor rasmi kertas.
  Widget _nota() {
    return Container(
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Imbasan kertas sebenar. Nombor muka surat mengikut susunan '
              'fail asal.',
              style: Teks.label.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Jalur thumbnail ("Kertas penuh") — untuk lompat terus ke muka surat
  /// mana-mana tanpa menggesek satu-satu.
  Widget _jalurAnak() {
    return Container(
      height: 118,
      color: _permukaanGelap,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        itemCount: _jumlah,
        itemBuilder: (context, indeks) {
          final semasa = indeks == _muka;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: Key('jalur-muka-${indeks + 1}'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pergiKe(indeks),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 78,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: semasa ? Warna.utamaMuda : Colors.white24,
                        width: semasa ? 3 : 1,
                      ),
                    ),
                    child: Image.asset(
                      widget.imej[indeks],
                      // `contain` — supaya seluruh muka surat kelihatan dalam
                      // thumbnail, bukan dipotong.
                      fit: BoxFit.contain,
                      // Thumbnail gagal dimuatkan → nombor muka tetap
                      // dipaparkan supaya jalur tidak berlubang kosong.
                      errorBuilder: (context, ralat, jejak) => Center(
                        child: Text(
                          '${indeks + 1}',
                          style: Teks.label.copyWith(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${indeks + 1}',
                    style: Teks.label.copyWith(
                      color: semasa ? Warna.utamaMuda : Colors.white70,
                      fontWeight: semasa ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _halaman() {
    return PageView.builder(
      controller: _kawalanMuka,
      itemCount: _jumlah,
      onPageChanged: (indeks) => setState(() => _muka = indeks),
      itemBuilder: (context, indeks) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: PembacaImej(laluan: widget.imej[indeks]),
      ),
    );
  }

  /// Bar bawah: nombor muka, gelangsar lompat, dan butang besar.
  Widget _barKawalan() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: const BoxDecoration(
        color: _permukaanGelap,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Muka ${_muka + 1} / $_jumlah',
                  style: Teks.biasa.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _jalurTerbuka = !_jalurTerbuka),
                icon: Icon(
                  _jalurTerbuka
                      ? Icons.grid_off_rounded
                      : Icons.grid_view_rounded,
                  size: 20,
                ),
                label: Text(_jalurTerbuka ? 'Tutup jalur' : 'Kertas penuh'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Warna.utamaMuda,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
              thumbColor: Colors.white,
              overlayColor: Warna.utamaMuda.withValues(alpha: 0.18),
              valueIndicatorColor: Warna.utama,
              valueIndicatorTextStyle: Teks.label.copyWith(color: Colors.white),
            ),
            child: Slider(
              value: _muka.toDouble(),
              // Gelangsar perlukan max > min; kertas satu muka surat sahaja
              // tidak munasabah, tetapi jangan biarkan ia melontar ralat.
              max: _jumlah > 1 ? (_jumlah - 1).toDouble() : 1,
              divisions: _jumlah > 1 ? _jumlah - 1 : null,
              label: 'Muka ${_muka + 1}',
              onChanged: _jumlah > 1
                  ? (nilai) => _pergiKe(nilai.round(), lancar: false)
                  : null,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _muka > 0 ? _sebelum : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Sebelum'),
                  style: _gayaButang,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _muka < _jumlah - 1 ? _seterusnya : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Seterusnya'),
                  style: _gayaButang,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
