import 'package:flutter_test/flutter_test.dart';
import 'package:grab/core/utils/links.dart';

void main() {
  test('pulls the link out of shared text', () {
    expect(
      extractLink('Check this out! https://vm.tiktok.com/ZMabc/ #fyp'),
      'https://vm.tiktok.com/ZMabc/',
    );
    expect(extractLink('https://pin.it/3xYz.'), 'https://pin.it/3xYz');
    expect(extractLink('no link here'), isNull);
    expect(extractLink(null), isNull);
  });

  test('names the platform', () {
    expect(platformOf('https://www.youtube.com/watch?v=1'), 'YouTube');
    expect(platformOf('https://youtu.be/1'), 'YouTube');
    expect(platformOf('https://vm.tiktok.com/x'), 'TikTok');
    expect(platformOf('https://www.pinterest.co.uk/pin/1/'), 'Pinterest');
    expect(platformOf('https://pin.it/x'), 'Pinterest');
    expect(platformOf('https://x.com/a/status/1'), 'X');
    expect(platformOf('https://notyoutube.com/x'), isNull);
    expect(platformOf('garbage'), isNull);
  });

  test('linkKey treats share variants of one video as the same', () {
    const a = 'https://youtu.be/Z-zYu4patP8?si=KPuV7uXB8WsNAQcr';
    expect(linkKey(a), 'yt:Z-zYu4patP8');
    expect(
      linkKey('https://www.youtube.com/watch?v=Z-zYu4patP8&feature=share'),
      linkKey(a),
    );
    expect(linkKey('https://m.youtube.com/shorts/Z-zYu4patP8'), linkKey(a));
    expect(
      linkKey(
        'https://www.tiktok.com/@u/video/123?is_from_webapp=1&sender_device=pc',
      ),
      linkKey('https://tiktok.com/@u/video/123/'),
    );
    expect(
      linkKey('https://example.com/watch?id=1'),
      isNot(linkKey('https://example.com/watch?id=2')),
    );
  });
}
