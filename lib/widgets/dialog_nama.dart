import 'dart:async';

import 'package:flutter/material.dart';

import '../services/suara.dart';
import '../tema.dart';
import 'maskot.dart';

/// Tanya nama murid, sekali sahaja.
///
/// Nama ialah perkara yang menjadikan app ini terasa **milik anak** dan bukan
/// sekadar laman latihan. Ia membolehkan kepala skrin berkata
/// "Assalamualaikum, Aisyah!", dan membolehkan skrin keputusan berkata
/// "Cemerlang, Aisyah!" — bukan "Cemerlang!" kepada sesiapa sahaja yang
/// memegang telefon.
///
/// Pulangan:
///   * nama (sudah dipangkas) apabila murid menekannya;
///   * `null` apabila ibu bapa memilih **Langkau**;
///   * rentetan kosong boleh berlaku apabila murid menekan "Mula belajar"
///     tanpa menaip apa-apa — pemanggil patut menganggapnya seperti Langkau.
///
/// [nilaiAwal] mengisi medan dengan nama semasa, dan [tukar] menukar nada
/// dialog daripada "selamat datang" kepada "kemas kini" — ibu bapa yang sudah
/// biasa dengan app tidak perlu disapa semula setiap kali dia menukar nama.
Future<String?> tanyaNama(
  BuildContext konteks, {
  String nilaiAwal = '',
  bool tukar = false,
}) => showDialog<String>(
  context: konteks,
  // Tidak boleh ditutup dengan menekan di luar: nama ialah langkah pertama
  // yang disengajakan, bukan dialog yang muncul secara tidak sengaja.
  barrierDismissible: false,
  builder: (_) => _DialogNama(nilaiAwal: nilaiAwal, tukar: tukar),
);

class _DialogNama extends StatefulWidget {
  const _DialogNama({this.nilaiAwal = '', this.tukar = false});

  final String nilaiAwal;
  final bool tukar;

  @override
  State<_DialogNama> createState() => _DialogNamaState();
}

class _DialogNamaState extends State<_DialogNama> {
  late final TextEditingController _kawalan = TextEditingController(
    text: widget.nilaiAwal,
  );
  final FocusNode _fokus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Soalan nama dibaca kuat. Dialog ini muncul sebaik app dibuka, sebelum
    // murid membaca apa-apa — murid Tahun 5 yang belum lancar membaca tidak
    // sepatutnya terpaksa meneka apa yang app mahu. Suara dilewatkan sedikit
    // supaya ia tidak bertindih dengan skrin muat turun yang baru sahaja
    // hilang.
    if (!widget.tukar) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        unawaited(
          Suara.instance.sebutKunci(Suara.kunciNama, sandaran: Suara.soalanNama),
        );
      });
    }

    // Papan kekunci dibuka sendiri supaya ibu bapa tidak perlu menekan medan
    // dahulu — satu langkah kurang sebelum anak boleh mula belajar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Kursor di hujung supaya nama sedia ada boleh terus disambung atau
      // dipadam, bukan ditulis semula dari depan.
      _kawalan.selection = TextSelection.collapsed(
        offset: _kawalan.text.length,
      );
      _fokus.requestFocus();
    });
  }

  @override
  void dispose() {
    _kawalan.dispose();
    _fokus.dispose();
    super.dispose();
  }

  void _hantar() => Navigator.of(context).pop(_kawalan.text.trim());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Maskot(saiz: 96, mood: MoodMaskot.gembira),
            const SizedBox(height: 8),
            Text(
              widget.tukar ? 'Tukar nama' : 'Assalamualaikum!',
              style: Teks.besar,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.tukar
                  ? 'Raz akan guna nama baharu ini.'
                  : 'Siapa nama kamu? Raz hendak kenal kamu.',
              style: Teks.biasa.copyWith(color: Colors.black54, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kawalan,
              focusNode: _fokus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: 24,
              onSubmitted: (_) => _hantar(),
              decoration: InputDecoration(
                labelText: 'Nama kamu',
                hintText: 'Contoh: Aisyah',
                prefixIcon: const Icon(Icons.person_rounded),
                // Kiraan aksara hanya mengganggu dalam dialog semudah ini.
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _hantar,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                widget.tukar ? 'Simpan' : 'Mula belajar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Warna.utama,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.tukar ? 'Batal' : 'Langkau'),
            ),
          ],
        ),
      ),
    );
  }
}
