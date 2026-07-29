import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'linkify_text.dart';
import 'note_body_formatting.dart';

final RegExp _boldPattern = RegExp(r'\*\*(.+?)\*\*');

/// Splits [text] on `**bold**` markers into alternating plain/bold segments,
/// with the `**` delimiters stripped from the bold segment's own text.
List<({String text, bool isBold})> _splitBold(String text) {
  final segments = <({String text, bool isBold})>[];
  var start = 0;
  for (final match in _boldPattern.allMatches(text)) {
    if (match.start > start) {
      segments.add((text: text.substring(start, match.start), isBold: false));
    }
    segments.add((text: match.group(1)!, isBold: true));
    start = match.end;
  }
  if (start < text.length) {
    segments.add((text: text.substring(start), isBold: false));
  }
  return segments;
}

/// Renders `**bold**` markers as actually-bold spans — used on its own where
/// a body is known not to contain links, or as a building block of
/// [formatNoteBody].
List<InlineSpan> boldify(
  String text, {
  required TextStyle baseStyle,
  required TextStyle boldStyle,
}) => [
  for (final segment in _splitBold(text))
    TextSpan(text: segment.text, style: segment.isBold ? boldStyle : baseStyle),
];

/// The note body's full read-only rendering: `**bold**` markers become bold
/// spans, and — within the non-bold segments only — URLs become tappable
/// links via [linkify]. When [onToggleChecklist] is given, a line starting
/// with a checklist glyph gets a tappable span for just that glyph (called
/// with the line's start offset in [text], ready to hand to
/// `toggleChecklistAtOffset`) — this is what lets a checklist item be
/// checked/unchecked straight from a read-only view, not just the editor.
///
/// Bold-splitting must run first. [linkify]'s URL regex is greedy over
/// non-whitespace, so running it over unsegmented text would let a URL
/// immediately followed by a closing `**` (e.g. `**https://foo.com**`)
/// swallow the marker into the matched link, corrupting both. Splitting on
/// `**` first avoids that entirely — a URL living inside a bold span is
/// simply not linkified, which is an accepted, rare trade-off.
///
/// Processed line-by-line (rather than over the whole string at once) so the
/// checklist glyph — always the first character of its line — is easy to
/// carve out; this is behavior-preserving for bold/links, since neither
/// `_boldPattern` nor `linkify`'s URL regex ever matches across a newline.
List<InlineSpan> formatNoteBody(
  String text, {
  required TextStyle baseStyle,
  required TextStyle boldStyle,
  required TextStyle linkStyle,
  void Function(int lineStartOffset)? onToggleChecklist,
}) {
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  var offset = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineStart = offset;
    final isChecklistLine =
        onToggleChecklist != null &&
        (line.startsWith(checklistUncheckedMarker) ||
            line.startsWith(checklistCheckedMarker));

    if (isChecklistLine) {
      spans.add(
        TextSpan(
          text: line.substring(0, 1),
          style: baseStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onToggleChecklist(lineStart),
        ),
      );
      _appendFormatted(spans, line.substring(1), baseStyle, boldStyle, linkStyle);
    } else {
      _appendFormatted(spans, line, baseStyle, boldStyle, linkStyle);
    }

    offset += line.length + 1;
    if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: baseStyle));
  }
  return spans;
}

void _appendFormatted(
  List<InlineSpan> spans,
  String text,
  TextStyle baseStyle,
  TextStyle boldStyle,
  TextStyle linkStyle,
) {
  for (final segment in _splitBold(text)) {
    if (segment.isBold) {
      spans.add(TextSpan(text: segment.text, style: boldStyle));
    } else {
      spans.addAll(linkify(segment.text, baseStyle: baseStyle, linkStyle: linkStyle));
    }
  }
}
