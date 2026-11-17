import 'package:flutter/widgets.dart';

/// Extra room the floating bars (mini player) take above the dock, so lists can
/// scroll their last item clear of them. Set by the shell.
class DockInset extends InheritedWidget {
  const DockInset({super.key, required this.extra, required super.child});

  final double extra;

  /// Bottom padding for a tab's scrolling list: the dock, plus any mini player.
  static double listBottom(BuildContext context) =>
      120 +
      (context.dependOnInheritedWidgetOfExactType<DockInset>()?.extra ?? 0);

  @override
  bool updateShouldNotify(DockInset old) => old.extra != extra;
}
