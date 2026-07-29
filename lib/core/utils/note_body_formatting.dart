// Pure text-manipulation for the note editor's Bullet/Checklist/Bold
// toolbar. Every function here takes the current body string and a caret
// offset and returns the new body + caret offset — no TextEditingController,
// no BuildContext — so the tricky line/paragraph/offset arithmetic can be
// unit-tested directly, independent of the widget that calls it.

const String bulletMarker = '•\t';
const String checklistUncheckedMarker = '☐\t';
const String checklistCheckedMarker = '☑\t';
const String boldDelimiter = '**';

class _Line {
  const _Line(this.start, this.end);

  /// [end] is the offset of the line's trailing `\n` (or the text length for
  /// the last line) — it does not include the newline itself.
  final int start;
  final int end;
}

List<_Line> _splitLines(String text) {
  final lines = <_Line>[];
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n') {
      lines.add(_Line(start, i));
      start = i + 1;
    }
  }
  lines.add(_Line(start, text.length));
  return lines;
}

/// The first line whose end offset is at or after [offset] — i.e. a caret
/// sitting exactly at a line's end belongs to that line, and a caret at the
/// very start of the next line belongs to the next one. `lines[i+1].start ==
/// lines[i].end + 1` always holds (the `\n` sits between them), so there's no
/// offset that satisfies both a line's end and the next line's start.
int _lineIndexForOffset(List<_Line> lines, int offset) {
  for (var i = 0; i < lines.length; i++) {
    if (offset <= lines[i].end) return i;
  }
  return lines.length - 1;
}

bool _isBlank(String text, _Line line) =>
    text.substring(line.start, line.end).trim().isEmpty;

({int startLine, int endLine}) _paragraphLineRange(
  List<_Line> lines,
  String text,
  int idx,
) {
  var s = idx;
  var e = idx;
  while (s > 0 && !_isBlank(text, lines[s - 1])) {
    s--;
  }
  while (e < lines.length - 1 && !_isBlank(text, lines[e + 1])) {
    e++;
  }
  return (startLine: s, endLine: e);
}

/// The bullet/checklist marker at the very start of [line], or `''` if none.
/// Bullet and checklist are mutually exclusive per line — a line carries at
/// most one of these three — so this is the single source of truth both for
/// detecting a line's current list state and for stripping it.
String _existingPrefix(String line) {
  for (final m in [bulletMarker, checklistUncheckedMarker, checklistCheckedMarker]) {
    if (line.startsWith(m)) return m;
  }
  return '';
}

/// A freshly-applied marker defaults in this much extra indent before the
/// item's own text — plain, independent characters the user can backspace
/// away, not part of the marker itself (so removing them never breaks
/// bullet/checklist detection, which only ever looks at the 2-char marker).
const String _defaultMarkerGap = '    ';

/// Shared bullet/checklist toggle: on an empty line, splices [marker] (plus
/// the default gap) in at the caret; on a non-empty line, applies [marker]
/// to every line of the contiguous non-blank paragraph around the caret,
/// replacing whatever bullet/checklist prefix (if any) each line already
/// carries — unless every line in the paragraph already carries this same
/// marker family (per [isSameFamily]), in which case the whole paragraph is
/// toggled back to plain text instead. Rebuilds the body in one pass so the
/// new caret offset can be captured exactly when the rebuild reaches the
/// caret's original line — no separate delta bookkeeping needed.
({String body, int caretOffset}) _applyLineMarker(
  String body,
  int caretOffset, {
  required String marker,
  required bool Function(String existingPrefix) isSameFamily,
}) {
  caretOffset = caretOffset.clamp(0, body.length);
  final lines = _splitLines(body);
  final idx = _lineIndexForOffset(lines, caretOffset);
  final currentLineText = body.substring(lines[idx].start, lines[idx].end);

  if (currentLineText.trim().isEmpty) {
    final insertion = marker + _defaultMarkerGap;
    final newBody =
        body.substring(0, caretOffset) + insertion + body.substring(caretOffset);
    return (body: newBody, caretOffset: caretOffset + insertion.length);
  }

  final range = _paragraphLineRange(lines, body, idx);
  final offsetWithinCaretLine = caretOffset - lines[idx].start;

  var toggleOff = true;
  for (var i = range.startLine; i <= range.endLine && toggleOff; i++) {
    final lineText = body.substring(lines[i].start, lines[i].end);
    if (!isSameFamily(_existingPrefix(lineText))) toggleOff = false;
  }

  final out = StringBuffer();
  int? newCaretOffset;
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) out.write('\n');
    final lineText = body.substring(lines[i].start, lines[i].end);
    final withinRange = i >= range.startLine && i <= range.endLine;
    final lineStartInOutput = out.length;

    if (!withinRange) {
      out.write(lineText);
      continue;
    }

    final existing = _existingPrefix(lineText);
    final content = lineText.substring(existing.length);
    final newPrefix = toggleOff
        ? ''
        : existing.isEmpty
        ? marker + _defaultMarkerGap
        : marker;
    out.write(newPrefix);
    out.write(content);

    if (i == idx) {
      final newOffsetWithinLine = offsetWithinCaretLine <= existing.length
          ? newPrefix.length
          : offsetWithinCaretLine - existing.length + newPrefix.length;
      newCaretOffset = lineStartInOutput + newOffsetWithinLine;
    }
  }
  return (body: out.toString(), caretOffset: newCaretOffset!);
}

