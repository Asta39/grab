import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/pop_theme.dart';
import '../../core/update/app_update.dart';
import '../../core/utils/error_log.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pop_widgets.dart';
import '../../core/widgets/toasts.dart';
import '../club/buddy.dart';
import '../club/rewards.dart';

const _repo = 'https://github.com/Asta39/grab';

enum FeedbackKind { problem, idea }

Future<void> showFeedback(BuildContext context, FeedbackKind kind) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FeedbackSheet(kind),
    );

/// The report or idea as a GitHub issue: title, body and label.
({String title, String body, String label}) buildIssue({
  required FeedbackKind kind,
  required String text,
  String? why,
  String? diagnostics,
}) {
  final first = text.trim().split('\n').first;
  final short = first.length > 70 ? '${first.substring(0, 70)}…' : first;
  if (kind == FeedbackKind.idea) {
    return (
      title: 'Idea: $short',
      label: 'enhancement',
      body: [
        '### The idea',
        text.trim(),
        if (why != null && why.trim().isNotEmpty) ...[
          '',
          '### Why it would help',
          why.trim(),
        ],
        '',
        '_Suggested from inside Grab._',
      ].join('\n'),
    );
  }
  return (
    title: 'Problem: $short',
    label: 'bug',
    body: [
      '### What happened',
      text.trim(),
      if (diagnostics != null) ...[
        '',
        '### Diagnostics',
        '```',
        diagnostics,
        '```',
      ],
      '',
      '_Reported from inside Grab._',
    ].join('\n'),
  );
}

/// A link that opens GitHub's new-issue form, filled in. Long logs are cut
/// so the link stays under what browsers accept.
String issueUrl(({String title, String body, String label}) issue) {
  var body = issue.body;
  if (body.length > 5500) body = '${body.substring(0, 5500)}\n…(cut)';
  return Uri.parse('$_repo/issues/new')
      .replace(
        queryParameters: {
          'title': issue.title,
          'body': body,
          'labels': issue.label,
        },
      )
      .toString();
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet(this.kind);

  final FeedbackKind kind;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _text = TextEditingController();
  final _why = TextEditingController();
  var _attach = true;
  var _showLog = false;
  String? _diagnostics;

  bool get _problem => widget.kind == FeedbackKind.problem;

  @override
  void initState() {
    super.initState();
    if (_problem) _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    final info = await PackageInfo.fromPlatform();
    final d = [
      'Grab ${info.version} (${info.buildNumber})',
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      '',
      ErrorLog.asText(),
    ].join('\n');
    if (mounted) setState(() => _diagnostics = d);
  }

  @override
  void dispose() {
    _text.dispose();
    _why.dispose();
    super.dispose();
  }

  ({String title, String body, String label}) get _issue => buildIssue(
    kind: widget.kind,
    text: _text.text,
    why: _why.text,
    diagnostics: _problem && _attach ? _diagnostics : null,
  );

  void _send() {
    if (_text.text.trim().isEmpty) {
      Haptics.warning();
      popToast(
        _problem ? 'Tell us what happened first' : 'Describe your idea first',
      );
      return;
    }
    Haptics.success();
    Buddy.say(_problem ? 'Thanks, we\'ll take a look' : 'Ooh, good idea!');
    openUrl(issueUrl(_issue));
    Navigator.pop(context);
  }

  Future<void> _copy() async {
    if (_text.text.trim().isEmpty) return _send();
    final i = _issue;
    await Clipboard.setData(ClipboardData(text: '${i.title}\n\n${i.body}'));
    Haptics.success();
    popToast(
      'Copied',
      icon: Icons.copy_rounded,
      detail: 'Paste it anywhere, or into a GitHub issue later.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    InputDecoration field(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.pop.field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DressedBuddy(
                  mood: _problem ? BuddyMood.search : BuddyMood.cheer,
                  hat: Rewards.hat.value,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _problem ? 'Report a problem' : 'Suggest a feature',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _problem
                            ? 'Something broke or looks wrong? Tell us.'
                            : 'What would make Grab better for you?',
                        style: TextStyle(color: context.pop.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: field(
                _problem
                    ? 'What happened, and what were you doing? A link that fails helps a lot.'
                    : 'Your idea, in a sentence or two',
              ),
            ),
            if (!_problem) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _why,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: field('Why would it help? (optional)'),
              ),
            ],
            if (_problem) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _attach,
                activeTrackColor: Pop.yellow,
                activeThumbColor: Pop.ink,
                onChanged: (v) => setState(() => _attach = v),
                title: const Text(
                  'Attach diagnostics',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Grab version, system and recent errors. No files or history.',
                ),
              ),
              if (_attach)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _showLog = !_showLog),
                    child: Text(
                      _showLog
                          ? 'Hide what\'s attached'
                          : 'See what\'s attached',
                    ),
                  ),
                ),
              if (_attach && _showLog)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.pop.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _diagnostics ?? '…',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            PopButton(
              label: _problem ? 'Send report on GitHub' : 'Send idea on GitHub',
              icon: Icons.open_in_new_rounded,
              onPressed: _send,
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('No GitHub account? Copy it instead'),
            ),
          ],
        ),
      ),
    );
  }
}
