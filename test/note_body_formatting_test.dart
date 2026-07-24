import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/core/utils/note_body_formatting.dart';

/// Exercises the pure text-transform functions behind the note editor's
/// Bullet/Checklist/Bold toolbar — no widget tree needed, since they only
/// operate on a body string + caret offset.
void main() {
  group('applyBulletToBody', () {
    test('inserts the marker on an empty line at the caret', () {
      final result = applyBulletToBody('', 0);
      expect(result.body, '•\t');
      expect(result.caretOffset, 2);
    });

    test('spreads the bullet across every line of the paragraph', () {
      const body = 'one\ntwo\nthree';
      // Caret in the middle of "two" (offset 5 = "one\nt|wo\nthree").
      final result = applyBulletToBody(body, 5);
      expect(result.body, '•\tone\n•\ttwo\n•\tthree');
      // "two" is preceded by one bulleted line ("•\tone\n"), so the caret
      // shifts by the marker length once for that earlier line, plus once
      // for its own line's marker.
      expect(result.caretOffset, 5 + 2 + 2);
    });

    test('does not bullet across a blank-line paragraph boundary', () {
      const body = 'one\n\ntwo';
      final result = applyBulletToBody(body, 0); // caret on "one"
      expect(result.body, '•\tone\n\ntwo');
    });

    test('re-clicking an already-bulleted paragraph is a content no-op', () {
      const body = '•\tone\n•\ttwo';
      final result = applyBulletToBody(body, 2);
      expect(result.body, body);
    });
  });

  group('applyChecklistToBody', () {
    test('inserts the unchecked marker on an empty line', () {
      final result = applyChecklistToBody('', 0);
      expect(result.body, '☐\t');
      expect(result.caretOffset, 2);
    });

    test('spreads the checklist marker across the paragraph', () {
      const body = 'milk\neggs';
      final result = applyChecklistToBody(body, 0);
      expect(result.body, '☐\tmilk\n☐\teggs');
    });

    test('re-clicking a mix of checked/unchecked lines does not double-insert', () {
      const body = '☑\tmilk\n☐\teggs';
      final result = applyChecklistToBody(body, 0);
      expect(result.body, body);
    });
  });

  group('toggleChecklistAtOffset', () {
    test('flips unchecked to checked when the tap lands on the glyph', () {
      const body = '☐\tmilk';
      final result = toggleChecklistAtOffset(body, 0);
      expect(result, isNotNull);
      expect(result!.body, '☑\tmilk');
      expect(result.caretOffset, 2);
    });

    test('flips checked back to unchecked', () {
      const body = '☑\tmilk';
      final result = toggleChecklistAtOffset(body, 1);
      expect(result, isNotNull);
      expect(result!.body, '☐\tmilk');
    });

    test('returns null when the tap lands past the marker (editing the label)', () {
      const body = '☐\tmilk';
      expect(toggleChecklistAtOffset(body, 3), isNull);
    });

    test('returns null on a line with no checklist marker', () {
      const body = 'just text';
      expect(toggleChecklistAtOffset(body, 0), isNull);
    });
  });

  group('applyBoldToBody', () {
    test('wraps only the current line', () {
      const body = 'one\ntwo\nthree';
      final result = applyBoldToBody(body, 5); // caret on "two"
      expect(result.body, 'one\n**two**\nthree');
    });

    test('does not spread to the paragraph even without a blank-line gap', () {
      const body = 'one\ntwo';
      final result = applyBoldToBody(body, 0); // caret on "one"
      expect(result.body, '**one**\ntwo');
    });

    test('toggles off an already-bolded line', () {
      const body = '**hello**';
      final result = applyBoldToBody(body, 4);
      expect(result.body, 'hello');
    });

    test('clamps the caret to the unwrapped text when it sat inside a delimiter', () {
      const body = '**hello**';
      final result = applyBoldToBody(body, 9); // caret at the very end
      expect(result.body, 'hello');
      expect(result.caretOffset, 5);
    });
  });
}
