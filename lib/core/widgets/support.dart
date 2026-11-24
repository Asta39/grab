import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/pop_theme.dart';
import '../update/app_update.dart';
import '../utils/haptics.dart';

/// Where support for Grab goes.
const supportUrl = 'https://buymesoda.com/TI6ooK66tVZuouHKmIeUnxE4Zey2';

/// The soda orange, matching the Buy Me a Soda art.
const _soda = Color(0xFFFF8A3D);

const _dayKey = 'support.lastShownDay';

String _today([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

/// True the first time the app opens on a given day; marks the day as shown.
bool takeDailySupport(SharedPreferences prefs, [DateTime? now]) {
  final today = _today(now);
  if (prefs.getString(_dayKey) == today) return false;
  prefs.setString(_dayKey, today);
  return true;
}

void openSupport() {
  Haptics.light();
  openUrl(supportUrl);
}

/// "Enjoying Grab?" card that floats above the dock, once a day, next to
/// the buddy. Swipe down or tap the cross to dismiss it.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: 'Support Grab',
      child: Dismissible(
        key: const ValueKey('support-card'),
        direction: DismissDirection.down,
        onDismissed: (_) => onDismiss(),
        child: Material(
          color: dark ? const Color(0xFF232325) : Colors.white,
          elevation: 10,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dark ? Colors.white12 : Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/support/soda.png',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enjoying Grab?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "It's free and open source. A soda keeps it going.",
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.25,
                          color: context.pop.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SodaButton(
                        label: 'Buy me a soda',
                        onTap: () {
                          openSupport();
                          onDismiss();
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Not now',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Haptics.selection();
                    onDismiss();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: context.pop.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SodaButton extends StatelessWidget {
  const _SodaButton({
    required this.label,
    required this.onTap,
    this.big = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) => Material(
    color: _soda,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: big ? 20 : 14,
          vertical: big ? 12 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_drink_rounded,
              size: big ? 18 : 15,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: Pop.font,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: big ? 15 : 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Always-there banner at the top of Settings.
class SupportBanner extends StatelessWidget {
  const SupportBanner({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Support Grab',
    child: ClipRRect(
      borderRadius: Pop.cardRadius,
      child: AspectRatio(
        aspectRatio: 2.15,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/support/banner.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              // Text stays left of the glass.
              child: FractionallySizedBox(
                widthFactor: 0.6,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Grab is free and\nopen source.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No ads. No tracking. Just a soda.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const Spacer(),
                    _SodaButton(
                      label: 'Buy me a soda',
                      onTap: openSupport,
                      big: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
