import 'package:mathlite/mathlite.dart';

final exampleCode = '''
                       n
det (A) =  ∑   sgn(σ)  ∏ a↓{σ(i), i}
         σ∈S↓n        i=1
''';

void main() {
  final grid = new MappedString(exampleCode);
  grid.entries.forEach(print);
}
