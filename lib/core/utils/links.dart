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

/// Tracking and share parameters that don't change which video a link opens.
const _noise = {
  'si',
  'feature',
  'pp',
  'igsh',
  'igshid',
  'is_from_webapp',
  'sender_device',
  'sender_web_id',
  'share_app_id',
  'share_link_id',
  'source',
  'ref',
  'mibextid',
  'fbclid',
  'gclid',
  's',
  't',
  'utm_source',
  'utm_medium',
  'utm_campaign',
  'utm_term',
  'utm_content',
  '_r',
  '_t',
  'invite_link_id',
  'rdid',
};

/// A stable key for "the same video", so a link shared twice with different
/// tracking bits counts once. YouTube links of every shape map to their video id.
String linkKey(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return url.trim();
  final host = u.host.toLowerCase().replaceFirst(
    RegExp(r'^(www|m|mobile)\.'),
    '',
  );
  final path = u.path.replaceFirst(RegExp(r'/+$'), '');
  if (host == 'youtu.be' && path.length > 1) return 'yt:${path.substring(1)}';
  if (host.endsWith('youtube.com')) {
    final v = u.queryParameters['v'];
    if (v != null) return 'yt:$v';
    final m = RegExp(r'^/(shorts|live|embed)/([^/]+)').firstMatch(path);
    if (m != null) return 'yt:${m[2]}';
  }
  final params =
      u.queryParameters.entries
          .where((e) => !_noise.contains(e.key.toLowerCase()))
          .map((e) => '${e.key}=${e.value}')
          .toList()
        ..sort();
  return '$host$path${params.isEmpty ? '' : '?${params.join('&')}'}';
}
