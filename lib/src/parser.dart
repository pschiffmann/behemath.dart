import 'dart:math';
import '../token_types.dart' as token_type;
import 'ast.dart';
import 'directions.dart';
import 'grid.dart';
import 'scanner.dart';

/// Maps opening to closing brackets.
const Map<String, String> brackets = const {
  token_type.lparen: token_type.rparen,
  token_type.lbracket: token_type.rbracket,
  token_type.lbrace: token_type.rbrace,
};

/// Restructures the assigned document into a meaningful syntax tree. [document]
/// is modified in-place. This method expects that [document] contains only
/// [Token] fragments.
Fragment parse(Document document) {
  recognizeBlocks(document).forEach(assemble);
  return null;
  //return document.single;
}

///
Iterable<Grid> recognizeBlocks(Document document) sync* {
  final it = new PrioritizingIterator(document.cast<Token>());
  final unclosedBrackets = <Token>[];

  while (it.moveNext()) {
    final token = it.current;

    if (unclosedBrackets.isNotEmpty) {
      final leftBracket = unclosedBrackets.last;
      if (token.bottom < leftBracket.top || token.top > leftBracket.bottom) {
        // We read past the end of the current brackets right hand side.
        throw new ParseException('Unclosed bracket', leftBracket);
      }
      if (token.top < leftBracket.top && token.bottom > leftBracket.top ||
          token.top < leftBracket.bottom && token.bottom > leftBracket.bottom) {
        throw new ParseException('token spans across a fenced block');
      }
    }

    if (brackets.containsKey(token.type)) {
      unclosedBrackets.add(token);
      it.prioritizeColumn(token.top, token.bottom);
    } else if (brackets.containsValue(token.type)) {
      if (unclosedBrackets.isEmpty) {
        throw new ParseException('Unbalanced bracket', token);
      }
      final leftBracket = unclosedBrackets.last;
      if (token.type != brackets[leftBracket.type] ||
          token.top != leftBracket.top ||
          token.bottom != leftBracket.bottom) {
        throw new ParseException('Unbalanced bracket', token);
      }
      unclosedBrackets.removeLast();
      if (leftBracket.right + 1 != token.left) {
        yield new GridSection(
            document,
            new Rectangle.fromPoints(
                leftBracket.topLeft + right, token.bottomRight + left));
      }
    }
  }
  if (unclosedBrackets.isNotEmpty) {
    throw new ParseException('Unclosed bracket', unclosedBrackets.last);
  }
  yield document;
}

///
void assemble(Grid grid) {
  print(grid.dimensions);
}

/// During parsing, fragments are stored in a mutable [Document] object.
class Document extends Grid<Fragment> {
  Document(Rectangle<int> dimensions) : super(dimensions);

  /// Adds [fragment] and removes all its [Fragment.children] from this
  /// document. Throws an [AssertionError] if [fragment] was already in this
  /// document, or any of its children was not.
  @override
  void add(Fragment fragment) {
    fragment.children.forEach(remove);
    assert(lookupArea(fragment).isEmpty);
    super.add(fragment);
  }
}

class RowCandidate {
  RowCandidate(Fragment fragment)
      : fragments = [fragment],
        top = fragment.top,
        bottom = fragment.bottom;

  final List<Fragment> fragments;

  int top;
  int bottom;

  void add(Fragment fragment) {
    fragments.add(fragment);
    top = min(top, fragment.top);
    bottom = max(bottom, fragment.bottom);
  }

  bool containsHeight(Rectangle<int> area) =>
      top <= area.top && bottom >= area.bottom;
}

/// Thrown by the parser if it encounters invalid input.
class ParseException implements Exception {
  ParseException(this.message, [this.fragment]);

  final String message;
  final Fragment fragment;

  @override
  String toString() => fragment == null
      ? 'Parsing error: $message'
      : 'Parsing error at fragment (${fragment.top}, ${fragment.left})-'
      '(${fragment.bottom}x${fragment.right}): $message';
}