({String body, int caretOffset}) applyBulletToBody(
  String body,
  int caretOffset,
) => _applyLineMarker(
  body,
  caretOffset,
  marker: bulletMarker,
  isSameFamily: (existing) => existing == bulletMarker,
);

({String body, int caretOffset}) applyChecklistToBody(
  String body,
  int caretOffset,
) => _applyLineMarker(
  body,
  caretOffset,
  marker: checklistUncheckedMarker,
  isSameFamily: (existing) =>
      existing == checklistUncheckedMarker || existing == checklistCheckedMarker,
);

/// Flips the checklist marker on the line under [caretOffset], but only if
/// the tap landed within the marker itself (offset 0/1/2 into the line) —
/// deeper into the line is normal caret placement for editing the item's
/// label, not a toggle. Returns `null` if there's nothing to toggle there.
({String body, int caretOffset})? toggleChecklistAtOffset(
  String body,
  int caretOffset,
) {
  caretOffset = caretOffset.clamp(0, body.length);
  final lines = _splitLines(body);
  final idx = _lineIndexForOffset(lines, caretOffset);
  final line = lines[idx];
  final lineText = body.substring(line.start, line.end);
  final offsetWithinLine = caretOffset - line.start;

  if (offsetWithinLine > checklistUncheckedMarker.length) return null;

  final String newMarker;
  if (lineText.startsWith(checklistUncheckedMarker)) {
    newMarker = checklistCheckedMarker;
  } else if (lineText.startsWith(checklistCheckedMarker)) {
    newMarker = checklistUncheckedMarker;
  } else {
    return null;
  }

  final newBody =
      body.substring(0, line.start) +
      newMarker +
      body.substring(line.start + newMarker.length);
  return (body: newBody, caretOffset: line.start + newMarker.length);
}

/// Wraps (or, if already wrapped, unwraps) only the single line under
/// [caretOffset] in [boldDelimiter] — never the surrounding paragraph.
/// Operates on the line's content *after* any existing bullet/checklist
/// prefix, so bold toggles independently of whichever (if any) list marker
/// the line carries, and never stacks a second `**` wrap in front of it.
({String body, int caretOffset}) applyBoldToBody(String body, int caretOffset) {
  caretOffset = caretOffset.clamp(0, body.length);
  final lines = _splitLines(body);
  final idx = _lineIndexForOffset(lines, caretOffset);
  final line = lines[idx];
  final lineText = body.substring(line.start, line.end);
  final offsetWithinLine = caretOffset - line.start;

  final prefix = _existingPrefix(lineText);
  final content = lineText.substring(prefix.length);
  final offsetWithinContent = (offsetWithinLine - prefix.length).clamp(
    0,
    content.length,
  );

  final isWrapped =
      content.startsWith(boldDelimiter) &&
      content.endsWith(boldDelimiter) &&
      content.length >= 2 * boldDelimiter.length;

  final String newContent;
  final int newOffsetWithinContent;
  if (isWrapped) {
    newContent = content.substring(
      boldDelimiter.length,
      content.length - boldDelimiter.length,
    );
    if (offsetWithinContent <= boldDelimiter.length) {
      newOffsetWithinContent = 0;
    } else if (offsetWithinContent >= content.length - boldDelimiter.length) {
      newOffsetWithinContent = newContent.length;
    } else {
      newOffsetWithinContent = offsetWithinContent - boldDelimiter.length;
    }
  } else {
    newContent = '$boldDelimiter$content$boldDelimiter';
    newOffsetWithinContent = offsetWithinContent + boldDelimiter.length;
  }

  final newLineText = prefix + newContent;
  final newOffsetWithinLine = prefix.length + newOffsetWithinContent;

  final newBody =
      body.substring(0, line.start) + newLineText + body.substring(line.end);
  return (body: newBody, caretOffset: line.start + newOffsetWithinLine);
}
