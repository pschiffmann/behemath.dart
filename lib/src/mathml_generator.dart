import 'ast.dart';

String generateMathml(Fragment fragment) {
  final generator = new _MathmlGenerator();
  fragment.accept(generator);
  return generator.result.toString();
}

class _MathmlGenerator extends FragmentVisitor<void> {
  final StringBuffer result = new StringBuffer();

  @override
  void visitFencedBlock(FencedBlock fragment) => throw new UnimplementedError();

  @override
  void visitFraction(Fraction fragment) => throw new UnimplementedError();

  @override
  void visitRow(Row fragment) => throw new UnimplementedError();

  @override
  void visitStack(Stack fragment) => throw new UnimplementedError();

  @override
  void visitToken(Token fragment) {
    result.write(fragment.lexeme);
  }
}
