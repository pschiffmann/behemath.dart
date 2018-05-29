import 'dart:math';

const Point<int> up = const Point(0, -1);
const Point<int> right = const Point(1, 0);
const Point<int> down = const Point(0, 1);
const Point<int> left = const Point(-1, 0);

/// A [Comparator] that sorts [Rectangle]s by their line top to bottom, or by
/// their column from left to right if [l] and [r] are on the same line.
int lineByLineTopToBottom(Rectangle<int> l, Rectangle<int> r) =>
    l.top != r.top ? l.top - r.top : l.left - r.left;

/// A [Comparator] that sorts [Rectangle]s by their column left to right, or by
/// their line from top to bottom if [l] and [r] are on the same line.
int columnByColumnLeftToRight(Rectangle<int> l, Rectangle<int> r) =>
    l.left != r.left ? l.left - r.left : l.top - r.top;
