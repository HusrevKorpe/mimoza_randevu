/// Up-to-two-letter initials for an avatar, e.g. "Emre Kaya" -> "EK".
///
/// Takes the first character of each of the first two words verbatim — no
/// `toUpperCase()`, which mangles Turkish letters (i -> I instead of İ). Returns
/// "?" for an empty/blank name so an avatar always has something to show.
String initialsFrom(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return '?';
  final buffer = StringBuffer();
  for (final word in words.take(2)) {
    buffer.write(word.substring(0, 1));
  }
  return buffer.toString();
}
