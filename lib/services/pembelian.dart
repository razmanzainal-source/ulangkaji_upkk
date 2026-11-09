import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Tip sukarela (in-app purchase) untuk menyokong pembangunan app.
///
/// **Penting:** app ini percuma sepenuhnya. Tip tidak membuka, tidak mengunci
/// dan tidak mengubah sebarang kandungan. Ia semata-mata tanda sokongan,
/// diletakkan di kawasan khas ibu bapa di belakang gerbang matematik (syarat
/// App Store Kids Category 1.3 dan Google Play Families).
class Pembelian {
  Pembelian._();

  static final Pembelian instance = Pembelian._();

  /// Tier tip dalam ringgit. Susunan ini juga susunan butang pada skrin.
  ///
  /// Setiap tier boleh mempunyai dua ID produk:
  ///  1. ID gaya bundle (`com.razmanzainal.ulangkajiUpkk.tip3`) — sama seperti
  ///     app Wira Kira (Math Hero).
  ///  2. ID lama ringkas (`tip_3`).
  ///
  /// Kedua-duanya ditanya serentak; yang wujud di kedai akan digunakan. Ini
  /// membolehkan app berfungsi walaupun produk baru belum dicipta di App Store
  /// Connect / Play Console.
  static const List<int> tierTip = [3, 5, 10];

  static const Map<int, List<String>> _idMengikutTier = {
    3: ['com.razmanzainal.ulangkajiUpkk.tip3', 'tip_3'],
    5: ['com.razmanzainal.ulangkajiUpkk.tip5', 'tip_5'],
    10: ['com.razmanzainal.ulangkajiUpkk.tip10', 'tip_10'],
  };

  /// Semua ID produk yang ditanya kepada kedai.
  static List<String> get semuaId => [
        for (final ids in _idMengikutTier.values) ...ids,
      ];

  /// ID produk yang benar-benar tersedia, mengikut tier (3 → id).
  final ValueNotifier<Map<int, String>> idAktif = ValueNotifier({});

  /// Benar apabila kedai boleh dihubungi pada peranti ini.
  final ValueNotifier<bool> kedaiTersedia = ValueNotifier<bool>(false);

  /// Harga setempat bagi setiap produk (ID → "RM 5.00").
  final ValueNotifier<Map<String, String>> harga = ValueNotifier({});

  /// Mesej terakhir untuk dipaparkan pada skrin tip.
  final ValueNotifier<String?> mesej = ValueNotifier<String?>(null);

  /// Benar semasa permintaan pembelian sedang berjalan.
  final ValueNotifier<bool> sedangBeli = ValueNotifier<bool>(false);

  final Map<String, ProductDetails> _produk = {};
  StreamSubscription<List<PurchaseDetails>>? _langganan;
  bool _sedia = false;

  /// Tanya kedai tentang produk tip. Selamat gagal — app tetap berfungsi.
  Future<void> muat() async {
    if (_sedia) return;
    _sedia = true;
    _pasangPendengar();
    await _tanyaKedai();
  }

  Future<void> _tanyaKedai() async {
    try {
      final ada = await InAppPurchase.instance.isAvailable();
      kedaiTersedia.value = ada;
      if (!ada) return;

      final hasil = await InAppPurchase.instance.queryProductDetails(
        semuaId.toSet(),
      );
      for (final p in hasil.productDetails) {
        _produk[p.id] = p;
      }
      if (_produk.isEmpty) {
        if (hasil.error != null) mesej.value = hasil.error!.message;
        return;
      }
      _kemasKiniTier();
    } catch (_) {
      kedaiTersedia.value = false;
    }
  }

  /// Tentukan ID produk mana yang mewakili setiap tier. ID gaya bundle
  /// diutamakan; jika tiada, ID lama digunakan.
  void _kemasKiniTier() {
    final aktif = <int, String>{};
    final petaHarga = <int, String>{};
    for (final tier in tierTip) {
      for (final id in _idMengikutTier[tier]!) {
        final produk = _produk[id];
        if (produk != null) {
          aktif[tier] = id;
          petaHarga[tier] = produk.price;
          break;
        }
      }
    }
    idAktif.value = aktif;
    harga.value = {
      for (final e in petaHarga.entries) '${e.key}': e.value,
    };
  }

  void _pasangPendengar() {
    _langganan ??= InAppPurchase.instance.purchaseStream.listen(
      _proses,
      onError: (Object _) => sedangBeli.value = false,
    );
  }

  Future<void> _proses(List<PurchaseDetails> senarai) async {
    for (final d in senarai) {
      if (semuaId.contains(d.productID)) {
        switch (d.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            mesej.value = 'Terima kasih atas sokongan anda!';
            break;
          case PurchaseStatus.pending:
            mesej.value = 'Pembayaran sedang diproses…';
            break;
          case PurchaseStatus.canceled:
            mesej.value = 'Tiada pembelian dibuat.';
            break;
          case PurchaseStatus.error:
            mesej.value = d.error?.message ?? 'Pembelian gagal. Cuba lagi.';
            break;
        }
      }
      if (d.pendingCompletePurchase) {
        try {
          // Tip ialah produk consumable — ia mesti diselesaikan (consume)
          // supaya boleh dibeli semula pada masa hadapan.
          await InAppPurchase.instance.completePurchase(d);
        } catch (_) {
          // Diabaikan: kedai sudah merekodkan pembelian.
        }
      }
    }
    sedangBeli.value = false;
  }

  /// Mulakan pembelian tip bagi [tier] (3, 5 atau 10).
  Future<void> beli(int tier) async {
    if (sedangBeli.value) return;
    mesej.value = null;

    if (_produk.isEmpty) await _tanyaKedai();

    final id = idAktif.value[tier] ?? _cariIdTersedia(tier);
    final produk = id == null ? null : _produk[id];
    if (produk == null) {
      mesej.value =
          'Produk tidak tersedia buat masa ini. Sila cuba sebentar lagi.';
      return;
    }

    sedangBeli.value = true;
    try {
      await InAppPurchase.instance.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: produk),
        autoConsume: true,
      );
    } catch (_) {
      sedangBeli.value = false;
      mesej.value = 'Pembelian tidak dapat dimulakan.';
    }
  }

  String? _cariIdTersedia(int tier) {
    for (final id in _idMengikutTier[tier] ?? const <String>[]) {
      if (_produk.containsKey(id)) return id;
    }
    return null;
  }

  @visibleForTesting
  Future<void> lupakan() async {
    await _langganan?.cancel();
    _langganan = null;
    _sedia = false;
    _produk.clear();
    kedaiTersedia.value = false;
    idAktif.value = {};
    harga.value = {};
    mesej.value = null;
    sedangBeli.value = false;
  }
}
