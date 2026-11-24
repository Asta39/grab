import 'package:flutter_test/flutter_test.dart';
import 'package:grab/features/club/backup.dart';
import 'package:grab/features/club/game.dart';
import 'package:grab/features/settings/feedback.dart';
import 'package:grab/features/welcome/whats_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('feedback', () {
    test('a problem becomes a bug issue with diagnostics', () {
      final i = buildIssue(
        kind: FeedbackKind.problem,
        text: 'Tapping a song closes the app',
        diagnostics: 'Grab 1.1.1',
      );
      expect(i.title, 'Problem: Tapping a song closes the app');
      expect(i.label, 'bug');
      expect(i.body, contains('Grab 1.1.1'));
    });
    test('an idea becomes an enhancement issue', () {
      final i = buildIssue(kind: FeedbackKind.idea, text: 'Dark mode widget', why: 'At night');
      expect(i.label, 'enhancement');
      expect(i.body, contains('At night'));
    });
    test('the link is a GitHub new-issue form and stays short', () {
      final i = buildIssue(kind: FeedbackKind.problem, text: 'x', diagnostics: 'y' * 20000);
      final u = Uri.parse(issueUrl(i));
      expect(u.host, 'github.com');
      expect(u.path, '/Asta39/grab/issues/new');
      expect(u.queryParameters['body']!.length, lessThan(5600));
    });
  });

  test('backup round trip keeps progress, not the Groq key', () {
    const g = GameState(xp: 700, best: 9, unlocked: {'night_owl': 1});
    final text = buildBackup(g, {'fun.hat': 'crown', 'fun.sounds': true});
    expect(text, isNot(contains('groq')));
    final b = parseBackup(text);
    expect(b.game.toJson(), g.toJson());
    expect(b.fun['fun.hat'], 'crown');
    expect(() => parseBackup('{"kind":"other"}'), throwsFormatException);
  });

  test("What's new shows once, only to people updating", () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    expect(takeWhatsNew(p, returning: true), isTrue);
    expect(takeWhatsNew(p, returning: true), isFalse);
    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    expect(takeWhatsNew(fresh, returning: false), isFalse);
  });
}
