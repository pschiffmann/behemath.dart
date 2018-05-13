import 'package:mathlite/mathlite.dart';

final exampleCode = '''
                       n
det (A) =  ∑   sgn(σ)  ∏ a↓{σ(i), i}
         σ∈S↓n        i=1
''';

void main() {
  final grid = new Grid.mapSource(exampleCode);
  for (final char in grid.rootFragments.retype<Character>()) {
    print(
        '${char.character} (length: ${char.character.length}) at ${char.box}');
  }
}
