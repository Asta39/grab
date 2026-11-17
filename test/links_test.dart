import 'package:flutter_test/flutter_test.dart';
import 'package:grab/core/utils/links.dart';

void main() {
  test('pulls the link out of shared text', () {
    expect(extractLink('Check this out! https://vm.tiktok.com/ZMabc/ #fyp'), 'https://vm.tiktok.com/ZMabc/');
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
}
