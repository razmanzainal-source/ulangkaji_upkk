import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan `susun` — susun item mengikut urutan betul.
///
/// Item dipindahkan dengan **seret**: pemegang di kanan kad boleh terus
/// diseret, manakala kad itu sendiri boleh diseret selepas ditahan seketika.
/// Dua cara kerana kanak-kanak kecil selalunya terus menekan kad dan menariknya,
/// tetapi kad mesti kekal boleh ditekan untuk butang 🔊.
///
/// Widget ini tidak menyimpan keadaan: skrin yang menyimpan susunan semasa dan
/// mengubahnya apabila [onSusun] dipanggil.
class PapanSusun extends StatelessWidget {
  const PapanSusun({
    super.key,
    required this.item,
    this.rumiItem,
    required this.warna,
    required this.onSusun,
    this.onDengar,
    this.lumpuh = false,
    this.betul,
  });

  /// Label item mengikut susunan semasa (paling atas dahulu).
  ///
  /// Setiap label mesti unik dalam satu soalan — ia digunakan sebagai kunci
  /// widget supaya animasi seretan tidak tersalah kad. Bank soalan menjamin
  /// ini (`test/bank_soalan_test.dart`).
  final List<String> item;

  /// Transliterasi Rumi bagi setiap item, **selari dengan susunan semasa**
  /// [item].
  ///
  /// Apabila murid menyeret kad, skrin mesti memindahkan item dalam kedua-dua
  /// senarai serentak — jika tidak, pasangan Jawi–Rumi akan tersasar daripada
  /// kadnya walaupun kedua-dua senarai itu masih sama panjang.
  final List<String>? rumiItem;

  /// Warna unit untuk lencana nombor dan pemegang seret.
  final Color warna;

  /// Pindahkan item daripada kedudukan [lama] ke kedudukan [baru].
  ///
  /// [baru] ialah indeks akhir selepas item dikeluarkan, jadi skrin boleh
  /// terus melakukan `insert(baru, removeAt(lama))`.
  final void Function(int lama, int baru)? onSusun;

  /// Dengar sebutan item pada kedudukan ini. `null` menyembunyikannya.
  final ValueChanged<int>? onDengar;

  /// Benar apabila murid tidak lagi boleh menjawab (soalan sudah disemak).
  final bool lumpuh;

  /// `null` belum disemak; `true`/`false` keputusan semakan.
  final bool? betul;

  @override
  Widget build(BuildContext context) {
    final tanah = switch (betul) {
      null => Colors.transparent,
      true => Warna.latarBetul,
      false => Warna.latarSalah,
    };
    final tepi = switch (betul) {
      null => null,
      true => Warna.betul,
      false => Warna.salah,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tanah,
        borderRadius: BorderRadius.circular(22),
        border: tepi == null ? null : Border.all(color: tepi, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView(
            // Senarai ini hidup di dalam halaman soalan yang sudah boleh
            // ditatal, jadi ia sendiri tidak perlu menatal.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            primary: false,
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            proxyDecorator: _kadDiangkat,
            onReorderItem: _susun,
            children: [
              for (var i = 0; i < item.length; i++)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(item[i]),
                  index: i,
                  enabled: !lumpuh,
                  child: _baris(i),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: warna),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tahan dan seret kad untuk susun mengikut urutan betul.',
                  style: Teks.kecil,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Selamatkan kedudukan sasaran daripada senarai boleh susun.
  ///
  /// `onReorderItem` sudah melaraskan indeks untuk item yang dikeluarkan, jadi
  /// [baru] terus boleh digunakan dengan `insert`.
  void _susun(int lama, int baru) {
    if (lumpuh || onSusun == null) return;
    if (lama < 0 || lama >= item.length) return;
    if (baru < 0 || baru >= item.length) return;
    if (baru == lama) return;
    onSusun!(lama, baru);
  }

  /// Kad yang sedang diseret diangkat sedikit supaya jelas ia sedang bergerak.
  Widget _kadDiangkat(Widget anak, int indeks, Animation<double> animasi) {
    return AnimatedBuilder(
      animation: animasi,
      builder: (konteks, isi) => Material(
        color: Colors.transparent,
        elevation: 8 * animasi.value,
        shadowColor: warna.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        child: isi,
      ),
      child: anak,
    );
  }

  Widget _baris(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: warna.withValues(alpha: 0.28), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: warna.withValues(alpha: 0.16),
              ),
              child: Text('${i + 1}', style: Teks.lencana),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Dwibahasa(
                jawi: item[i],
                rumi: Dwibahasa.rumiSelari(rumiItem, i, item.length),
              ),
            ),
            if (onDengar != null)
              IconButton(
                onPressed: () => onDengar!(i),
                iconSize: 22,
                color: warna,
                tooltip: 'Dengar',
                icon: const Icon(Icons.volume_up_rounded),
              ),
            _pemegang(i),
          ],
        ),
      ),
    );
  }

  /// Pemegang seret di kanan kad.
  ///
  /// Tidak seperti kad itu sendiri, pemegang ini mula diseret dengan serta-merta
  /// — kanak-kanak tidak perlu tahu bahawa kad perlu ditahan dahulu.
  Widget _pemegang(int i) {
    return Tooltip(
      message: 'Seret untuk susun',
      child: ReorderableDragStartListener(
        index: i,
        enabled: !lumpuh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Icon(
            Icons.drag_indicator_rounded,
            size: 28,
            color: lumpuh ? Colors.black26 : warna.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
