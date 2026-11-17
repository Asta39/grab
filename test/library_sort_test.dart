import 'package:flutter_test/flutter_test.dart';
import 'package:grab/features/library/library_items.dart';

LibraryItem item(String path, String? site, int day) => LibraryItem(
  jobId: path,
  path: path,
  title: path,
  kind: LibraryKind.video,
  site: site,
  finishedAt: DateTime(2026, 1, day),
);

void main() {
  final items = [
    item('a', 'Youtube', 1),
    item('b', 'TikTok', 3),
    item('c', 'YoutubeTab', 2),
    item('d', null, 4),
  ];
  const sizes = {'a': 50, 'b': 10, 'c': 900, 'd': 0};
  int sizeOf(String p) => sizes[p]!;
  List<String> paths(List<LibraryItem> l) => [for (final i in l) i.path];

  test('sorts by date, size and site', () {
    expect(paths(sortLibrary(items, LibrarySort.newest, sizeOf: sizeOf)), [
      'd',
      'b',
      'c',
      'a',
    ]);
    expect(paths(sortLibrary(items, LibrarySort.oldest, sizeOf: sizeOf)), [
      'a',
      'c',
      'b',
      'd',
    ]);
    expect(paths(sortLibrary(items, LibrarySort.largest, sizeOf: sizeOf)), [
      'c',
      'a',
      'b',
      'd',
    ]);
    expect(paths(sortLibrary(items, LibrarySort.site, sizeOf: sizeOf)), [
      'd',
      'b',
      'c',
      'a',
    ]);
  });

  test('groups by platform, biggest group first', () {
    final g = groupBySite(
      sortLibrary(items, LibrarySort.newest, sizeOf: sizeOf),
    );
    expect([for (final (name, _) in g) name], ['YouTube', 'Other', 'TikTok']);
    expect(paths(g.first.$2), ['c', 'a']);
  });

  test('friendly site names', () {
    expect(siteName('TwitterStatus'), 'X');
    expect(siteName('VimeoIE'), 'Vimeo');
    expect(siteName('DailymotionIE'), 'Dailymotion');
    expect(siteName(null), 'Other');
  });
}
