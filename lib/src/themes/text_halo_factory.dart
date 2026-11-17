import 'dart:math';
import 'dart:ui';

import 'expression/caching_expression.dart';
import 'expression/expression.dart';

class TextHaloFactory {
  static Expression<List<Shadow>>? toHaloFunction(
      Expression<Color> colorExpression, Expression<double>? haloWidth) {
    return cache(TextHaloExpression(colorExpression, haloWidth));
  }
}

class TextHaloExpression extends Expression<List<Shadow>> {
  final Expression<Color> colorExpression;
  final Expression<double>? haloWidth;

  TextHaloExpression(this.colorExpression, this.haloWidth)
      : super('textHalo(${colorExpression.cacheKey},${haloWidth?.cacheKey})', {
          ...colorExpression.properties(),
          ...(haloWidth?.properties() ?? {}),
          'zoom'
        });

  @override
  List<Shadow>? evaluate(EvaluationContext context) {
    final color = colorExpression.evaluate(context);
    if (color == null) {
      return null;
    }
    final width = haloWidth?.evaluate(context);
    if (width == null) {
      return null;
    }
    double factor = max(1.0, context.zoomScaleFactor);
    double offset = width / factor;
    // A halo is a ring around the glyph. Four blurred shadows (the previous
    // approach) detach from the glyph at high device pixel ratios and read as a
    // duplicated, shadowed label. Zero-blur copies keep the ring tight.
    const steps = 12;
    return [
      for (var i = 0; i < steps; i++)
        Shadow(
          offset: Offset(
            offset * cos(2 * pi * i / steps),
            offset * sin(2 * pi * i / steps),
          ),
          blurRadius: 0,
          color: color,
        ),
    ];
  }

  @override
  bool get isConstant => false;
}
