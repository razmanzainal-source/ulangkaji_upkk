# Peraturan ProGuard/R8 untuk "Sains Tahun 5 Bersama Raz".
#
# Kenapa fail ini perlu ada?
# -------------------------
# Flutter menghidupkan pengecilan kod R8 secara lalai untuk binaan *release*.
# R8 mengubah tandatangan fungsi `suspend` yang dijana oleh Pigeon di dalam
# plugin (contoh: `getAll(String, List, Continuation)` menjadi
# `getAll(String, List, b5)`), tetapi tapak panggilan masih mengharapkan
# tandatangan asal. Akibatnya berlaku `NoSuchMethodError` pada masa jalan:
#
#   java.lang.NoSuchMethodError:
#     io.flutter.plugins.sharedpreferences.SharedPreferencesApiRegistrar
#       .getAll(Ljava/lang/String;Ljava/util/List;Lkotlin/coroutines/Continuation;)
#
# Kesannya pada peranti sebenar: storan kemajuan gagal dan app memaparkan skrin
# kosong (release sahaja; binaan debug tidak terjejas).
#
# Simpan kelas plugin supaya app kekal stabil pada telefon anak.

# --- Plugin Flutter (Pigeon: shared_preferences, flutter_tts, dll.) ---
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.plugins.** { *; }

# Kelas Pigeon yang dijana (jika plugin meletakkannya dalam pakej sendiri).
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }

# --- Pemain audio (audioplayers) ---
-keep class xyz.luan.audioplayers.** { *; }
-keep interface xyz.luan.audioplayers.** { *; }
