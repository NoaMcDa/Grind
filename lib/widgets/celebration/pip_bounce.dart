import 'package:flutter/material.dart';

import '../pip_avatar.dart';

/// A short Pip hop for a finished focus session: scale and lift in a small
/// sequence (about 900 ms), then [onDone]. Ignores pointers and is hidden
/// from semantics, so it never blocks input or repeats the praise line.
class PipBounce extends StatefulWidget {
  const PipBounce({
    super.key,
    this.accessory = PipAccessory.none,
    this.size = 96,
    this.duration = const Duration(milliseconds: 900),
    this.onDone,
  });

  final PipAccessory accessory;
  final double size;
  final Duration duration;
  final VoidCallback? onDone;

  @override
  State<PipBounce> createState() => _PipBounceState();
}

class _PipBounceState extends State<PipBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.5,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.15,
        end: 0.95,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.95,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
  ]);

  static final _lift = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -28.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -28.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -10.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 10,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -10.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 25,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Opacity(
            opacity: _c.value > 0.9 ? (1 - _c.value) / 0.1 : 1,
            child: Transform.translate(
              offset: Offset(0, _lift.evaluate(_c)),
              child: Transform.scale(scale: _scale.evaluate(_c), child: child),
            ),
          ),
          child: PipAvatar(
            size: widget.size,
            cheering: true,
            accessory: widget.accessory,
          ),
        ),
      ),
    );
  }
}
