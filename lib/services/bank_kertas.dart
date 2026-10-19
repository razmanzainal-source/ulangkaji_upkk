import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kertas.dart';

/// Bank soalan UPKK yang dibundelkan bersama app.
///
/// App ini berfungsi **tanpa Internet**. Semua soalan, skema jawapan dan
/// imbasan kertas tahun lepas dibaca daripada aset yang dibundelkan. Bank
/// dimuat sekali sahaja semasa app dibuka, dan hasilnya disimpan dalam ingatan
/// supaya menukar subjek tidak memerlukan bacaan fail lagi.
///
/// Dua jenis data dimuatkan:
///   1. `assets/content/subjek.json` — senarai subjek, format rasmi setiap
///      bahagian, dan senarai imbasan kertas sebenar.
///   2. `assets/content/bank/<id>.json` — himpunan soalan setiap subjek.
class BankKertas {
  BankKertas._();

  static final BankKertas instance = BankKertas._();

  static const String _laluanSubjek = 'assets/content/subjek.json';

  List<Subjek> _subjek = const [];
  final Map<String, List<SoalanKertas>> _bank = {};
  bool _dimuatkan = false;

  /// Mesej ralat yang boleh dipaparkan kepada pengguna, atau `null`.
  String? ralat;

  bool get sedia => _dimuatkan && ralat == null;

  List<Subjek> get subjek => _subjek;

  /// Kertas sebenar yang ada untuk semua subjek — untuk dipaparkan sebagai
  /// senarai panjang.
  List<KertasSebenar> get semuaKertasSebenar => [
        for (final s in _subjek) ...s.kertasSebenar,
      ];

  Subjek? subjekDaripada(String id) {
    for (final s in _subjek) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Himpunan soalan satu subjek.
  List<SoalanKertas> bank(String subjekId) => _bank[subjekId] ?? const [];

  int bilanganSoalan(String subjekId) => bank(subjekId).length;

  /// Bilangan soalan satu subjek bagi bahagian tertentu.
  ///
  /// Bahagian diambil daripada tanda `bahagian` pada soalan; jika soalan tidak
  /// mempunyai tanda itu, jenisnya dipadankan dengan jenis yang diterima oleh
  /// bahagian tersebut mengikut format rasmi.
  int bilanganBahagian(String subjekId, String bahagian) {
    final s = subjekDaripada(subjekId);
    if (s == null) return 0;
    return bank(subjekId).where((q) => sesuaiUntuk(s, q, bahagian)).length;
  }

  /// Adakah satu soalan boleh digunakan untuk bahagian tertentu?
  static bool sesuaiUntuk(Subjek subjek, SoalanKertas soalan, String bahagian) {
    final format = subjek.bahagian.where((b) => b.nama == bahagian).firstOrNull;
    if (format == null) return false;
    if (soalan.bahagian == bahagian) return true;
    if (soalan.bahagian.isNotEmpty) return false;
    return format.jenis.contains(soalan.jenis.teks);
  }

  Future<void> muat() async {
    _dimuatkan = true;
    try {
      final teks = await rootBundle.loadString(_laluanSubjek);
      final json = jsonDecode(teks) as Map<String, dynamic>;
      _subjek = ((json['subjek'] as List?) ?? const [])
          .map((e) => Subjek.dariJson(e as Map<String, dynamic>))
          .toList();

      // Muatkan bank setiap subjek. Kegagalan satu subjek tidak sepatutnya
      // menjadikan seluruh app tidak boleh digunakan — subjek lain mungkin
      // masih lengkap.
      for (final s in _subjek) {
        try {
          final bankTeks = await rootBundle.loadString(
            'assets/content/bank/${s.id}.json',
          );
          final bankJson = jsonDecode(bankTeks) as Map<String, dynamic>;
          _bank[s.id] = ((bankJson['soalan'] as List?) ?? const [])
              .asMap()
              .entries
              .map((e) => SoalanKertas.dariJson(
                    e.value as Map<String, dynamic>,
                    bahagian: (e.value as Map<String, dynamic>)['bahagian']
                            as String? ??
                        '',
                    nombor: e.key + 1,
                  ))
              .toList();
        } catch (e) {
          _bank[s.id] = const [];
        }
      }

      final kosong = _subjek.where((s) => (_bank[s.id] ?? const []).isEmpty);
      ralat = kosong.length == _subjek.length
          ? 'Bank soalan tidak dapat dibaca.'
          : null;
      _subjekKosong = kosong.map((s) => s.id).toSet();
    } catch (e) {
      ralat = 'Bank soalan tidak dapat dibaca: $e';
      _subjek = const [];
    }
  }

  Set<String> _subjekKosong = const {};

  /// Subjek yang banknya gagal dimuatkan — dipaparkan sebagai tidak tersedia.
  bool adaSoalan(String subjekId) =>
      (_bank[subjekId] ?? const []).isNotEmpty && !_subjekKosong.contains(subjekId);

  /// Set semula untuk ujian.
  void setSemula() {
    _dimuatkan = false;
    _subjek = const [];
    _bank.clear();
    _subjekKosong = const {};
    ralat = null;
  }
}

extension _PertamaAtauNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
