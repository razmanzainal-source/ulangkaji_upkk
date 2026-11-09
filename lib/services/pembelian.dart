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

  /// ID produk pada kedua-dua kedai. Semuanya **consumable** (boleh dibeli
  /// berulang kali).
  static const List<String> idTip = ['tip_3', 'tip_5', 'tip_10'];

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
        idTip.toSet(),
      );
      if (hasil.productDetails.isEmpty) {
        if (hasil.error != null) mesej.value = hasil.error!.message;
        return;
      }
      final peta = <String, String>{};
      for (final p in hasil.productDetails) {
        _produk[p.id] = p;
        peta[p.id] = p.price;
      }
      harga.value = peta;
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
      if (idTip.contains(d.productID)) {
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

  /// Mulakan pembelian tip bagi [id].
  Future<void> beli(String id) async {
    if (sedangBeli.value) return;
    mesej.value = null;

    if (_produk.isEmpty) await _tanyaKedai();
    final produk = _produk[id];
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

  @visibleForTesting
  Future<void> lupakan() async {
    await _langganan?.cancel();
    _langganan = null;
    _sedia = false;
    _produk.clear();
    kedaiTersedia.value = false;
    harga.value = {};
    mesej.value = null;
    sedangBeli.value = false;
  }
}
