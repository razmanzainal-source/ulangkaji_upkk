import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/kongsi.dart';
import '../services/simpan_gambar.dart';
import '../tema.dart';

/// Skrin semakan sebelum keputusan dikongsi.
///
/// Gambar yang dipaparkan di sini ialah gambar **sebenar** yang akan dihantar.
/// Ia ditangkap daripada kad keputusan dan dihantar sebagai fail, bukan dilukis
/// semula. Jadi apa yang ibu bapa lihat betul-betul sama dengan yang diterima
/// oleh WhatsApp, Facebook, Instagram atau Threads.
///
/// Skrin ini sengaja datang sebelum lembaran kongsi telefon: murid dan ibu
/// bapa boleh melihat gambar itu dahulu, dan boleh menyimpannya ke galeri
/// kalau mereka tidak mahu menghantarnya kepada sesiapa.
class KongsiScreen extends StatefulWidget {
  const KongsiScreen({
    super.key,
    required this.imej,
    required this.teks,
    required this.namaFail,
    required this.namaSimpan,
  });

  /// Bait PNG kad keputusan.
  final Uint8List imej;

  /// Kapsyen yang menemani gambar.
  final String teks;

  /// Nama fail gambar semasa dikongsi (contoh `keputusan-upkk-adab.png`).
  final String namaFail;

  /// Nama tanpa sambungan semasa disimpan ke galeri.
  final String namaSimpan;

  @override
  State<KongsiScreen> createState() => _KongsiScreenState();
}

class _KongsiScreenState extends State<KongsiScreen> {
  bool _menyimpan = false;
  bool _berkongsi = false;

  Future<void> _kongsi() async {
    setState(() => _berkongsi = true);
    final hasil = await Kongsi.kongsiImej(
      imej: widget.imej,
      namaFail: widget.namaFail,
      teks: widget.teks,
    );
    if (!mounted) return;
    setState(() => _berkongsi = false);

    if (hasil == null) {
      _pesan(
        'Perkongsian tidak tersedia pada peranti ini. '
        'Gambar boleh disimpan dan dimuat naik sendiri.',
      );
    }
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    final berjaya = await simpanGambarKeGaleri(
      widget.imej,
      nama: widget.namaSimpan,
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    _pesan(
      berjaya
          ? 'Gambar disimpan. Boleh dimuat naik ke media sosial sendiri.'
          : 'Gambar tidak dapat disimpan. Benarkan akses galeri dan cuba lagi.',
    );
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks, style: Teks.biasa.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.latarSkrin,
      appBar: AppBar(
        backgroundColor: Warna.utama,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Kongsi keputusan', style: Teks.sederhana),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.memory(
                          widget.imej,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapsyen yang akan dihantar',
                            style: Teks.label.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(widget.teks, style: Teks.kecil),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih app dalam senarai: WhatsApp, Facebook, Instagram, '
                      'Threads atau mana-mana app lain pada telefon. '
                      'Ibu bapa sahaja yang menekan butang hantar.',
                      textAlign: TextAlign.center,
                      style: Teks.label.copyWith(
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: Warna.utama,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _berkongsi ? null : _kongsi,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Kongsi', style: Teks.besar),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _menyimpan ? null : _simpan,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Simpan gambar', style: Teks.besar),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
