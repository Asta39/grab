import 'package:flutter_test/flutter_test.dart';
import 'package:grab/data/engine/media_info.dart';

void main() {
  test('converts tokens to yt-dlp fields', () {
    expect(
      ytDlpTemplate('{title} - {site}'),
      '%(title).80B - %(extractor_key)s',
    );
    expect(ytDlpTemplate(''), '%(title).80B [%(id)s]');
    expect(
      ytDlpTemplate('{date} {uploader}'),
      '%(upload_date>%Y-%m-%d|undated)s %(uploader,channel|Unknown)s',
    );
  });

  test('cleans path characters, unknown tokens and stray %', () {
    expect(ytDlpTemplate('a/b {nope} {title} 100%'), 'a b %(title).80B 100%%');
    expect(ytDlpTemplate('no tokens here'), '%(title).80B [%(id)s]');
  });

  test('preview', () {
    expect(
      previewFileName('{title} - {site}'),
      'Sunset timelapse - Youtube.mp4',
    );
  });
}
