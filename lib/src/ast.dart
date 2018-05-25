import 'dart:math';
import 'package:collection/collection.dart';
import 'mapping.dart';
import 'scanner.dart' show Token;

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

/// The container class is a mutable container that stores the individual
/// [Fragment]s that have to be assembled into one connected syntax tree. It
/// serves as a mixin for [Document] and [FencedBlock].
abstract class Container {
  /// All unconnected fragments that have to be assembled into a single syntax
  /// tree.
  Set<Fragment> get rootFragments;
  Set<Fragment> get _rootFragments;

  /// The inside dimensions of this container.
  Rectangle<int> get body;

  /// If this container is [finalized], this property contains the single child
  /// fragment.
  Fragment get expression => _expression;
  Fragment _expression;

  /// Whether [finalize] was called on this container.
  bool get finalized => _expression != null;

  /// Adds [fragment] as a root fragment of this container. If [fragment] has
  /// children, these are removed from [rootFragments], and their
  /// [Fragment.parent] is set to [fragment]. This operation is
  /// irreversible.
  ///
  /// Throws an [AssertionError] if
  /// * [fragment] occupies the same space as another fragment already present
  ///   in this container,
  /// * fragment is alreay part of another syntax tree part,
  /// * `fragment.dimensions` is not contained in [body],
  /// * any child of [fragment] already has a parent, or
  /// * this container is already [finalized].
  void add(Fragment fragment) {
    assert(!finalized);
    assert(body.containsRectangle(fragment.dimensions));
    assert(fragment._container == null);
    fragment._container = this;

    for (final child in fragment.children) {
      assert(child._container == this);
      assert(child._parent == null);
      child._parent = fragment;
      _rootFragments.remove(child);
    }
    if (fragment is FencedBlock) {
      _addFencedBlock(fragment);
    }
    assert(lookupArea(fragment.dimensions).isEmpty);
    _rootFragments.add(fragment);
  }

  /// Extension point for [Document] and [FencedBlock].
  void _addFencedBlock(FencedBlock fragment);

  /// Marks this container as completely processed. It can no longer have
  /// [rootFragments], and its child can now be accessed through [expression].
  void finalize() {
    assert(!finalized);
    if (_rootFragments.isNotEmpty) _expression = _rootFragments.single;
    _rootFragments.clear();
  }

  /// Returns the root fragment that spans the specified point, or `null` if
  /// none exists.
  Fragment lookupPoint(Point<int> point) => _rootFragments.firstWhere(
      (fragment) => fragment.dimensions.containsPoint(point),
      orElse: () => null);

  /// Returns all root fragments that intersect [area].
  Iterable<Fragment> lookupArea(Rectangle<int> area) =>
      _rootFragments.where((fragment) => fragment.dimensions.intersects(area));

  /// Returns all fragment in this container that intersect the rectangle to the
  /// right of `fragment.dimensions`. The result is ordered first by column from
  /// left to right, then by line top to bottom.
  List<Fragment> rightOf(Fragment fragment) => lookupArea(new Rectangle(
          fragment.dimensions.right + 1,
          fragment.dimensions.top,
          body.right - fragment.dimensions.right,
          fragment.dimensions.height))
      .toList(growable: false)
        ..sort((a, b) => a.dimensions.left != b.dimensions.left
            ? a.dimensions.left - b.dimensions.left
            : a.dimensions.top - b.dimensions.top);
}

/// The Document object is the root node of a mathlite syntax tree.
class Document extends Container {
  Document(MappedString source) : this._(source, new Set());
  Document._(this.source, this._rootFragments)
      : rootFragments = new UnmodifiableSetView(_rootFragments);

  /// The string that is being parsed.
  final MappedString source;

  @override
  final Set<Fragment> rootFragments;
  @override
  final Set<Fragment> _rootFragments;

  @override
  Rectangle<int> get body => source.dimensions;

  /// Hands over all fragments that are claimed by [fragment].
  @override
  void _addFencedBlock(FencedBlock fragment) {
    for (final claimed in fragment.rootFragments) {
      assert(claimed._container == this);
      claimed._container = fragment;
    }
    _rootFragments.removeAll(fragment.rootFragments);
  }
}

/// Fragments are the nodes of the mathlite syntax tree.
abstract class Fragment {
  Fragment(this._dimensions);

  Fragment.withChildren();

  /// The container that stores this object.
  Container get container => _container;
  Container _container;

  /// The minimal bounding box over all [children].
  Rectangle<int> get dimensions =>
      _dimensions ??= boundingBox(children.map((child) => child.dimensions));
  Rectangle<int> _dimensions;

  /// The parent fragment of which this object is a child, or `null` if this is
  /// still a root fragment in its [container].
  Fragment get parent => _parent;
  Fragment _parent;

  Fragment get root => parent != null ? parent.root : this;

  /// All child fragments that this object is composed of.
  Iterable<Fragment> get children;
}

/// Represents a section of a [Document] that is surrounded by brackets or
/// absolute value bars.
///
/// The term _fence operator_ is borrowed from the Mozilla MathML documentation.
class FencedBlock extends Fragment with Container {
  /// Creates a fenced block with both left and right bracket.
  FencedBlock(Token leftBracket, Token rightBracket)
      : this._(leftBracket, rightBracket, new Set());
  FencedBlock._(this.leftBracket, this.rightBracket, this._rootFragments)
      : rootFragments = new UnmodifiableSetView(_rootFragments),
        body = leftBracket.dimensions.right + 1 != rightBracket.dimensions.left
            ? new Rectangle.fromPoints(leftBracket.dimensions.topRight + right,
                rightBracket.dimensions.bottomLeft + left)
            : null,
        super.withChildren();

  /// Creates a fenced block with only a left bracket. Used for piecewise
  /// defined functions.
  FencedBlock.withoutRightBracket(Token leftBracket, int width)
      : this._withoutRightBracket(leftBracket, width, new Set());
  FencedBlock._withoutRightBracket(
      this.leftBracket, int width, this._rootFragments)
      : assert(width >= 0),
        rootFragments = new UnmodifiableSetView(_rootFragments),
        rightBracket = null,
        body = new Rectangle.fromPoints(leftBracket.dimensions.topRight + right,
            leftBracket.dimensions.bottomRight + right * (width + 1)),
        super(new Rectangle.fromPoints(leftBracket.dimensions.topLeft,
            leftBracket.dimensions.bottomRight + right * (width + 1)));

  @override
  final Set<Fragment> rootFragments;
  @override
  final Set<Fragment> _rootFragments;

  final Token leftBracket;
  final Token rightBracket;

  @override
  final Rectangle<int> body;

  /// Returns [leftBracket], [rightBracket] and [expression].
  @override
  Iterable<Fragment> get children sync* {
    yield leftBracket;
    if (expression != null) yield expression;
    yield rightBracket;
  }

  /// Sub-containers must not be added to a [FencedBlock] via [add]. [claim]
  /// must be used instead.
  @override
  void _addFencedBlock(FencedBlock fragment) =>
      throw new UnsupportedError('Should never happen');

  /// Marks a [Fragment] in a [Document] to be moved into this container after
  /// this has been added to that document.
  void claim(Fragment fragment) {
    assert(container == null);
    assert(body.containsRectangle(fragment.dimensions));
    _rootFragments.add(fragment);
  }

  @override
  void finalize() {
    assert(container != null);
    super.finalize();
  }
}
