import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/pop_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../library/library_items.dart';
import '../library/library_screen.dart';
import '../library/player_screen.dart';
import 'buddy.dart';
import 'fun.dart';

/// Grab Pal: "that cooking video from last month", "the song with the guitar
/// intro"... finds files from a fuzzy description. Uses the user's own Groq
/// key when there is one (only titles, sites, kinds and dates are sent), and
/// a local word match otherwise.

class PalMatch {
  const PalMatch(this.item, this.why);
  final LibraryItem item;
  final String? why;
}

/// Plain local search: every query word should appear somewhere; close words count a little.
List<PalMatch> localSearch(List<LibraryItem> items, String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 1)
      .toList();
  if (words.isEmpty) return const [];
  final scored = <(double, LibraryItem)>[];
  for (final it in items) {
    final hay =
        '${it.title} ${it.fileName} ${siteName(it.site)} ${it.kind.name}'
            .toLowerCase();
    final tokens = hay.split(RegExp(r'[^a-z0-9]+'));
    var score = 0.0;
    for (final w in words) {
      if (hay.contains(w)) {
        score += 1;
      } else if (tokens.any((t) => t.length > 3 && _close(t, w))) {
        score += 0.6;
      }
    }
    if (score > 0) scored.add((score / words.length, it));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final s in scored.take(12)) PalMatch(s.$2, null)];
}

/// Edit distance of at most 1 or 2, for typos.
bool _close(String a, String b) {
  if ((a.length - b.length).abs() > 2) return false;
  final limit = b.length > 5 ? 2 : 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length] <= limit;
}

/// Asks Groq to pick the best matches. Throws on network or key problems.
Future<List<PalMatch>> groqSearch(
  String key,
  List<LibraryItem> items,
  String query, {
  http.Client? client,
}) async {
  final list = items.take(400).toList();
  final catalog = [
    for (final (i, it) in list.indexed)
      {
        'i': i,
        't': it.title,
        's': siteName(it.site),
        'k': it.kind.name,
        if (it.finishedAt != null)
          'd': it.finishedAt!.toIso8601String().substring(0, 10),
      },
  ];
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final body = jsonEncode({
    'model': 'llama-3.3-70b-versatile',
    'temperature': 0.2,
    'response_format': {'type': 'json_object'},
    'messages': [
      {
        'role': 'system',
        'content':
            'You are Grab Pal, a friendly helper inside a video and audio downloader. '
            'Given the user\'s library (i=index, t=title, s=site, k=kind, d=date saved) '
            'and a fuzzy request, return the items that best match, best first, at most 8. '
            'Understand vague descriptions, topics, moods, people, rough dates ("last week") and typos. '
            'Today is $today. Reply only with JSON: {"matches":[{"i":0,"why":"short reason, max 8 words"}],"say":"one short friendly sentence"}. '
            'If nothing fits, return an empty list and say so kindly.',
      },
      {
        'role': 'user',
        'content': 'Library: ${jsonEncode(catalog)}\nRequest: $query',
      },
    ],
  });
  final c = client ?? http.Client();
  try {
    final r = await c
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode == 401) throw const PalError('That Groq key was refused.');
    if (r.statusCode >= 400) {
      throw PalError('Grab Pal is busy right now (${r.statusCode}).');
    }
    final content =
        ((jsonDecode(r.body) as Map)['choices'] as List)
                .first['message']['content']
            as String;
    final data = jsonDecode(content) as Map;
    lastSay = data['say'] as String?;
    return [
      for (final m in (data['matches'] as List? ?? const []))
        if (m is Map && m['i'] is num && (m['i'] as num).toInt() < list.length)
          PalMatch(list[(m['i'] as num).toInt()], m['why'] as String?),
    ];
  } finally {
    if (client == null) c.close();
  }
}

/// The friendly line from Groq's last answer.
String? lastSay;

class PalError implements Exception {
  const PalError(this.message);
  final String message;
  @override
  String toString() => message;
}

void openPal(BuildContext context) {
  Haptics.light();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _PalSheet(),
  );
}

class _PalSheet extends ConsumerStatefulWidget {
  const _PalSheet();

  @override
  ConsumerState<_PalSheet> createState() => _PalSheetState();
}

class _PalSheetState extends ConsumerState<_PalSheet> {
  final _q = TextEditingController();
  List<PalMatch>? _results;
  String? _say;
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final items = ref.read(libraryProvider);
    final key = ref.read(funProvider).groqKey;
    setState(() {
      _busy = true;
      _error = null;
      _say = null;
    });
    Buddy.mood(BuddyMood.search, hold: const Duration(seconds: 30));
    List<PalMatch> found;
    String? say;
    try {
      if (key.isEmpty) {
        found = localSearch(items, q);
      } else {
        found = await groqSearch(key, items, q);
        say = lastSay;
      }
    } catch (e) {
      // Fall back to the local match so the user still gets something.
      found = localSearch(items, q);
      _error = e is PalError
          ? e.message
          : 'Couldn\'t reach Grab Pal, so I searched by words.';
    }
    if (!mounted) return;
    Buddy.mood(found.isEmpty ? BuddyMood.sad : BuddyMood.cheer);
    found.isEmpty ? Haptics.warning() : Haptics.success();
    setState(() {
      _busy = false;
      _results = found;
      _say =
          say ??
          (found.isEmpty
              ? 'I couldn\'t find that one. Try other words?'
              : 'Found ${found.length} that might be it!');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(funProvider).groqKey.isNotEmpty;
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BuddyFace(size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grab Pal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _say ??
                          (hasKey
                              ? 'Describe it however you remember it.'
                              : 'Tell me some words from it. Add a Groq key in Settings and I get much smarter.'),
                      style: TextStyle(color: context.pop.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _ask(),
            decoration: InputDecoration(
              hintText: hasKey
                  ? 'e.g. that funny cat video from last week'
                  : 'e.g. jonte chapter',
              filled: true,
              fillColor: context.pop.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: _ask,
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: context.pop.muted, fontSize: 13),
            ),
          ],
          if (results != null && results.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = results[i];
                  return Material(
                    color: context.pop.card,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pop(context);
                        openPlayer(context, m.item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            PopThumb(
                              seed: m.item.jobId,
                              url: m.item.thumbnail,
                              audio: m.item.kind == LibraryKind.audio,
                              size: 52,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    m.why ??
                                        '${siteName(m.item.site)} · ${m.item.ext}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.pop.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.play_arrow_rounded),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Paste, change or remove the user's own Groq key.
Future<void> editGroqKey(BuildContext context, WidgetRef ref) async {
  final c = TextEditingController(text: ref.read(funProvider).groqKey);
  final saved = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Grab Pal key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste your own Groq API key (free at console.groq.com) to let Grab Pal '
            'understand fuzzy searches. Only titles, sites, kinds and dates of your '
            'files are sent to Groq, never the files. Without a key, Grab Pal '
            'matches words on your phone.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            obscureText: true,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'gsk_...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Remove'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, c.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  c.dispose();
  if (saved == null) return;
  ref.read(funProvider.notifier).update((f) => f.copyWith(groqKey: saved));
}
