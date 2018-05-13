import 'dart:convert' show LineSplitter;
import 'dart:math';

class Grid {
  factory Grid.mapSource(String input,
      {int lineOffset: 0, int columnOffset: 0}) {
    final lines = const LineSplitter().convert(input);
    final grid = new Grid._();

    var lineNumber = 1 + lineOffset;
    for (final line in lines) {
      var columnNumber = 1 + columnOffset;
      for (final char
          in line.runes.map((rune) => new String.fromCharCode(rune))) {
        if (char != ' ') {
          new Character(grid, columnNumber, lineNumber, char);
        }
        columnNumber++;
      }
      lineNumber++;
    }
    return grid;
  }

  Grid._();

  final Set<Fragment> rootFragments = new Set();

  void _add(Fragment fragment) {
    assert(fragment.grid == this);
    fragment.children.forEach(rootFragments.remove);
    rootFragments.add(fragment);
  }
}

abstract class Fragment {
  Fragment.withChildren(this.grid) {
    for (final child in children) {
      assert(child.parent == null, '$child already has a parent');
      child._parent = this;
      _box = _box == null ? child.box : _box.boundingBox(child.box);
    }

    grid._add(this);
  }

  Fragment._character(this.grid, this._box) {
    grid._add(this);
  }

  final Grid grid;

  Rectangle<int> _box;
  Rectangle<int> get box => _box;

  Fragment _parent;
  Fragment get parent => _parent;

  Fragment get root => parent != null ? parent.root : this;

  Iterable<Fragment> get children => const [];
}

class Character extends Fragment {
  Character(Grid grid, int column, int line, this.character)
      : super._character(grid, new Rectangle(column, line, 0, 0));

  final String character;
}
