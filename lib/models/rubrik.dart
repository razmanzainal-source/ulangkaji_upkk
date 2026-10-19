/// Rubrik pemarkahan soalan bertulis (`taip`).
///
/// Kertas UASA Sejarah Tahun 5 memberikan markah mengikut skema pemarkahan:
/// satu markah bagi setiap isi (fakta) yang betul. Rubrik ini meniru skema
/// itu — setiap [Idea] ialah satu isi yang bernilai satu markah.
///
/// Data ini sengaja kekal sebagai data tulen (tiada enjin pemarkahan di sini)
/// supaya `lib/models/` tidak bergantung pada `lib/services/`.
library;

/// Satu isi jawapan yang bernilai satu markah.
class Idea {
  const Idea({required this.maksud, required this.kata});

  /// Huraian isi ini — dipaparkan kepada murid sebagai maklum balas supaya
  /// dia tahu isi mana yang belum ditulis.
  final String maksud;

  /// Mana-mana satu perkataan ini sudah memadai untuk mengesahkan isi ini.
  /// Senarai pertama biasanya perkataan yang dijangka dalam buku teks, dan
  /// selebihnya sinonim atau ejaan lain yang diterima.
  final List<String> kata;

  factory Idea.dariJson(Map<String, dynamic> json) => Idea(
        maksud: json['maksud'] as String? ?? '',
        kata: (json['kata'] as List?)?.cast<String>() ?? const [],
      );
}

/// Senarai isi yang perlu ada dalam jawapan satu soalan `taip`.
class Rubrik {
  const Rubrik(this.idea);

  final List<Idea> idea;

  static const Rubrik kosong = Rubrik([]);

  /// Markah penuh soalan = bilangan isi, sama seperti skema pemarkahan UASA.
  int get markah => idea.length;

  bool get ada => idea.isNotEmpty;

  factory Rubrik.dariJson(Object? senarai) => Rubrik(
        (senarai as List? ?? const [])
            .map((e) => Idea.dariJson(e as Map<String, dynamic>))
            .toList(),
      );
}
