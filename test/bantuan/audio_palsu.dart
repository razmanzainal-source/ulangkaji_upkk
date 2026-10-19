// Platform audio palsu untuk ujian.
//
// `Suara` membina `AudioPlayer` sebaik sahaja ia disentuh, dan `AudioPlayer`
// segera memanggil platform audio asli. Di dalam ujian tidak ada platform asli,
// jadi panggilan itu gagal dengan `MissingPluginException` **di luar** kawalan
// `try`/`catch` app — dan ujian gagal atas sebab yang tidak berkaitan dengan apa
// yang diuji.
//
// Bantuan ini menggantikan platform audio dengan satu yang senyap. Ujian masih
// boleh memeriksa **niat** app (lihat `Suara.kesanTerakhir`), cuma tiada bunyi
// yang benar-benar dimainkan.

import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Platform audio yang tidak menyentuh perkakasan langsung.
///
/// Semua kaedah mengembalikan serta-merta. `getEventStream` memulangkan aliran
/// kosong dan bukannya `EventChannel` — saluran peristiwa dinamakan mengikut id
/// pemain, jadi ia tidak boleh dipalsukan lebih awal.
class _PlatformAudioPalsu extends AudioplayersPlatformInterface {
  @override
  Future<void> create(String playerId) async {}

  @override
  Future<void> dispose(String playerId) async {}

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> stop(String playerId) async {}

  @override
  Future<void> resume(String playerId) async {}

  @override
  Future<void> release(String playerId) async {}

  @override
  Future<void> seek(String playerId, Duration position) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {}

  @override
  Future<void> setSourceBytes(
    String playerId,
    Uint8List bytes, {
    String? mimeType,
  }) async {}

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  ) async {}

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<int?> getCurrentPosition(String playerId) async => null;

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<void> emitError(String playerId, String code, String message) async {}

  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream.empty();
}

/// Pasang platform audio palsu. Panggil sekali dalam `setUpAll` atau pada
/// permulaan `main` ujian.
void pasangAudioPalsu() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AudioplayersPlatformInterface.instance = _PlatformAudioPalsu();

  // Skop audio global (dipakai oleh `AudioPlayer` untuk tetapan sistem) masih
  // memanggil saluran asli; panggilan itu dikekalkan senyap di sini.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (_) async => null,
      );

  // Aliran peristiwa global pula dibuka oleh `AudioPlayer.global` sebaik sahaja
  // ia dicipta, dan tanpa pendengar palsu ia membaling `MissingPluginException`
  // di tengah-tengah ujian yang membenarkan masa sebenar berlalu (misalnya
  // ujian yang menunggu gambar kad ditangkap).
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        const EventChannel('xyz.luan/audioplayers.global/events'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
}
