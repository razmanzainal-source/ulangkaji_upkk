import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/rubrik.dart';
import '../services/pemarkah.dart';
import '../tema.dart';
import '../tulisan.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan bertulis (`taip`).
///
/// Meniru soalan Bahagian C kertas UASA: murid menaip jawapan ayat ringkas,
/// kemudian menekan "Semak Jawapan". Markah mengikut skema pemarkahan sebenar
/// (1 idea = 1 markah), jadi papan ini juga memaparkan markah dan — selepas
/// jawapan ditunjukkan — isi mana yang dijumpai dan mana yang belum.
///
/// Widget ini tidak menyimpan keadaan jawapan: skrin yang memiliki
/// [kawalan] dan [markah], sama seperti `PapanPadan` dan `PapanSusun`.
class PapanTaip extends StatelessWidget {
  const PapanTaip({
    super.key,
    required this.kawalan,
    required this.warna,
    required this.rubrik,
    required this.lumpuh,
    required this.onHantar,
    this.markah,
    this.tunjukIdea = false,
    this.jawapanContoh = '',
    this.rumiBayang,
    this.had = hadAksaraJawapan,
    this.bacaSahaja = false,
    this.gayaTaip,
    this.bayang,
    this.onSentuh,
  });

  /// Pengawal teks jawapan. Dimiliki oleh skrin supaya teks kekal apabila
  /// widget dibina semula (contohnya semasa maskot beranimasi).
  final TextEditingController kawalan;

  /// Warna unit untuk sorotan dan butang.
  final Color warna;

  /// Rubrik soalan — untuk senarai isi selepas jawapan ditunjukkan.
  final Rubrik rubrik;

  /// Benar apabila jawapan tidak boleh diubah lagi.
  final bool lumpuh;

  /// Dipanggil apabila murid menekan butang "Siap" pada papan kekunci.
  final ValueChanged<String> onHantar;

  /// `null` belum disemak; jika tidak, keputusan semakan terakhir.
  final Markah? markah;

  /// Benar apabila isi rubrik boleh dipaparkan.
  ///
  /// Isi hanya ditunjukkan selepas murid mencuba dua kali — jika tidak, jawapan
  /// penuh sudah terbuka pada percubaan pertama.
  final bool tunjukIdea;

  /// Contoh jawapan penuh, dipaparkan selepas jawapan ditunjukkan.
  final String jawapanContoh;

  /// Transliterasi Rumi bagi teks bayang (hint) medan taip.
  ///
  /// Medan taip menunjukkan contoh jawapan dalam Jawi; murid dan ibu bapa
  /// yang belum lancar Jawi mungkin tidak dapat membacanya. Rumi dipaparkan
  /// sebagai baris bantuan kecil **di bawah medan**, bukan di dalamnya,
  /// supaya ruang menaip tidak dipenuhi teks panduan yang panjang.
  final String? rumiBayang;

  /// Had aksara. Jawapan UASA Bahagian C cukup satu hingga dua baris ayat,
  /// jadi kotak ini menghalang murid daripada menulis karangan.
  final int had;

  /// Benar apabila medan ini hanya dipaparkan, bukan ditaip terus.
  ///
  /// Soalan Jawi dan Arab dijawab melalui [PapanKekunciTulisan], bukan papan
  /// kekunci telefon: papan kekunci sistem tidak boleh ditukar kepada Jawi,
  /// jadi membiarkannya terbuka hanya menutup separuh skrin dengan papan
  /// kekunci Latin yang tidak berguna.
  final bool bacaSahaja;

  /// Gaya teks jawapan. Jawapan Jawi menggunakan font Jawi.
  final TextStyle? gayaTaip;

  /// Teks bayang di dalam medan taip.
  final String? bayang;

  /// Dipanggil apabila murid menyentuh medan jawapan.
  ///
  /// Dipakai untuk membuka semula papan kekunci jika murid menutupnya tadi.
  final VoidCallback? onSentuh;

