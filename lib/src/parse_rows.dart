part of 'parser.dart';

void assembleRows(Grid grid, int distance) {
  final it = PrioritizingIterator(grid);
  RowCandidate candidate;
  while (it.moveNext()) {
    if (candidate == null) {
      candidate = new RowCandidate(it.current);
      it.prioritizeColumn(candidate.top, candidate.bottom);
      continue;
    }
    if (candidate.right + 1 < it.current.left) {}
    if (candidate.containsHeight(it.current)) {
      candidate.add(it.current);
      continue;
    }
  }
}

class RowCandidate {
  RowCandidate(Fragment fragment)
      : fragments = [fragment],
        top = fragment.top,
        bottom = fragment.bottom;

  final List<Fragment> fragments;

  int top;
  int bottom;
  int get left => fragments.first.left;
  int get right => fragments.last.right;

  void add(Fragment fragment) {
    assert(fragment.left > fragments.last.right);
    fragments.add(fragment);
    top = min(top, fragment.top);
    bottom = max(bottom, fragment.bottom);
  }

  bool containsHeight(Rectangle<int> area) =>
      top <= area.top && bottom >= area.bottom;
}
