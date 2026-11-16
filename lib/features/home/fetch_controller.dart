import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/engine/media_info.dart';
import '../../data/repositories/download_repository.dart';

/// Everything the Home + Choose format flow needs.
class FetchState {
  const FetchState({
    this.info = const AsyncData(null),
    this.mode = DownloadMode.videoAndAudio,
    this.optionIndex = 0,
    this.subLangs = const {},
    this.embedSubs = false,
  });

  final AsyncValue<MediaInfo?> info;
  final DownloadMode mode;
  final int optionIndex;
  final Set<String> subLangs;
  final bool embedSubs;

  List<QualityOption> get options => info.value?.optionsFor(mode) ?? const [];
  QualityOption? get selected => options.isEmpty ? null : options[optionIndex.clamp(0, options.length - 1)];

  /// Download is possible when there is something to fetch for this mode.
  bool get canDownload =>
      info.value != null && (mode != DownloadMode.subtitlesOnly || subLangs.isNotEmpty);

  FetchState copyWith({
    AsyncValue<MediaInfo?>? info,
    DownloadMode? mode,
    int? optionIndex,
    Set<String>? subLangs,
    bool? embedSubs,
  }) =>
      FetchState(
        info: info ?? this.info,
        mode: mode ?? this.mode,
        optionIndex: optionIndex ?? this.optionIndex,
        subLangs: subLangs ?? this.subLangs,
        embedSubs: embedSubs ?? this.embedSubs,
      );
}

class FetchController extends Notifier<FetchState> {
  @override
  FetchState build() => const FetchState();

  Future<void> fetch(String url) async {
    url = url.trim();
    if (url.isEmpty) return;
    state = FetchState(info: const AsyncLoading());
    final result = await AsyncValue.guard(() => ref.read(engineProvider).fetch(url));
    state = state.copyWith(
      info: result is AsyncError
          ? AsyncError(_friendly(result.error!), result.stackTrace!)
          : result,
    );
  }

  void setMode(DownloadMode m) => state = state.copyWith(mode: m, optionIndex: 0);
  void setOption(int i) => state = state.copyWith(optionIndex: i);
  void setEmbed(bool v) => state = state.copyWith(embedSubs: v);

  void toggleLang(String lang) {
    final next = {...state.subLangs};
    next.contains(lang) ? next.remove(lang) : next.add(lang);
    state = state.copyWith(subLangs: next);
  }

  /// Queues the download and returns the job id.
  Future<String?> download() async {
    final info = state.info.value;
    if (info == null || !state.canDownload) return null;
    final langs = state.subLangs.toList();
    final auto = info.subtitles.any((t) => t.auto && langs.contains(t.lang));
    return ref.read(downloadRepositoryProvider).enqueue(DownloadRequest(
          info: info,
          mode: state.mode,
          maxHeight: state.selected?.height,
          estimatedBytes: state.selected?.bytes,
          subtitles: SubtitleChoice(langs: langs, includeAuto: auto, embed: state.embedSubs),
        ));
  }

  static Object _friendly(Object e) {
    if (e is PlatformException) {
      final msg = e.message ?? '';
      final line = msg.split('\n').lastWhere((l) => l.contains('ERROR'), orElse: () => msg);
      return line.replaceFirst(RegExp(r'^.*ERROR:\s*'), '').trim();
    }
    return e;
  }
}

final fetchControllerProvider = NotifierProvider<FetchController, FetchState>(FetchController.new);
