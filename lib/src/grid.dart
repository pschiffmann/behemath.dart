import 'dart:collection';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'directions.dart';

/// A grid allows efficient lookup of it elements by area through the methods
/// [lookupPoint], [lookupArea] and [lookupSorted]. All elements of a grid must
/// be contained in [dimensions], and elements must not overlap.
///
/// This class should be implemented as a Quadtree, or maybe as a spatial hash.
/// Right now it just wraps a [Set].
/// http://zufallsgenerator.github.io/2014/01/26/visually-comparing-algorithms/
class Grid<E extends Rectangle<int>> extends IterableBase<E> {
  Grid(this.dimensions);

  /// Elements can only be added to this grid if they are contained within this
  /// area.
  final Rectangle<int> dimensions;

  final Set<E> _elements = new Set();

  @override
  E get first => _elements.first;
  @override
  bool get isEmpty => _elements.isEmpty;
  @override
  bool get isNotEmpty => _elements.isNotEmpty;
  @override
  Iterator<E> get iterator => _elements.iterator;
  @override
  E get last => _elements.last;
  @override
  int get length => _elements.length;
  @override
  E get single => _elements.single;

  /// Adds [rect] to this grid. Throws an [AssertionError] if [rect] is not
  /// contained within [dimensions], or this grid already contains an element
  /// that overlaps with [rect].
  void add(E rect) {
    assert(dimensions.containsRectangle(rect));
    assert(lookupArea(rect).isEmpty);
    _elements.add(rect);
  }

  /// Removes [rect] from the grid. Throws an [AssertionError] if [rect] was not
  /// in this grid.
  void remove(E rect) {
    final removed = _elements.remove(rect);
    assert(removed);
  }

  /// Returns the fragment that spans the specified point, or `null` if none
  /// exists.
  E lookupPoint(Point<int> point) => _elements
      .firstWhere((rect) => rect.containsPoint(point), orElse: () => null);

  /// Returns all fragments that intersect [area].
  Iterable<E> lookupArea(Rectangle<int> area) =>
      _elements.where((rect) => rect.intersects(area));

  List<E> lookupSorted(Rectangle<int> area, Comparator<E> order) =>
      lookupArea(area).toList(growable: false)..sort(order);

  /// Returns all fragment in this container that intersect the rectangle to the
  /// right of `rect`. The result is ordered first by column from left to right,
  /// then by line top to bottom.
  List<E> rightOf(Rectangle<int> rect) => lookupSorted(
      new Rectangle(
          rect.right + 1, rect.top, dimensions.right - rect.right, rect.height),
      columnByColumnLeftToRight);
}

/// This class provides a mutable view of a subsection of a [Grid].
class GridSection<E extends Rectangle<int>> extends IterableBase<E>
    implements Grid<E> {
  GridSection(Grid base, this.dimensions)
      : assert(base.dimensions.containsRectangle(dimensions)),
        base = base is GridSection ? base.base : base;

  /// The object this is a view of.
  final Grid base;

  /// The elements of [base] that are also in `this`.
  Iterable<E> get _rectangles => base.lookupArea(dimensions);
  @override
  @alwaysThrows
  Set<E> get _elements =>
      throw new UnsupportedError('Not available for GridSection');

  @override
  final Rectangle<int> dimensions;

  @override
  E get first => _rectangles.first;
  @override
  bool get isEmpty => _rectangles.isEmpty;
  @override
  bool get isNotEmpty => _rectangles.isNotEmpty;
  @override
  Iterator<E> get iterator => _rectangles.iterator;
  @override
  E get last => _rectangles.last;
  @override
  int get length => _rectangles.length;
  @override
  E get single => _rectangles.single;

  /// Adds [rect] to [base]. Throws an [AssertionError] if [rect] is not
  /// contained within [dimensions], or [base] already contains an element that
  /// overlaps with [rect].
  @override
  void add(E rect) {
    assert(dimensions.containsRectangle(rect));
    base.add(rect);
  }

  /// Removes [rect] from the grid. Throws an [AssertionError] if [rect] was not
  /// in this grid.
  @override
  void remove(E rect) {
    assert(lookupArea(rect).single == rect);
    base.remove(rect);
  }

  /// Returns the fragment that spans the specified point, or `null` if none
  /// exists.
  @override
  E lookupPoint(Point<int> point) => _rectangles
      .firstWhere((rect) => rect.containsPoint(point), orElse: () => null);

  /// Returns all fragments that intersect [area].
  @override
  Iterable<E> lookupArea(Rectangle<int> area, [Comparator<E> order]) =>
      _rectangles.where((rect) => rect.intersects(area));

  @override
  List<E> lookupSorted(Rectangle<int> area, Comparator<E> order) =>
      lookupArea(area).toList(growable: false)..sort(order);

  /// Returns all fragment in this container that intersect the rectangle to the
  /// right of `rect`. The result is ordered first by column from left to right,
  /// then by line top to bottom.
  @override
  List<E> rightOf(Rectangle<int> rect) => lookupArea(
      new Rectangle(
          rect.right + 1, rect.top, dimensions.right - rect.right, rect.height),
      columnByColumnLeftToRight);
}

/// This iterator can be used to iterate over a [Grid] column by column from
/// left to right. The method [prioritizeColumn] can be used to visit a specific
/// area first, and [undoPrioritization] reverts a previous [prioritizeColumn]
/// call.
///
/// The iterator is not affected by changes made to the grid.
class PrioritizingIterator<E extends Rectangle<int>> implements Iterator<E> {
  PrioritizingIterator(Iterable<E> elements)
      : _elements = elements.toList(growable: false)
          ..sort(columnByColumnLeftToRight);

  final List<E> _elements;
  int _index = -1;

  @override
  E get current =>
      _index != -1 && _index != _elements.length ? _elements[_index] : null;

  @override
  bool moveNext() {
    if (_index < _elements.length) _index++;
    return _index < _elements.length;
  }

  /// Reorders all unvisited elements of this iterator so that elements with
  /// [Rectangle.top] inside the range [top, bottom] are visited before elements
  /// with a `top` outside that range. Both groups are internally ordered by
  /// [columnByColumnLeftToRight].
  void prioritizeColumn(int top, int bottom) {
    if (_index >= _elements.length - 1) return;
    mergeSort<E>(_elements, start: _index + 1, compare: (l, r) {
      final lInColumn = top <= l.top && l.top <= bottom;
      final rInColumn = top <= r.top && r.top <= bottom;
      if (lInColumn && !rInColumn) return -1;
      if (!lInColumn && rInColumn) return 1;
      return columnByColumnLeftToRight(l, r);
    });
  }

  /// Restores the default order for all unvisited elements. [current] is not
  /// changed.
  void undoPrioritization() {
    if (_index >= _elements.length - 1) return;
    mergeSort<E>(_elements,
        start: _index + 1, compare: columnByColumnLeftToRight);
  }
}
