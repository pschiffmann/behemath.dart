import 'dart:math';
import 'package:mathlite/mathlite.dart';
import 'package:mathlite/src/mathml_generator.dart';

///  n
///  ∏ a↓{σ(i), i}
/// i=1
final Fragment equation = new Row([
  new UnderOverScript(
      new Token('prefixOperator', '∏', const Point(2, 2), const Point(2, 2)),
      new Row([
        new Token('identifier', 'i', const Point(1, 3), const Point(1, 3)),
        new Token('infixOperator', '=', const Point(2, 3), const Point(2, 3)),
        new Token('number', '1', const Point(3, 3), const Point(3, 3))
      ]),
      new Token('identifier', 'n', const Point(2, 1), const Point(2, 1))),
  new Token('identifier', 'a', const Point(4, 2), const Point(4, 2)),
  new Token('infixOperator', '↓', const Point(5, 2), const Point(5, 2)),
  new FencedBlock(
      new Token('{', '{', const Point(6, 2), const Point(6, 2)),
      new Row([
        new Token('identifier', 'σ', const Point(7, 2), const Point(7, 2)),
        new FencedBlock(
            new Token('(', '(', const Point(8, 2), const Point(8, 2)),
            new Token('identifier', 'i', const Point(9, 2), const Point(9, 2)),
            new Token(')', ')', const Point(10, 2), const Point(10, 2))),
        new Token('infixOperator', ',', const Point(11, 2), const Point(11, 2)),
        new Token('identifier', 'i', const Point(13, 2), const Point(13, 2))
      ]),
      new Token('}', '}', const Point(14, 2), const Point(14, 2)))
]);

void main() {
  print(generateMathml(equation));
}
