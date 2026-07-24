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

/// Shared bullet/checklist insertion: on an empty line, splices [marker] in
/// at the caret; on a non-empty line, spreads [marker] across every line of
/// the contiguous non-blank paragraph around the caret that isn't already
/// marked (per [isMarked]), rebuilding the body in one pass so the new caret
/// offset can be captured exactly when the rebuild reaches the caret's
/// original line — no separate delta bookkeeping needed.
({String body, int caretOffset}) _applyLineMarker(
  String body,
  int caretOffset, {
  required String marker,
  required bool Function(String line) isMarked,
}) {
  caretOffset = caretOffset.clamp(0, body.length);
  final lines = _splitLines(body);
  final idx = _lineIndexForOffset(lines, caretOffset);
  final currentLineText = body.substring(lines[idx].start, lines[idx].end);

  if (currentLineText.trim().isEmpty) {
    final newBody =
        body.substring(0, caretOffset) + marker + body.substring(caretOffset);
    return (body: newBody, caretOffset: caretOffset + marker.length);
  }

  final range = _paragraphLineRange(lines, body, idx);
  final offsetWithinCaretLine = caretOffset - lines[idx].start;

  final out = StringBuffer();
  int? newCaretOffset;
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) out.write('\n');
    final lineText = body.substring(lines[i].start, lines[i].end);
    final withinRange = i >= range.startLine && i <= range.endLine;
    final prepend = withinRange && !isMarked(lineText);
    final lineStartInOutput = out.length;
    if (prepend) out.write(marker);
    out.write(lineText);
    if (i == idx) {
      newCaretOffset =
          lineStartInOutput +
          (prepend ? marker.length : 0) +
          offsetWithinCaretLine;
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
  isMarked: (line) => line.startsWith(bulletMarker),
);

({String body, int caretOffset}) applyChecklistToBody(
  String body,
  int caretOffset,
) => _applyLineMarker(
  body,
  caretOffset,
  marker: checklistUncheckedMarker,
  isMarked: (line) =>
      line.startsWith(checklistUncheckedMarker) ||
      line.startsWith(checklistCheckedMarker),
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
({String body, int caretOffset}) applyBoldToBody(String body, int caretOffset) {
  caretOffset = caretOffset.clamp(0, body.length);
  final lines = _splitLines(body);
  final idx = _lineIndexForOffset(lines, caretOffset);
  final line = lines[idx];
  final lineText = body.substring(line.start, line.end);
  final offsetWithinLine = caretOffset - line.start;

  final isWrapped =
      lineText.startsWith(boldDelimiter) &&
      lineText.endsWith(boldDelimiter) &&
      lineText.length >= 2 * boldDelimiter.length;

  final String newLineText;
  final int newOffsetWithinLine;
  if (isWrapped) {
    newLineText = lineText.substring(
      boldDelimiter.length,
      lineText.length - boldDelimiter.length,
    );
    if (offsetWithinLine <= boldDelimiter.length) {
      newOffsetWithinLine = 0;
    } else if (offsetWithinLine >= lineText.length - boldDelimiter.length) {
      newOffsetWithinLine = newLineText.length;
    } else {
      newOffsetWithinLine = offsetWithinLine - boldDelimiter.length;
    }
  } else {
    newLineText = '$boldDelimiter$lineText$boldDelimiter';
    newOffsetWithinLine = offsetWithinLine + boldDelimiter.length;
  }

  final newBody =
      body.substring(0, line.start) + newLineText + body.substring(line.end);
  return (body: newBody, caretOffset: line.start + newOffsetWithinLine);
}
