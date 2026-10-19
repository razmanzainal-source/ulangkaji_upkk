import 'package:flutter/material.dart';

import '../tema.dart';
import 'dwibahasa.dart';

/// Papan jawapan untuk soalan `tempat_kosong` — gaya UASA Bahagian B.
///
/// Murid mengisi setiap tempat kosong dengan perkataan daripada bank perkataan
/// yang disediakan, sama seperti kertas peperiksaan sekolah. Cara guna:
/// ketik satu tempat kosong (ia bertukar warna), kemudian ketik perkataan;
/// ketik tempat kosong yang sudah diisi untuk mengosongkannya semula.
///
/// Widget ini menyimpan hanya pilihan kosong yang sedang disorot — semua
/// jawapan sebenar diuruskan oleh skrin yang memilikinya.
class PapanTempatKosong extends StatefulWidget {
  const PapanTempatKosong({
    super.key,
    required this.ayat,
    this.rumiAyat,
    required this.bank,
    this.rumiBank,
    required this.indeksBank,
    required this.isi,
    required this.warna,
    required this.onIsi,
    required this.onKosongkan,
    this.onDengarAyat,
    this.onDengarKata,
    this.lumpuh = false,
    this.betul,
  });

  /// Ayat dengan penanda `____` di setiap tempat kosong.
  final List<String> ayat;

  /// Transliterasi Rumi bagi setiap [ayat], dipaparkan sebagai baris kecil
  /// di bawah ayat Jawi.
  ///
  /// Jika ia tiada atau panjangnya tidak sepadan, ayat dipaparkan tanpa
  /// baris Rumi.
  final List<String>? rumiAyat;

  /// Perkataan bank mengikut susunan paparan (dikocok).
  final List<String> bank;

  /// Transliterasi Rumi bagi setiap perkataan [bank] mengikut susunan
  /// paparan.
  ///
  /// Skrin mengocok [bank], jadi ia mesti mengocok senarai ini serentak —
  /// pasangan Jawi–Rumi akan tersasar jika kedua-duanya tidak sepadan.
  final List<String>? rumiBank;

  /// Indeks asal bagi setiap slot [bank].
  final List<int> indeksBank;

  /// Isian semasa: indeks kosong (0, 1, ...) ke indeks asal perkataan.
  final Map<int, int> isi;

  /// Warna unit untuk sorotan.
  final Color warna;

  /// Dipanggil apabila sesuatu kosong diisi dengan perkataan asal [asal].
  final void Function(int kosong, int asal) onIsi;

  /// Dipanggil apabila murid mengosongkan semula sesuatu kosong.
  final ValueChanged<int> onKosongkan;

  /// Butang dengar bagi setiap ayat. `null` menyembunyikannya.
  final ValueChanged<int>? onDengarAyat;

  /// Butang dengar bagi setiap perkataan bank (indeks asal).
  final ValueChanged<int>? onDengarKata;

  /// Benar apabila jawapan tidak boleh diubah lagi.
  final bool lumpuh;

  /// `null` belum disemak; `true`/`false` keputusan semakan.
  final bool? betul;

  @override
  State<PapanTempatKosong> createState() => _PapanTempatKosongState();
}

class _PapanTempatKosongState extends State<PapanTempatKosong> {
  /// Indeks kosong yang sedang disorot, jika ada.
  int? _terpilih;

