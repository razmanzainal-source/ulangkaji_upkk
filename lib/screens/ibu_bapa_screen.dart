import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/pembelian.dart';
import '../tema.dart';
import '../widgets/maskot.dart';

/// Pautan awam (dihoskan di GitHub Pages).
const String urlDasarPrivasi =
    'https://razmanzainal-source.github.io/ulangkaji-upkk-legal/privacy.html';
const String urlSokongan =
    'https://razmanzainal-source.github.io/ulangkaji-upkk-legal/';

/// Benar apabila Versi Penuh sudah dibeli. Jika belum, skrin ibu bapa dibuka
/// dahulu dan hasilnya dikembalikan.
///
/// Semua kemasukan ke mod berbayar mesti melalui fungsi ini supaya kanak-kanak
/// tidak boleh tersentuh skrin pembelian secara tidak sengaja.
Future<bool> pastikanVersiPenuh(BuildContext context) async {
  if (Pembelian.instance.terbuka.value) return true;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const IbuBapaScreen()),
  );
  return Pembelian.instance.terbuka.value;
}

/// Skrin khas untuk ibu bapa dan guru: gerbang umur (parental gate) diikuti
/// pembelian Versi Penuh.
///
/// Apple (Kids Category, garis panduan 1.3) membenarkan peluang pembelian
/// dalam app kanak-kanak **hanya** jika ia berada di kawasan khas di belakang
/// gerbang ibu bapa. Google Play (Families) pula menuntut monetisasi yang
/// tidak memancing klik kanak-kanak. Skrin ini memenuhi kedua-duanya.
class IbuBapaScreen extends StatefulWidget {
  const IbuBapaScreen({super.key});

  @override
  State<IbuBapaScreen> createState() => _IbuBapaScreenState();
}

class _IbuBapaScreenState extends State<IbuBapaScreen> {
  late final int _a;
  late final int _b;
  final TextEditingController _jawapan = TextEditingController();
  bool _lulus = false;
  String? _ralat;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _a = 13 + r.nextInt(6); // 13–18
    _b = 6 + r.nextInt(4); // 6–9
  }

  @override
  void dispose() {
    _jawapan.dispose();
    super.dispose();
  }

  int get _betul => _a * _b;

  void _semakGerbang() {
    if (int.tryParse(_jawapan.text.trim()) == _betul) {
      setState(() {
        _lulus = true;
        _ralat = null;
      });
      return;
    }
    setState(() => _ralat = 'Jawapan tidak tepat. Cuba lagi.');
  }

  Future<void> _bukaPautan(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Pautan gagal dibuka — bukan ralat yang perlu mengganggu pengguna.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.latarSkrin,
      appBar: AppBar(
        backgroundColor: Warna.utama,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Untuk Ibu Bapa & Guru', style: Teks.sederhana),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (!_lulus) _gerbang() else _kedai(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- gerbang

  Widget _gerbang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0D4DE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Warna.utama),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Kawasan khas ibu bapa',
                        style: Teks.sederhana),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bahagian ini mengandungi pilihan pembelian. Untuk meneruskan, '
                'sila jawab soalan di bawah — soalan ini memastikan hanya '
                'orang dewasa membuka bahagian ini.',
                style: Teks.biasa.copyWith(color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Warna.utamaLembut,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: Warna.utama),
                    const SizedBox(width: 10),
                    Text(
                      'Berapakah $_a × $_b ?',
                      style: Teks.besar.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('gerbang-jawapan'),
                controller: _jawapan,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _semakGerbang(),
                decoration: InputDecoration(
                  labelText: 'Jawapan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_ralat != null) ...[
                const SizedBox(height: 8),
                Text(_ralat!,
                    style: Teks.biasa.copyWith(color: Warna.salah)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('gerbang-teruskan'),
                  onPressed: _semakGerbang,
                  style: FilledButton.styleFrom(
                    backgroundColor: Warna.utama,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Teruskan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Latih tubi kekal percuma untuk semua murid. Pembelian hanya '
          'diperlukan untuk mod Percubaan (kertas peperiksaan).',
          style: Teks.kecil.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ kedai

  Widget _kedai() {
    return ValueListenableBuilder<bool>(
      valueListenable: Pembelian.instance.terbuka,
      builder: (context, terbuka, _) {
        if (terbuka) return _sudahBeli();

        return ValueListenableBuilder<String?>(
          valueListenable: Pembelian.instance.harga,
          builder: (context, harga, _) {
            final labelHarga = harga ?? 'RM 9.90';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Warna.utama, Warna.utamaMuda],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Maskot(saiz: 54, mood: MoodMaskot.gembira),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Versi Penuh',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$labelHarga · bayar sekali sahaja',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tiada langganan, tiada bayaran berulang.',
                        style: Teks.label.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0D4DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Ciri(teks: 'Mod Percubaan tanpa had — kertas 70 markah, '
                          '1 jam 15 minit, semua 6 subjek'),
                      _Ciri(teks: 'Kertas UPKK 2024 dan 2025 dalam bentuk digital'),
                      _Ciri(teks: 'Slip keputusan penuh untuk dikongsi'),
                      _Ciri(teks: 'Latih tubi kekal percuma — tiada apa-apa '
                          'yang hilang jika tidak membeli'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: Pembelian.instance.sedangBeli,
                    builder: (context, menunggu, _) => FilledButton.icon(
                      key: const ValueKey('beli-penuh'),
                      onPressed: menunggu ? null : () => Pembelian.instance.beli(),
                      icon: menunggu
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_bag_outlined),
                      label: Text(
                        menunggu ? 'Memproses…' : 'Beli — $labelHarga',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Warna.utama,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('pulihkan-pembelian'),
                    onPressed: Pembelian.instance.pulihkan,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Pulihkan pembelian',
                        style: Teks.biasa),
                    style: TextButton.styleFrom(
                      foregroundColor: Warna.utama,
                    ),
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: Pembelian.instance.mesej,
                  builder: (context, mesej, _) {
                    if (mesej == null) return const SizedBox(height: 4);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(mesej,
                          style: Teks.biasa.copyWith(color: Warna.salah)),
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: Pembelian.instance.kedaiTersedia,
                  builder: (context, ada, _) {
                    if (ada) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Kedai aplikasi tidak tersedia pada peranti ini. '
                        'Pembelian hanya boleh dibuat melalui App Store atau '
                        'Google Play.',
                        style: Teks.kecil.copyWith(color: Colors.black54),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Pembayaran dikendalikan sepenuhnya oleh Apple App Store '
                  'atau Google Play. Aplikasi ini tidak menerima atau menyimpan '
                  'maklumat pembayaran anda.',
                  style: Teks.kecil.copyWith(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _bukaPautan(urlDasarPrivasi),
                      child: const Text('Dasar Privasi', style: Teks.kecil),
                    ),
                    TextButton(
                      onPressed: () => _bukaPautan(urlSokongan),
                      child: const Text('Bantuan', style: Teks.kecil),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sudahBeli() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Warna.betul, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Versi Penuh aktif',
                    style: Teks.sederhana.copyWith(color: Warna.betul)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Semua mod Percubaan dan kertas UPKK digital sudah dibuka. '
            'Terima kasih kerana menyokong app ini.',
            style: Teks.biasa.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup', style: Teks.biasa),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ciri extends StatelessWidget {
  const _Ciri({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded,
                size: 18, color: Warna.betul),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(teks,
                style: Teks.biasa.copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }
}
