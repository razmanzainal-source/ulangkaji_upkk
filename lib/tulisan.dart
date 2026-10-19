/// Utiliti arah tulisan Jawi dan Arab.
///
/// Diasingkan daripada `Pemarkah` dan daripada widget kerana tiga tempat
/// memerlukannya dengan sebab yang berbeza:
///
/// * medan jawapan — untuk memilih arah perenggan yang betul;
/// * papan kekunci — untuk menandakan kekunci yang bukan huruf Jawi;
/// * penanda markah — untuk mengetahui jawapan itu Jawi atau Rumi.
library;

/// Julat kod Unicode yang tergolong dalam tulisan Arab.
///
/// Jawi ialah abjad Arab dengan huruf tambahan Melayu (چ ݢ ڠ ڤ ۏ ڽ), jadi
/// julat yang sama meliputi kedua-duanya.
const List<List<int>> julatTulisanArab = [
  [0x0600, 0x06FF], // Arab asas + Jawi (termasuk harakat)
  [0x0750, 0x077F], // Arab tambahan
  [0x08A0, 0x08FF], // Arab tambahan A
  [0xFB50, 0xFDFF], // Bentuk persembahan A — termasuk ﷺ (U+FDFA)
  [0xFE70, 0xFEFF], // Bentuk persembahan B
];

/// Benar apabila [kod] ialah aksara tulisan Arab atau Jawi.
bool aksaraTulisanArab(int kod) {
  for (final julat in julatTulisanArab) {
    if (kod >= julat[0] && kod <= julat[1]) return true;
  }
  return false;
}

/// Benar apabila [teks] mengandungi sekurang-kurangnya satu aksara Arab/Jawi.
///
/// Dipakai untuk menentukan arah perenggan medan jawapan. Medan yang
/// memaparkan ayat Jawi mesti berarah kanan-ke-kiri; jika tidak, beberapa
/// patah perkataan Jawi akan tersusun terbalik.
bool bertulisanArab(String teks) {
  for (final unit in teks.runes) {
    if (aksaraTulisanArab(unit)) return true;
  }
  return false;
}

/// Arah perenggan yang sepatutnya bagi [teks].
///
/// Tulisan Jawi dan Arab dibaca kanan-ke-kiri. Menetapkan arah ikut **isi
/// teks**, bukan ikut halaman papan kekunci, supaya jawapan Rumi yang ditaip
/// pada soalan Jawi tetap dipaparkan dengan betul.
bool arahKananKeKiri(String teks) => bertulisanArab(teks);
