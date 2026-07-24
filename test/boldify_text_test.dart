import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/core/utils/boldify_text.dart';

const _base = TextStyle(fontSize: 13.5);
const _bold = TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold);
const _link = TextStyle(fontSize: 13.5, decoration: TextDecoration.underline);

String _textOf(InlineSpan span) => (span as TextSpan).text!;

void main() {
  group('boldify', () {
    test('plain text with no markers stays a single plain span', () {
      final spans = boldify('just plain text', baseStyle: _base, boldStyle: _bold);
      expect(spans, hasLength(1));
      expect(_textOf(spans.first), 'just plain text');
      expect((spans.first as TextSpan).style, _base);
    });

    test('bold-only text strips the delimiters and applies boldStyle', () {
      final spans = boldify('**hello**', baseStyle: _base, boldStyle: _bold);
      expect(spans, hasLength(1));
      expect(_textOf(spans.first), 'hello');
      expect((spans.first as TextSpan).style, _bold);
    });

    test('an unclosed marker is left as literal plain text', () {
      final spans = boldify('hello **world', baseStyle: _base, boldStyle: _bold);
      expect(spans, hasLength(1));
      expect(_textOf(spans.first), 'hello **world');
      expect((spans.first as TextSpan).style, _base);
    });
  });

  group('formatNoteBody', () {
    test('bold segments are not linkified, plain segments still are', () {
      final spans = formatNoteBody(
        '**bold** see https://example.com',
        baseStyle: _base,
        boldStyle: _bold,
        linkStyle: _link,
      );

      final boldSpan = spans.firstWhere((s) => (s as TextSpan).style == _bold);
      expect(_textOf(boldSpan), 'bold');

      final linkSpan = spans.firstWhere((s) => (s as TextSpan).style == _link);
      expect(_textOf(linkSpan), 'https://example.com');
    });
  });
}
