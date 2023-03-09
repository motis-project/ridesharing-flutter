import 'package:flutter/material.dart';

class FadeOut extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final String? tooltip;
  final Widget? indicator;
  final Alignment indicatorAlignment;
  const FadeOut({
    super.key,
    required this.child,
    this.onTap,
    this.label,
    this.tooltip,
    this.indicator,
    this.indicatorAlignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    Widget fadeOut = ExcludeSemantics(
      child: ShaderMask(
        shaderCallback: (Rect rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.black, Colors.transparent],
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
        blendMode: BlendMode.dstIn,
        child: child,
      ),
    );
    if (onTap != null || indicator != null) {
      fadeOut = Stack(
        children: <Widget>[
          fadeOut,
          if (indicator != null)
            Positioned.fill(
              child: Align(
                alignment: indicatorAlignment,
                child: ExcludeSemantics(child: indicator),
              ),
            ),
          if (onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
        ],
      );
    }
    if (onTap != null) {
      fadeOut = Semantics(
        label: label,
        button: true,
        tooltip: tooltip,
        child: fadeOut,
      );
    }
    return fadeOut;
  }
}