  @override
  Widget build(BuildContext context) {
    final tanah = switch (widget.betul) {
      null => Colors.transparent,
      true => Warna.latarBetul,
      false => Warna.latarSalah,
    };
    final tepi = switch (widget.betul) {
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
          for (var i = 0; i < widget.ayat.length; i++) _barisAyat(context, i),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _terpilih == null
                      ? 'Ketik tempat kosong, kemudian pilih perkataan di bawah.'
                      : 'Sekarang pilih perkataan untuk tempat kosong '
                            'yang berwarna.',
                  style: Teks.kecil,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var j = 0; j < widget.bank.length; j++) _cipKata(j),
            ],
          ),
        ],
      ),
    );
  }

  /// Nombor kosong pertama dalam ayat [i].
  int _kosongPertama(int i) {
    var bilangan = 0;
    for (var k = 0; k < i; k++) {
      bilangan += '____'.allMatches(widget.ayat[k]).length;
    }
    return bilangan;
  }

  /// Baris Rumi bagi ayat [i], atau `null` jika senarainya tidak sepadan.
  String? _rumiAyat(int i) =>
      Dwibahasa.rumiSelari(widget.rumiAyat, i, widget.ayat.length);

  Widget _barisAyat(BuildContext context, int i) {
    final rumi = _rumiAyat(i);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: widget.warna.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Text(
              '${i + 1}',
              style: Teks.lencana.copyWith(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: _spanAyat(i)),
                        style: Teks.jawi,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (widget.onDengarAyat != null)
                      IconButton(
                        onPressed: () => widget.onDengarAyat!(i),
                        iconSize: 22,
                        color: widget.warna,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 4),
                        tooltip: 'Dengar ayat',
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                  ],
                ),
                // Ayat ini mengadun cip di dalamnya, jadi baris Rumi tidak
                // boleh melalui Dwibahasa; gaya barisnya dikongsi daripada
                // Dwibahasa supaya rupanya sama dengan papan lain.
                if (rumi != null && TunjukRumi.of(context))
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4),
                    child: Text(
                      rumi,
                      textAlign: TextAlign.left,
                      style: Dwibahasa.gayaBarisRumi(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bina span ayat: teks biasa berselang dengan cip tempat kosong.
  List<InlineSpan> _spanAyat(int i) {
    final span = <InlineSpan>[];
    final bahagian = widget.ayat[i].split('____');
    var kosong = _kosongPertama(i);

    for (var b = 0; b < bahagian.length; b++) {
      if (bahagian[b].isNotEmpty) {
        span.add(TextSpan(text: bahagian[b]));
      }
      if (b < bahagian.length - 1) {
        span.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _cipKosong(kosong),
          ),
        );
        kosong++;
      }
    }
    return span;
  }

  Widget _cipKosong(int kosong) {
    final asal = widget.isi[kosong];
    final diisi = asal != null;
    final disemak = widget.betul != null;
    final tepat = diisi && asal == kosong;
    final dipilih = _terpilih == kosong;

    // Selepas disemak: kosong yang betul menghijau, yang salah memerah —
    // supaya murid nampak tepat mana yang tersasar.
    final warnaTepi = disemak
        ? (tepat ? Warna.betul : Warna.salah)
        : (dipilih ? widget.warna : widget.warna.withValues(alpha: 0.45));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: diisi
            ? (disemak
                  ? (tepat ? Warna.latarBetul : Warna.latarSalah)
                  : widget.warna.withValues(alpha: 0.14))
            : (dipilih ? widget.warna.withValues(alpha: 0.14) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.lumpuh
              ? null
              : () {
                  if (diisi) {
                    widget.onKosongkan(kosong);
                    setState(() => _terpilih = null);
                  } else {
                    setState(() => _terpilih = dipilih ? null : kosong);
                  }
                },
          child: Container(
            constraints: const BoxConstraints(minWidth: 74),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: warnaTepi,
                width: dipilih && !disemak ? 3 : 2,
              ),
            ),
            child: Text(
              diisi ? widget.bank[widget.indeksBank.indexOf(asal)] : '____',
              textAlign: TextAlign.center,
              // Cip tempat kosong berada di tengah ayat, jadi saiz `jawiKecil`
              // dari tema dipakai supaya ayat kekal mengalir dalam satu baris.
              style: Teks.jawiKecil.copyWith(
                fontWeight: FontWeight.w800,
                color: diisi
                    ? (disemak && !tepat ? Warna.salah : Colors.black87)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cipKata(int j) {
    final asal = widget.indeksBank[j];
    final digunakan = widget.isi.containsValue(asal);

    return Material(
      color: digunakan ? warnaLatarCipDigunakan : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: (widget.lumpuh || digunakan) ? null : () => _isiDengan(asal),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: digunakan
                  ? Colors.black.withValues(alpha: 0.12)
                  : widget.warna.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (digunakan) ...[
                const Icon(Icons.check_rounded, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                // IntrinsicWidth: pil bank kekal sebesar kandungannya —
                // tanpanya baris Rumi akan meluaskan pil sehingga penuh.
                child: IntrinsicWidth(
                  child: Dwibahasa(
                    jawi: widget.bank[j],
                    rumi: Dwibahasa.rumiSelari(
                      widget.rumiBank,
                      j,
                      widget.bank.length,
                    ),
                    gayaJawi: Teks.jawi.copyWith(
                      color: digunakan
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (widget.onDengarKata != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => widget.onDengarKata!(asal),
                  iconSize: 20,
                  color: widget.warna,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Dengar',
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Isi perkataan [asal] ke dalam kosong yang dipilih, atau kosong pertama
  /// yang belum diisi.
  void _isiDengan(int asal) {
    final kosong = _tempatUntukIsi();
    if (kosong == null) return;
    widget.onIsi(kosong, asal);
    setState(() => _terpilih = null);
  }

  int? _tempatUntukIsi() {
    final terpilih = _terpilih;
    if (terpilih != null && !widget.isi.containsKey(terpilih)) {
      return terpilih;
    }
    final jumlah = widget.indeksBank.length;
    for (var i = 0; i < jumlah; i++) {
      if (!widget.isi.containsKey(i)) return i;
    }
    return null;
  }

  static const Color warnaLatarCipDigunakan = Color(0xFFECEFF1);
}
