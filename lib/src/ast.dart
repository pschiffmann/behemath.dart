import 'dart:math';
import 'package:meta/meta.dart';
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
            bottomRight.y - topLeft.y) {
    assert(children.every(containsRectangle));
  }

  Fragment.fromRectangle(Rectangle<int> box)
      : this(box.topLeft, box.bottomRight);

  /// All meaningful immediate child fragments that this object is composed of.
  /// [Token] members are not included in this iterable.
  Iterable<Fragment> get children;

  /// Part of the [FragmentVisitor] interface. This method should only be called
  /// by a [FragmentVisitor].
  R accept<R>(FragmentVisitor<R> visitor);
}

/// Represents a horizontal sequence of fragments.
///
/// https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mrow
class Row extends Fragment {
  Row(List<Fragment> children)
      : assert(children.length > 1, 'Too few elements to wrap in a row'),
        children = new List.unmodifiable(children),
        super.fromRectangle(boundingBox(children));

  /// The elements of this row, ordered from left to right.
  @override
  final List<Fragment> children;

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitRow(this);
}

///
class Stack extends Fragment {
  Stack(Iterable<Fragment> children)
      : assert(children.length > 1, 'Too few elements to wrap in a row'),
        children = new List.unmodifiable(children),
        super.fromRectangle(boundingBox(children));

  /// The elements of this row, ordered from top to bottom.
  @override
  final List<Fragment> children;

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitStack(this);
}

/// Represents an [`munderover`][1], [`munder`][2] or [`mover`][3] tag.
///
/// [1]: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/munderover
/// [2]: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/munder
/// [3]: https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mover
class UnderOverScript extends Fragment {
  UnderOverScript(this.base, this.underScript, this.overScript)
      : assert(underScript != null || overScript != null),
        super.fromRectangle(boundingBox([base, underScript, overScript]));

  /// The operator or identifier to which the under- or overscripts are
  /// attached.
  final Token base;

  /// The underscript of [base], or `null` if [base] doesn't have an
  /// underscript.
  final Fragment underScript;

  /// The overscript of [base], or `null` if [base] doesn't have an overscript.
  final Fragment overScript;

  /// Returns [underScript], then [overScript], if they are not `null`.
  @override
  Iterable<Fragment> get children sync* {
    if (underScript != null) yield underScript;
    if (overScript != null) yield overScript;
  }

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitUnderOverScript(this);
}

/// Represents a vertically stacked fraction.
///
/// https://developer.mozilla.org/en-US/docs/Web/MathML/Element/mfrac
class Fraction extends Fragment {
  Fraction(this.numerator, this.fractionBar, this.denominator)
      : super.fromRectangle(boundingBox([numerator, fractionBar, denominator]));

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

/// Represents a fragment that is surrounded by brackets or absolute value bars.
///
/// The term _fence operator_ is borrowed from the Mozilla MathML documentation.
class FencedBlock extends Fragment {
  FencedBlock(this.leftBracket, this.body, this.rightBracket)
      : super(leftBracket.topLeft, rightBracket.bottomRight);

  final Token leftBracket;
  final Fragment body;
  final Token rightBracket;

  @override
  Iterable<Fragment> get children sync* {
    yield body;
  }

  @override
  R accept<R>(FragmentVisitor<R> visitor) => visitor.visitFencedBlock(this);
}

/// https://en.wikipedia.org/wiki/Visitor_pattern
abstract class FragmentVisitor<R> {
  @visibleForOverriding
  R visitFencedBlock(FencedBlock fragment);
  @visibleForOverriding
  R visitFraction(Fraction fragment);
  @visibleForOverriding
  R visitRow(Row fragment);
  @visibleForOverriding
  R visitStack(Stack fragment);
  @visibleForOverriding
  R visitToken(Token fragment);
  @visibleForOverriding
  R visitUnderOverScript(UnderOverScript fragment);
}
