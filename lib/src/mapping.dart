import 'dart:collection' show UnmodifiableMapBase;
import 'dart:convert' show LineSplitter;
import 'dart:math';
import 'package:meta/meta.dart';

/// Points upwards in a [MappedString] coordinate system.
const Point<int> up = const Point(0, -1);

/// Points right in a [MappedString] coordinate system.
const Point<int> right = const Point(1, 0);

/// Points downwards in a [MappedString] coordinate system.
const Point<int> down = const Point(0, 1);

/// Points left in a [MappedString] coordinate system.
const Point<int> left = const Point(-1, 0);

/// This class gives efficient access to the characters of a string through
/// their (x, y) coordinates, assuming that every character has a width and
/// height of 1. UTF-16 surrogate pairs are treated as a single character, so
/// they only occupy a single position. The indexing starts with (1, 1) in the
/// top left corner.
///
/// Whitespace characters are not accessible through [operator[]], and the tab
/// character `\t` is not supported.
///
/// The whole string is accessible through [source].
class MappedString extends UnmodifiableMapBase<Point<int>, String> {
  /// Creates a mapped string from [input].
  ///
  /// If [input] is part of another document and you want the (x, y) coordinates
  /// to be absolute coordinates of that parent document, use [lineOffset] and
  /// [columnOffset]. These parameters don't skip over parts of [input], but
  /// only displace the keys for the character mapping and [dimensions].
  factory MappedString(final String input,
      {final int lineOffset: 0, final int columnOffset: 0}) {
    final characters = <Point<int>, String>{};

    var rightmostPosition = columnOffset;
    var line = lineOffset;
    for (final lineString in const LineSplitter().convert(input)) {
      line++;
      var column = columnOffset;
      for (final char
          in lineString.runes.map((rune) => new String.fromCharCode(rune))) {
        column++;
        switch (char) {
          case ' ':
            break;
          case '\t':
            throw new ArgumentError('invalid character `\\t` '
                'in line $line, column $column');
          default:
            characters[new Point(column, line)] = char;
        }
      }
      rightmostPosition = max(rightmostPosition, column);
    }

    return new MappedString._(
        input,
        new Rectangle.fromPoints(new Point(1 + columnOffset, 1 + lineOffset),
            new Point(rightmostPosition, line)),
        characters);
  }

  MappedString._(this.source, this.dimensions, this._characters);

  /// The "1-dimensional" string that is mapped by this object.
  final String source;

  /// The width and height of this string. The leftmost characters in this
  /// string have an x coordinate value of `dimensions.left`, the rightmost
  /// characters an x coordinate value `dimensions.right`, and so forth.
  ///
  /// By default, `dimensions.topLeft` is (1, 1), but can be displaced by the
  /// `lineOffset` and `columnOffset` arguments to the constructor.
  final Rectangle<int> dimensions;

  final Map<Point<int>, String> _characters;

  /// Yields all non-space characters in the specified direction, starting from
  /// [position], exclusive. You can use [up], [right], [down] and [left] as
  /// directions. Stops on the first space character if [breakOnSpace] is
  /// `true`.
  Iterable<MapEntry<Point<int>, String>> neighbours(
      {@required Point<int> position,
      @required final Point<int> direction,
      final bool breakOnSpace: true}) sync* {
    while (dimensions.containsPoint(position += direction)) {
      final char = this[position];
      if (char != null) {
        yield new MapEntry(position, char);
      } else if (breakOnSpace) {
        return;
      }
    }
  }

  @override
  String toString() => source;

  @override
  Iterable<MapEntry<Point<int>, String>> get entries => _characters.entries;
  @override
  bool get isEmpty => _characters.isEmpty;
  @override
  bool get isNotEmpty => _characters.isNotEmpty;
  @override
  Iterable<Point<int>> get keys => _characters.keys;
  @override
  int get length => _characters.length;
  @override
  Iterable<String> get values => _characters.values;

  @override
  bool containsKey(Object key) => _characters.containsKey(key);
  @override
  bool containsValue(Object value) => _characters.containsValue(value);

  @override
  String operator [](Object position) => _characters[position];
}
