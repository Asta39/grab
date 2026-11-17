/// Finds the first web link in shared or pasted text.
/// Apps like TikTok share "Check this out! https://vm.tiktok.com/abc/" rather than a bare URL.
String? extractLink(String? text) {
  if (text == null) return null;
  final m = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  ).firstMatch(text);
  if (m == null) return null;
  return m.group(0)!.replaceFirst(RegExp(r'[).,!?]+$'), '');
}

/// Platforms shown as chips on Home, in display order.
const platforms = [
  'YouTube',
  'TikTok',
  'Instagram',
  'Pinterest',
  'X',
  'Facebook',
];

/// Which known platform a link belongs to, or null.
String? platformOf(String? url) {
  final host = Uri.tryParse(url ?? '')?.host.toLowerCase() ?? '';
  if (host.isEmpty) return null;
  bool has(String d) => host == d || host.endsWith('.$d');
  if (has('youtube.com') || has('youtu.be')) return 'YouTube';
  if (has('tiktok.com')) return 'TikTok';
  if (has('instagram.com')) return 'Instagram';
  if (has('pinterest.com') || has('pin.it') || host.contains('pinterest.')) {
    return 'Pinterest';
  }
  if (has('x.com') || has('twitter.com')) return 'X';
  if (has('facebook.com') || has('fb.watch')) return 'Facebook';
  return null;
}
