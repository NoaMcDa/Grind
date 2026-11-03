import 'package:flutter/widgets.dart';

/// Caps the system text scale so layouts stay intact while still honouring
/// the user's accessibility setting up to [maxScale].
class TextScaleClamp extends StatelessWidget {
  const TextScaleClamp({super.key, required this.child, this.maxScale = 1.3});

  final Widget child;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: maxScale),
      ),
      child: child,
    );
  }
}
