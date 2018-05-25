import '../token_types.dart' as token_type;
import 'ast.dart';
import 'scanner.dart';

/// Maps opening to closing brackets.
const Map<String, String> closingBrackets = const {
  token_type.lparen: token_type.rparen,
  token_type.lbracket: token_type.rbracket,
  token_type.lbrace: token_type.rbrace,
  token_type.bar: token_type.bar
};

/// Token types that indicate the end of a [FencedBlock].
const List<String> rightBrackets = const [
  token_type.rparen,
  token_type.rbracket,
  token_type.rbrace
];

/// Restructures the assigned document into a meaningful syntax tree. [document]
/// is modified in-place. This method expects that [document] contains only
/// [Token] fragments.
void assemble(Document document) {
  final containers = <Container>[document];
  for (final token in new List<Token>.from(document.rootFragments)) {
    if (token.container != document) {
      // This token has been claimed by a descendant [FencedBlock].
      continue;
    } else if (token.parent != null) {
      // This token is a closing bracket in a descendant [FencedBlock].
      continue;
    }

    final closingBracket = closingBrackets[token.type];
    if (closingBracket != null) {
      parseFencedBlock(document, token, closingBracket, containers);
    }
  }

  for (final container in containers) {
    print(container.body);
  }
}

/// Parses the [FencedBlock] that starts with [leftBracket], adds it as a child
/// of [document], and places it in [containers]. Returns a reference to the
/// created fragment.
FencedBlock parseFencedBlock(Document document, Token leftBracket,
    String rightBracket, List<Container> containers) {
  final claimed = <Fragment>[];
  for (final fragment in document.rightOf(leftBracket)) {
    final token = fragment as Token;
    if (token.container != document) {
      // This token has been claimed by a descendant [FencedBlock].
      continue;
    } else if (token.parent != null) {
      // This token is a closing bracket in a descendant [FencedBlock].
      continue;
    }

    // We found a right bracket. Either [token] terminates this FencedBlock, or
    // this is a syntax error.
    if (rightBrackets.contains(token.type)) {
      if (token.type == rightBracket &&
          token.dimensions.height == leftBracket.dimensions.height &&
          token.dimensions.top == leftBracket.dimensions.top) {
        final result = new FencedBlock(leftBracket, token);
        claimed.forEach(result.claim);
        document.add(result);
        containers.add(result);
        return result;
      } else {
        throw new ParseException('Unbalanced bracket', token);
      }
    }
    // We found a left bracket. Start a new [FencedBlock] parse and add the
    // result as a root fragment of this one.
    else if (closingBrackets.containsKey(token.type)) {
      claimed.add(parseFencedBlock(
          document, token, closingBrackets[token.type], containers));
    }
    // We found a non-bracket token. Claim it as a root fragment of this and let
    // the subsequent parse phases handle it.
    else {
      claimed.add(token);
    }
  }
  // We found no right bracket that could close this block.
  throw new ParseException('No closing bracket found', leftBracket);
}

/// Thrown by the parser if it encounters invalid input.
class ParseException implements Exception {
  ParseException(this.message, [this.fragment]);

  final String message;
  final Fragment fragment;

  @override
  String toString() => fragment == null
      ? 'Parsing error: $message'
      : 'Parsing error at fragment '
      '(${fragment.dimensions.top}, ${fragment.dimensions.left})-'
      '(${fragment.dimensions.bottom}x${fragment.dimensions.right}): $message';
}
