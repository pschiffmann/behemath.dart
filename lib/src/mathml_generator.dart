import 'ast.dart';

/// Generates a String in MathML syntax that corresponds to the assigned
/// fragment tree.
String generateMathml(final Fragment fragment) {
  final generator = new _MathmlGenerator();
  fragment.accept(generator);
  return generator.result.toString();
}

class _MathmlGenerator extends FragmentVisitor<void> {
  final StringBuffer result = new StringBuffer();

  @override
  void visitFencedBlock(final FencedBlock fragment) =>
      throw new UnimplementedError();

  @override
  void visitFraction(final Fraction fragment) => throw new UnimplementedError();

  @override
  void visitRow(final Row fragment) {
    result.write('<mrow>');
    for (final child in fragment.children) {
      child.accept(this);
    }
    result.write('</mrow>');
  }

  @override
  void visitStack(final Stack fragment) => throw new UnimplementedError();

  @override
  void visitSubSuperScript(final SubSuperScript fragment) =>
      throw new UnimplementedError();

  @override
  void visitToken(final Token fragment) {
    result.write(fragment.lexeme);
  }

  @override
  void visitUnderOverScript(final UnderOverScript fragment) =>
      throw new UnimplementedError();
}
