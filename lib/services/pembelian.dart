import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengurus pembelian dalam app untuk ciri **Versi Penuh** (mod Percubaan).
///
/// Semua kandungan ulang kaji (Latih tubi) kekal percuma. Yang berbayar ialah
/// mod peperiksaan: kertas percubaan 70 markah dan kertas UPKK digital.
///
/// Pembayaran dikendalikan sepenuhnya oleh App Store (Apple) atau Play Store
/// (Google). Aplikasi ini tidak menerima sebarang maklumat pembayaran.
class Pembelian {
  Pembelian._();

  static final Pembelian instance = Pembelian._();

  /// ID produk yang sama pada kedua-dua kedai.
  static const String idProduk = 'ulangkaji_upkk_full';

  static const String kunciSimpan = 'pembelian_penuh';

  /// Benar apabila Versi Penuh sudah dibeli (atau dipulihkan).
  final ValueNotifier<bool> terbuka = ValueNotifier<bool>(false);

  /// Benar apabila kedai boleh dihubungi pada peranti ini.
  final ValueNotifier<bool> kedaiTersedia = ValueNotifier<bool>(false);

  /// Harga setempat yang dipaparkan oleh kedai (contoh "RM 9.90").
  final ValueNotifier<String?> harga = ValueNotifier<String?>(null);

  /// Mesej terakhir untuk dipaparkan pada skrin pembelian.
  final ValueNotifier<String?> mesej = ValueNotifier<String?>(null);

  /// Benar semasa permintaan pembelian sedang berjalan.
  final ValueNotifier<bool> sedangBeli = ValueNotifier<bool>(false);

  ProductDetails? _produk;
  StreamSubscription<List<PurchaseDetails>>? _langganan;
  bool _sedia = false;

  /// Muatkan status pembelian tersimpan dan tanya kedai.
  ///
  /// Selamat dipanggil walaupun kedai tidak tersedia (contohnya dalam ujian
  /// atau pada peranti tanpa perkhidmatan Play/App Store): semua ralat
  /// ditelan supaya app tetap boleh digunakan secara percuma.
  Future<void> muat() async {
    if (_sedia) return;
    _sedia = true;

    try {
      final p = await SharedPreferences.getInstance();
      terbuka.value = p.getBool(kunciSimpan) ?? false;
    } catch (_) {
      terbuka.value = false;
    }

    _pasangPendengar();
    await _tanyaKedai();
  }

  Future<void> _tanyaKedai() async {
    try {
      final ada = await InAppPurchase.instance.isAvailable();
      kedaiTersedia.value = ada;
      if (!ada) return;

      final hasil = await InAppPurchase.instance.queryProductDetails({
        idProduk,
      });
      if (hasil.productDetails.isEmpty) {
        if (hasil.error != null) mesej.value = hasil.error!.message;
        return;
      }
      _produk = hasil.productDetails.first;
      harga.value = _produk!.price;
    } catch (_) {
      kedaiTersedia.value = false;
    }
  }

  void _pasangPendengar() {
    _langganan ??= InAppPurchase.instance.purchaseStream.listen(
      _proses,
      onError: (Object _) => sedangBeli.value = false,
    );
  }

  Future<void> _proses(List<PurchaseDetails> senarai) async {
    for (final d in senarai) {
      if (d.productID == idProduk) {
        switch (d.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _buka();
            mesej.value = null;
            break;
          case PurchaseStatus.pending:
            mesej.value = 'Pembelian sedang diproses…';
            break;
          case PurchaseStatus.canceled:
            mesej.value = 'Pembelian dibatalkan.';
            break;
          case PurchaseStatus.error:
            mesej.value = d.error?.message ?? 'Pembelian gagal. Cuba lagi.';
            break;
        }
      }
      if (d.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(d);
        } catch (_) {
          // Diabaikan: pembelian sudah direkodkan oleh kedai.
        }
      }
    }
    sedangBeli.value = false;
  }

  Future<void> _buka() async {
    terbuka.value = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(kunciSimpan, true);
    } catch (_) {
      // Prestasi storan gagal tidak menghalang pembelian yang sah.
    }
  }

  /// Mulakan pembelian Versi Penuh.
  Future<void> beli() async {
    if (sedangBeli.value) return;
    mesej.value = null;

    if (_produk == null) {
      await _tanyaKedai();
    }
    if (_produk == null) {
      mesej.value = 'Produk tidak tersedia buat masa ini. Cuba sebentar lagi.';
      return;
    }

    sedangBeli.value = true;
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _produk!),
      );
    } catch (e) {
      sedangBeli.value = false;
      mesej.value = 'Pembelian tidak dapat dimulakan.';
    }
  }

  /// Pulihkan pembelian yang pernah dibuat (contohnya selepas tukar peranti).
  Future<void> pulihkan() async {
    mesej.value = null;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      mesej.value = 'Pemulihan tidak dapat dijalankan.';
    }
  }

  /// Untuk ujian: tetapkan status tanpa kedai.
  @visibleForTesting
  void tetapkanUntukUjian({required bool terbuka}) {
    this.terbuka.value = terbuka;
  }

  @visibleForTesting
  Future<void> lupakan() async {
    _langganan?.cancel();
    _langganan = null;
    _sedia = false;
    _produk = null;
    terbuka.value = false;
    kedaiTersedia.value = false;
    harga.value = null;
    mesej.value = null;
    sedangBeli.value = false;
  }
}
