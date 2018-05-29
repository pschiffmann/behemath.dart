import 'dart:math';
import 'parser.dart' show Document;
import 'scanner.dart' show Token;
export 'scanner.dart' show Token;

/// Calculates the minimum bounding box that contains all rectangles in
/// [contained].
Rectangle<int> boundingBox(Iterable<Rectangle<int>> contained) {
  var left = contained.first.left;
  var top = contained.first.top;
  var right = contained.first.right;
  var bottom = contained.first.bottom;
  for (final rect in contained.skip(1)) {
    left = min(left, rect.left);
    top = min(top, rect.top);
    right = max(right, rect.right);
    bottom = max(bottom, rect.bottom);
  }
  return new Rectangle(left, top, right - left, bottom - top);
}

/// Fragments are the nodes of the mathlite syntax tree.
abstract class Fragment extends Rectangle<int> {
  Fragment(Point<int> topLeft, Point<int> bottomRight)
      : assert(topLeft.y <= bottomRight.y && topLeft.x <= bottomRight.x),
        super(topLeft.x, topLeft.y, bottomRight.x - topLeft.x,
            bottomRight.y - topLeft.y);

  /// All child fragments that this object is composed of.
  Iterable<Fragment> get children;

  R accept<R>(FragmentVisitor<R> visitor);
}

class Row extends Fragment {
  Row(List<Fragment> children)
      : children = new List.unmodifiable(children),
        super(null, null);

  @override
  final List<Fragment> children;

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitRow(this);
}

class Stack extends Fragment {
  Stack(Iterable<Fragment> children, Point<int> topLeft, Point<int> bottomRight)
      : children = new List.unmodifiable(children),
        super(topLeft, bottomRight);

  @override
  final List<Fragment> children;

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitStack(this);
}

class Fraction extends Fragment {
  Fraction(this.numerator, this.fractionBar, this.denominator,
      Point<int> topLeft, Point<int> bottomRight)
      : super(topLeft, bottomRight);

  final Fragment numerator;
  final Token fractionBar;
  final Fragment denominator;

  @override
  Iterable<Fragment> get children sync* {
    yield numerator;
    yield denominator;
  }

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitFraction(this);
}

/// Represents a section of a [Document] that is surrounded by brackets or
/// absolute value bars.
///
/// The term _fence operator_ is borrowed from the Mozilla MathML documentation.
class FencedBlock extends Fragment {
  FencedBlock(this.leftBracket, this.rightBracket, this.body)
      : super(leftBracket.topLeft, rightBracket.bottomRight);

  final Token leftBracket;
  final Token rightBracket;
  final Fragment body;

  /// Returns [body].
  @override
  Iterable<Fragment> get children sync* {
    yield body;
  }

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitFencedBlock(this);
}

/// https://en.wikipedia.org/wiki/Visitor_pattern
abstract class FragmentVisitor<R> {
  R visitFencedBlock(FencedBlock fragment);
  R visitFraction(Fraction fragment);
  R visitRow(Row fragment);
  R visitStack(Stack fragment);
  R visitToken(Token fragment);
}
