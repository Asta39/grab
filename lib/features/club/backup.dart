import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/toasts.dart';
import 'fun.dart';
import 'game.dart';

const _kind = 'grab-club-backup';

/// Look settings saved with progress. The Groq key is left out on purpose.
const _funKeys = [
  'fun.sounds',
  'fun.shake',
  'fun.buddy',
  'fun.dock',
  'fun.cover',
  'fun.hat',
  'fun.party',
  'fun.soundPack',
];

/// Everything Grab Club needs to come back on a new phone, as JSON.
String buildBackup(GameState g, Map<String, Object?> fun, [DateTime? now]) =>
    const JsonEncoder.withIndent('  ').convert({
      'kind': _kind,
      'version': 1,
      'exported': (now ?? DateTime.now()).toIso8601String(),
      'grabClub': g.toJson(),
      'fun': fun,
    });

/// Reads a backup; throws [FormatException] if it isn't one.
({GameState game, Map<String, Object?> fun}) parseBackup(String text) {
  final j = jsonDecode(text);
  if (j is! Map || j['kind'] != _kind) {
    throw const FormatException("That file isn't a Grab Club backup");
  }
  return (
    game: GameState.fromJson((j['grabClub'] as Map).cast<String, Object?>()),
    fun: ((j['fun'] as Map?) ?? const {}).cast<String, Object?>(),
  );
}

/// Saves progress to a file and hands it to the share sheet
/// (Drive, Files, email…).
Future<void> exportGrabClub(WidgetRef ref) async {
  Haptics.medium();
  final prefs = ref.read(sharedPrefsProvider);
  final fun = {
    for (final k in _funKeys)
      if (prefs.get(k) != null) k: prefs.get(k),
  };
  final day = DateTime.now().toIso8601String().substring(0, 10);
  final f = File('${(await getTemporaryDirectory()).path}/grab-club-$day.json');
  await f.writeAsString(buildBackup(ref.read(gameProvider), fun));
  await SharePlus.instance.share(
    ShareParams(files: [XFile(f.path)], subject: 'Grab Club backup'),
  );
}

/// Picks a backup file and, after confirming, restores it.
Future<void> importGrabClub(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  final file = picked.firstOrNull;
  if (file == null) return;
  final bytes = await file.xFile.readAsBytes();
  final ({GameState game, Map<String, Object?> fun}) b;
  try {
    b = parseBackup(utf8.decode(bytes));
  } catch (e) {
    Haptics.error();
    popToast(
      "Couldn't restore",
      error: true,
      detail: e is FormatException ? e.message : 'The file is damaged.',
    );
    return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Restore this backup?'),
      content: Text(
        'Level ${b.game.level.n} · ${b.game.level.name}, '
        '${b.game.unlocked.length} badges, best streak ${b.game.best}.\n\n'
        'This replaces your current Grab Club progress.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final prefs = ref.read(sharedPrefsProvider);
  for (final MapEntry(:key, :value) in b.fun.entries) {
    if (!_funKeys.contains(key)) continue;
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }
  ref.read(gameProvider.notifier).restore(b.game);
  ref.invalidate(funProvider);
  Haptics.success();
  popToast(
    'Progress restored',
    icon: Icons.restore_rounded,
    detail: 'Welcome back, ${b.game.level.name}!',
  );
}
