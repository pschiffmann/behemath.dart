import 'package:mathlite/mathlite.dart';
import 'package:mathlite/token_types.dart' as token_type;

final exampleCode = '''
                       n
det (A) =  ∑   sgn(σ)  ∏ a↓{σ(i), i}
         σ∈S↓n        i=1
''';

void main() {
  final document = scan(
      new MappedString(exampleCode),
      defaultPatterns +
          [
            const TokenPattern('det', token_type.identifier),
            const TokenPattern('sgn', token_type.identifier),
            const TokenPattern('S', token_type.identifier),
            const TokenPattern('σ', token_type.identifier),
            const TokenPattern('A', token_type.identifier),
            const TokenPattern('a', token_type.identifier),
            const TokenPattern('i', token_type.identifier),
            const TokenPattern('n', token_type.identifier),
            const TokenPattern('1', token_type.number),
          ]);
  assemble(document);
}
