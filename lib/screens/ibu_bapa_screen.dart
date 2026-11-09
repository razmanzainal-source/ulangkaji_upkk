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

/// Skrin khas untuk ibu bapa dan guru: gerbang matematik diikuti pilihan
/// memberi **tip sukarela**.
///
/// App Store (Kids Category, 1.3) membenarkan peluang pembelian dalam app
/// kanak-kanak **hanya** di kawasan khas di belakang gerbang ibu bapa.
/// Google Play (Families) menuntut monetisasi yang tidak memancing klik
/// kanak-kanak. Skrin ini memenuhi kedua-duanya.
///
/// **Tiada kandungan dikunci.** Tip tidak membuka apa-apa.
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
    // Tambah sahaja (bukan sifir) — cukup untuk menghalang kanak-kanak
    // menekan butang pembelian secara tidak sengaja, tetapi pantas untuk
    // ibu bapa.
    _a = 4 + r.nextInt(6); // 4–9
    _b = 3 + r.nextInt(7); // 3–9
  }

  @override
  void dispose() {
    _jawapan.dispose();
    super.dispose();
  }

  int get _betul => _a + _b;

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
          if (!_lulus) _gerbang() else _tip(),
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
                'Bahagian ini untuk orang dewasa. Untuk meneruskan, sila jawab '
                'soalan di bawah.',
                style: Teks.biasa.copyWith(color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Warna.utamaLembut,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: Warna.utama),
                    const SizedBox(width: 10),
                    Text(
                      'Berapakah $_a + $_b ?',
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------- tip

  Widget _tip() {
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
                      'Sokongan Sukarela',
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
                'App ini percuma sepenuhnya. Jika ia membantu anak atau murid '
                'awak, anda boleh memberi tip sebagai tanda sokongan.',
                style: Teks.label
                    .copyWith(color: Colors.white, height: 1.5, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0D4DE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 19, color: Warna.utama),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip tidak membuka atau mengunci apa-apa. Semua soalan, '
                  'kertas dan suara bacaan tetap percuma untuk semua orang.',
                  style: Teks.kecil.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<Map<String, String>>(
          valueListenable: Pembelian.instance.harga,
          builder: (context, harga, _) {
            return Column(
              children: [
                for (final id in Pembelian.idTip) ...[
                  _butangTip(id, harga[id]),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: Pembelian.instance.mesej,
          builder: (context, mesej, _) {
            if (mesej == null) return const SizedBox(height: 6);
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                mesej,
                style: Teks.biasa.copyWith(
                  color: mesej.startsWith('Terima kasih')
                      ? Warna.betul
                      : Warna.salah,
                ),
              ),
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
                'Kedai aplikasi tidak tersedia pada peranti ini. Tip hanya '
                'boleh dibuat melalui App Store atau Google Play.',
                style: Teks.kecil.copyWith(color: Colors.black54),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Pembayaran diproses sepenuhnya oleh Apple App Store atau Google '
          'Play. Aplikasi ini tidak menerima atau menyimpan maklumat '
          'pembayaran anda. Tip tidak boleh dipulihkan kerana ia bukan '
          'pembelian kandungan.',
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
  }

  Widget _butangTip(String id, String? harga) {
    final label = harga ?? _hargaLalai(id);
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder<bool>(
        valueListenable: Pembelian.instance.sedangBeli,
        builder: (context, menunggu, _) => FilledButton.icon(
          key: ValueKey('tip-$id'),
          onPressed: menunggu ? null : () => Pembelian.instance.beli(id),
          icon: menunggu
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.favorite_rounded, size: 19),
          label: Text(
            'Beri tip $label',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Warna.utama,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  /// Harga lalai jika kedai belum membalas (contoh: offline).
  String _hargaLalai(String id) => switch (id) {
        'tip_3' => 'RM 3.00',
        'tip_5' => 'RM 5.00',
        _ => 'RM 10.00',
      };
}
