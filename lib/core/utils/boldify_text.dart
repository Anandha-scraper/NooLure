import 'package:flutter/material.dart';

import 'linkify_text.dart';

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
/// links via [linkify].
///
/// Bold-splitting must run first. [linkify]'s URL regex is greedy over
/// non-whitespace, so running it over unsegmented text would let a URL
/// immediately followed by a closing `**` (e.g. `**https://foo.com**`)
/// swallow the marker into the matched link, corrupting both. Splitting on
/// `**` first avoids that entirely — a URL living inside a bold span is
/// simply not linkified, which is an accepted, rare trade-off.
List<InlineSpan> formatNoteBody(
  String text, {
  required TextStyle baseStyle,
  required TextStyle boldStyle,
  required TextStyle linkStyle,
}) {
  final spans = <InlineSpan>[];
  for (final segment in _splitBold(text)) {
    if (segment.isBold) {
      spans.add(TextSpan(text: segment.text, style: boldStyle));
    } else {
      spans.addAll(linkify(segment.text, baseStyle: baseStyle, linkStyle: linkStyle));
    }
  }
  return spans;
}