  @override
  Widget build(BuildContext context) {
    final keputusan = markah;
    final tanah = switch (keputusan) {
      null => Colors.white,
      _ when keputusan.betul => Warna.latarBetul,
      _ => Warna.latarSalah,
    };
    final tepi = switch (keputusan) {
      null => warna,
      _ when keputusan.betul => Warna.betul,
      _ => Warna.salah,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: tanah,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tepi.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: warna),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tulis jawapan kamu di sini:',
                  style: Teks.sederhana.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _medanTaip(),
          if (_adaRumiBayang) _bayangRumi(),
          _kiraAksara(),
          if (keputusan != null) ...[
            const SizedBox(height: 12),
            _panelMarkah(keputusan),
          ],
        ],
      ),
    );
  }

  Widget _medanTaip() {
    // Arah perenggan mengikut isi jawapan, bukan ikut tetapan skrin. Jawapan
    // Jawi dibaca kanan-ke-kiri; jawapan Rumi dibaca kiri-ke-kanan. Jika arah
    // ditetapkan sekali sahaja, jawapan Jawi yang panjang akan tersusun
    // terbalik — dan jawapan Rumi pula tersusun songsang.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: kawalan,
      builder: (konteks, nilai, _) {
        final kiriKeKanan = !bertulisanArab(nilai.text);
        // Font mengikut isi jawapan juga: jawapan Jawi dipaparkan dengan font
        // Jawi supaya huruf seperti ڠ dan ݢ tidak menjadi kotak kosong,
        // manakala jawapan Rumi kembali kepada font biasa.
        final asas = Teks.biasa.copyWith(fontSize: 18);
        final gaya = kiriKeKanan ? asas : (gayaTaip ?? asas);
        return TextField(
          controller: kawalan,
          enabled: !lumpuh,
          readOnly: bacaSahaja,
          // Kursor mesti kelihatan walaupun papan kekunci sistem tidak dibuka:
          // tanpa kursor, murid tidak tahu di mana hurufnya akan masuk.
          showCursor: true,
          onTap: onSentuh,
          maxLength: had,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          minLines: 2,
          maxLines: 4,
          keyboardType: bacaSahaja
              ? TextInputType.none
              : TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: lumpuh || bacaSahaja ? null : onHantar,
          textAlign: kiriKeKanan ? TextAlign.left : TextAlign.right,
          textDirection:
              kiriKeKanan ? TextDirection.ltr : TextDirection.rtl,
          style: gaya,
          decoration: InputDecoration(
            hintText: bayang ?? 'Contoh: Kerana besi bersentuh dengan air.',
            hintStyle: (gayaTaip ?? asas).copyWith(color: Colors.black38),
            filled: true,
            fillColor: lumpuh ? Colors.white70 : Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: warna.withValues(alpha: 0.4), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: warna.withValues(alpha: 0.4), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: warna, width: 3),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.12),
                width: 2,
              ),
            ),
            counterText: '',
          ),
        );
      },
    );
  }

  /// Benar apabila ada baris Rumi untuk dipaparkan di bawah medan taip.
  bool get _adaRumiBayang =>
      rumiBayang != null && rumiBayang!.trim().isNotEmpty;

  /// Baris bantuan Rumi bagi teks bayang medan taip.
  ///
  /// Ikon terjemah dipakai supaya jelas baris ini ialah panduan bacaan,
  /// bukan sebahagian daripada jawapan.
  Widget _bayangRumi() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.translate_rounded, size: 15, color: Colors.black45),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              rumiBayang!,
              textAlign: TextAlign.left,
              style: Dwibahasa.gayaBarisRumi(),
            ),
          ),
        ],
      ),
    );
  }

  /// Kiraan aksara di bawah kotak taip.
  ///
  /// Kanak-kanak perlu nampak dengan jelas berapa banyak lagi ruang yang ada,
  /// dan had ini mesti kelihatan sebelum dia terlanggar, bukan selepas.
  Widget _kiraAksara() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: kawalan,
      builder: (context, nilai, _) {
        final panjang = nilai.text.length;
        final hampir = panjang >= had * 0.9;
        return Padding(
          padding: const EdgeInsets.only(top: 6, right: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$panjang / $had aksara',
              style: Teks.label.copyWith(
                fontWeight: FontWeight.w700,
                color: hampir
                    ? Warna.tepiNota
                    : Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _panelMarkah(Markah keputusan) {
    final betul = keputusan.betul;
    final warnaMarkah = betul ? Warna.betul : Warna.salah;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              betul ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: warnaMarkah,
              size: 22,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                betul
                    ? 'Betul! Markah: ${keputusan.diperoleh} / ${keputusan.penuh}'
                    : 'Markah: ${keputusan.diperoleh} / ${keputusan.penuh}'
                          ' — cuba tambah isi yang kurang',
                style: Teks.biasa.copyWith(
                  fontWeight: FontWeight.w800,
                  color: warnaMarkah,
                ),
              ),
            ),
          ],
        ),
        if (tunjukIdea) ...[
          const SizedBox(height: 8),
          Text(
            'Isi yang perlu ada:',
            style: Teks.kecil.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < rubrik.idea.length; i++) _barisIdea(i, keputusan),
          if (jawapanContoh.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: warnaMarkah.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jawapan contoh:',
                    style: Teks.label.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jawapanContoh,
                    style: Teks.biasa.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _barisIdea(int i, Markah keputusan) {
    // Rubrik dan keputusan sepatutnya sama panjang; jagaan ini hanya untuk
    // mengelakkan ralat jika bank soalan tidak sepadan.
    if (i >= keputusan.ideaDijumpai.length) return const SizedBox.shrink();
    final ada = keputusan.ideaDijumpai[i];

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ada ? Icons.check_rounded : Icons.close_rounded,
            size: 18,
            color: ada ? Warna.betul : Warna.salah,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rubrik.idea[i].maksud,
              style: Teks.kecil.copyWith(
                color: ada ? Colors.black87 : Colors.black54,
                fontWeight: ada ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
