import 'dart:math';
import '../token_types.dart' as token_type;
import 'ast.dart';
import 'directions.dart' show down, right;
import 'mapping.dart';
import 'parser.dart' show Document;

/// The default list of patterns that is used by [scan] to recognize tokens in a
/// source string.
const List<TokenPattern> defaultPatterns = const [
  // mathlite specific formatting
  const TokenPattern('↑', token_type.infixOperator),
  const TokenPattern('↓', token_type.infixOperator),

  // brackets
  const TokenPattern('(', token_type.lparen),
  const TokenPattern(')', token_type.rparen),
  const TokenPattern('[', token_type.lbracket),
  const TokenPattern(']', token_type.rbracket),
  const TokenPattern('{', token_type.lbrace),
  const TokenPattern('}', token_type.rbrace),

  // universal operators
  const TokenPattern('=', token_type.infixOperator),
  const TokenPattern(',', token_type.infixOperator),

  // number arithmetic
  const TokenPattern('+', token_type.infixOperator),
  const TokenPattern('-', token_type.infixOperator),
  const TokenPattern('*', token_type.infixOperator),
  const TokenPattern('/', token_type.infixOperator),
  const TokenPattern('√', token_type.prefixOperator),
  const TokenPattern('∑', token_type.prefixOperator),
  const TokenPattern('∏', token_type.prefixOperator),

  // boolean logic
  const TokenPattern('∀', token_type.infixOperator),
  const TokenPattern('∃', token_type.infixOperator),
  const TokenPattern('∄', token_type.infixOperator),
  const TokenPattern('⋀', token_type.infixOperator),
  const TokenPattern('⋁', token_type.infixOperator),

  // sets
  const TokenPattern('∅', token_type.identifier),
  const TokenPattern('⊂', token_type.infixOperator),
  const TokenPattern('⊃', token_type.infixOperator),
  const TokenPattern('⊄', token_type.infixOperator),
  const TokenPattern('⊅', token_type.infixOperator),
  const TokenPattern('⊆', token_type.infixOperator),
  const TokenPattern('⊇', token_type.infixOperator),
  const TokenPattern('⋂', token_type.infixOperator),
  const TokenPattern('⋃', token_type.infixOperator),
  const TokenPattern('∖', token_type.infixOperator),
  const TokenPattern('∈', token_type.infixOperator),
  const TokenPattern('∉', token_type.infixOperator),
  const TokenPattern('∋', token_type.infixOperator),
  const TokenPattern('∌', token_type.infixOperator),
];

/// Compares substrings of [source] against all [patterns] to parse the raw
/// string into tokens. Patterns are matched in the same order as they appear in
/// [patterns], und characters are matched in iteration order. (left to right,
/// line by line)
///
/// Throws an [ArgumentError] if a character in [source] doesn't match any
/// pattern.
Document scan(final MappedString source,
    [Iterable<TokenPattern> patterns = defaultPatterns]) {
  final document = new Document(source.dimensions);
  processCharacter:
  for (final position in source.keys) {
    if (document.lookupPoint(position) != null) {
      // This character has already been consumed by a vertical parse.
      continue;
    }

    for (final pattern in patterns) {
      final token = pattern.match(source, position);
      if (token != null) {
        document.add(token);
        continue processCharacter;
      }
    }

    throw new ArgumentError('Parsing error in line ${position.y}, '
        "column ${position.x}: Couldn't match the character "
        '${source[position]} against any pattern');
  }
  return document;
}

/// The simplest fragment type, and the only one that doesn't have any children.
class Token extends Fragment {
  Token(this.type, this.lexeme, Point<int> firstCharacter,
      Point<int> lastCharacter)
      : super(firstCharacter, lastCharacter);

  final String type;

  /// The characters that form this token.
  final String lexeme;

  @override
  Iterable<Fragment> get children => const [];
}

///
class TokenPattern {
  const TokenPattern(this.pattern, this.type, {this.direction: right});

  /// The pattern as a String. This should support RegExp-like syntax in the
  /// future; Right now, it only recognizes on literal matches.
  final String pattern;

  /// If this pattern matches an input, it creates a [Token] of this type.
  final String type;

  /// Must be either [right] or [down].
  final Point direction;

  /// Returns a token of type [type], if [pattern] could be matched against
  /// [input] at [position]. Else, returns `null`.
  Token match(final MappedString input, final Point<int> position) {
    var current = position;
    final lexeme = new StringBuffer();
    for (final expected
        in pattern.runes.map((rune) => new String.fromCharCode(rune))) {
      final char = input[current];
      if (char != expected) return null;
      direction == down ? lexeme.writeln(char) : lexeme.write(char);
      current += direction;
    }
    return new Token(type, lexeme.toString(), position, current - direction);
  }
}
