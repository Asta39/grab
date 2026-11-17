import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/toasts.dart';
import '../../data/engine/engine_channel.dart';

/// An audio extraction running on a saved file.
class Extraction {
  const Extraction({required this.engineId, this.progress = 0, this.error});

  final String engineId;
  final double progress;
  final String? error;
}

/// Audio extractions in progress, keyed by the download (job) they belong to.
/// When one finishes, its file is added to that download.
class ExtractionController extends Notifier<Map<String, Extraction>> {
  StreamSubscription<EngineEvent>? _sub;

  @override
  Map<String, Extraction> build() {
    _sub = ref.watch(engineProvider).events.listen(_onEvent);
    ref.onDispose(() => _sub?.cancel());
    return const {};
  }

  Future<void> extractAudio({
    required String jobId,
    required String input,
    required String title,
    String? format,
  }) async {
    if (state.containsKey(jobId)) return;
    final fmt = format ?? ref.read(settingsProvider).audioFormat;
    final engineId = 'x-$jobId-${DateTime.now().microsecondsSinceEpoch}';
    state = {...state, jobId: Extraction(engineId: engineId)};
    try {
      await ref
          .read(engineProvider)
          .extractAudio(id: engineId, input: input, format: fmt, title: title);
    } catch (e) {
      _end(jobId);
      popToast("Couldn't extract audio", error: true, detail: '$e');
    }
  }

  Future<void> cancel(String jobId) async {
    final x = state[jobId];
    if (x != null) await ref.read(engineProvider).cancel(x.engineId);
  }

  Future<void> _onEvent(EngineEvent e) async {
    final jobId = state.entries
        .where((en) => en.value.engineId == e.id)
        .map((en) => en.key)
        .firstOrNull;
    if (jobId == null) return;
    switch (e.status) {
      case 'running':
        state = {
          ...state,
          jobId: Extraction(engineId: e.id, progress: e.progress ?? 0),
        };
      case 'done':
        await ref.read(downloadRepositoryProvider).addPaths(jobId, e.paths);
        _end(jobId);
        popToast(
          'Audio extracted',
          icon: Icons.music_note_rounded,
          detail: e.paths.isEmpty ? null : e.paths.first.split('/').last,
        );
      case 'error':
        _end(jobId);
        popToast("Couldn't extract audio", error: true, detail: e.error);
      case 'canceled':
        _end(jobId);
    }
  }

  void _end(String jobId) => state = {...state}..remove(jobId);
}

final extractionProvider =
    NotifierProvider<ExtractionController, Map<String, Extraction>>(
      ExtractionController.new,
    );
