import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp _urlPattern = RegExp(r'https?://\S+');

/// Splits [text] on URLs and returns spans — plain text in [baseStyle], and
/// tappable, [linkStyle]-styled spans that open the link via `url_launcher`
/// for each match. Used with `SelectableText.rich` so note bodies stay
/// selectable/copyable while still making links tappable.
List<InlineSpan> linkify(
  String text, {
  required TextStyle baseStyle,
  required TextStyle linkStyle,
}) {
  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in _urlPattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
    }
    // Trailing punctuation right after a URL (a period ending the sentence,
    // a closing bracket, …) reads as part of the link but isn't — trim it
    // off the tappable/highlighted span and let it fall through as plain text.
    var url = match.group(0)!;
    var end = match.end;
    while (url.isNotEmpty && '.,!?)]}\'"'.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
      end--;
    }
    spans.add(
      TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
    start = end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: baseStyle));
  }
  return spans;
}
