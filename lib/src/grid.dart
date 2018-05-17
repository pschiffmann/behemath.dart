import 'dart:math';
import 'package:collection/collection.dart';
import 'mapping.dart';

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

/// The grid class is a mutable container that stores the individual [Fragment]s
/// that have to be assembled into one connected syntax tree.
class Grid {
  Grid(this.source);

  /// The string that is being parsed in this grid.
  final MappedString source;

  final Set<Fragment> _rootFragments = new Set();
  Set<Fragment> get rootFragments => new UnmodifiableSetView(_rootFragments);

  /// Adds [fragment] as a root fragment of this grid, and `this` as its
  /// [Fragment.grid]. If [fragment] has children, these are removed from
  /// [rootFragments]. This operation is irreversible.
  void add(Fragment fragment) {
    assert(fragment._grid == null);
    fragment._grid = this;
    for (final child in fragment.children) {
      assert(child._parent == null);
      assert(child._grid == this);
      child._parent = fragment;
      _rootFragments.remove(child);
    }
    assert(lookupArea(fragment.dimensions).isEmpty);
    _rootFragments.add(fragment);
  }

  /// Returns the root fragment that spans the specified point, or `null` if
  /// none exists.
  Fragment lookupPoint(Point<int> point) => _rootFragments.firstWhere(
      (fragment) => fragment.dimensions.containsPoint(point),
      orElse: () => null);

  /// Returns all root fragments that intersect [area].
  Iterable<Fragment> lookupArea(Rectangle<int> area) =>
      _rootFragments.where((fragment) => fragment.dimensions.intersects(area));
}

/// Fragments are the nodes of the mathlite syntax tree.
abstract class Fragment {
  Fragment(this._dimensions);

  Fragment.withChildren();

  Grid _grid;
  Grid get grid => _grid;

  Rectangle<int> _dimensions;
  Rectangle<int> get dimensions =>
      _dimensions ??= boundingBox(children.map((child) => child.dimensions));

  Fragment _parent;
  Fragment get parent => _parent;

  Fragment get root => parent != null ? parent.root : this;

  Iterable<Fragment> get children => const [];
}
