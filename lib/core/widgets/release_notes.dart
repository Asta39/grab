import 'package:flutter/material.dart';

import '../theme/pop_theme.dart';

/// One piece of a release's notes, ready to show in the app.
sealed class NoteBlock {
  const NoteBlock(this.text);
  final String text;
}

class NoteHeading extends NoteBlock {
  const NoteHeading(super.text, {this.major = true});

  /// A `##` heading (true) or a bold-only line used as a sub-heading.
  final bool major;
}

class NoteBullet extends NoteBlock {
  const NoteBullet(super.text);
}

class NoteParagraph extends NoteBlock {
  const NoteParagraph(super.text);
}

/// Sections of the GitHub notes that are about the release page, not the app.
const _skipSections = {'downloads', 'credits'};

/// Turns GitHub release Markdown into simple blocks: headings, bullets and
/// paragraphs. Tables, download lists and credits are left out; links keep
/// their text; `**bold**` stays marked for [ReleaseNotes] to render.
List<NoteBlock> parseReleaseNotes(String md) {
  final out = <NoteBlock>[];
  var skipping = false;
  for (final raw in md.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final heading = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(line);
    if (heading != null) {
      final title = _plain(heading.group(1)!);
      skipping = _skipSections.contains(title.toLowerCase());
      if (!skipping) out.add(NoteHeading(title));
      continue;
    }
    if (skipping) continue;
    if (line.startsWith('|')) continue; // tables
    if (line.startsWith('The Windows and macOS files')) continue;
    final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
    if (bullet != null) {
      out.add(NoteBullet(_clean(bullet.group(1)!)));
      continue;
    }
    // A line that is only bold text reads as a small heading.
    final boldOnly = RegExp(r'^\*\*(.+)\*\*$').firstMatch(line);
    if (boldOnly != null) {
      out.add(NoteHeading(_plain(boldOnly.group(1)!), major: false));
      continue;
    }
    out.add(NoteParagraph(_clean(line)));
  }
  return out;
}

/// Keeps `**bold**`, drops links and code marks.
String _clean(String s) => s
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1)!)
    .replaceAll('`', '');

/// Plain text, with every Markdown mark removed.
String _plain(String s) => _clean(s).replaceAll('**', '').replaceAll('__', '');

/// Release notes as tidy text: headings, yellow-dot bullets, real bold.
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final blocks = parseReleaseNotes(markdown);
    final body = TextStyle(
      fontSize: 13.5,
      height: 1.4,
      color: context.pop.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, b) in blocks.indexed)
          switch (b) {
            NoteHeading(major: true) => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 4),
              child: Text(
                b.text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: context.pop.text,
                ),
              ),
            ),
            NoteHeading() => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12, bottom: 6),
              child: Text(
                b.text.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: context.pop.muted,
                ),
              ),
            ),
            NoteBullet() => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: const BoxDecoration(
                      color: Pop.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: _rich(b.text, body)),
                ],
              ),
            ),
            NoteParagraph() => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _rich(
                b.text,
                body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ),
          },
      ],
    );
  }

  /// Text with `**bold**` parts in bold.
  Widget _rich(String s, TextStyle style) {
    final parts = s.split('**');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (i, p) in parts.indexed)
            TextSpan(
              text: p,
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w800)
                  : null,
            ),
        ],
      ),
    );
  }
}
