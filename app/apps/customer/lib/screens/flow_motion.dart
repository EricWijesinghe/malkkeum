import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Motion used only by the booking flows (owner design p07-p22). Transform and paint
/// only, one beat each (no loops), and nothing moves under reduced motion.

/// Runs 0 -> 1 once whenever [trigger] changes while [active], and once on mount when
/// [onMount]. [delay] is part of the controller's run, so no timer outlives the widget.
/// Builders must draw the resting state at both 0 and 1.
class OneShot extends StatefulWidget {
  const OneShot({
    super.key,
    required this.builder,
    this.trigger,
    this.active = true,
    this.onMount = false,
    this.delay = Duration.zero,
    this.duration = Motion.iconPop,
    this.child,
  });
  final Object? trigger;
  final bool active;
  final bool onMount;
  final Duration delay;
  final Duration duration;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  @override
  State<OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  bool _started = false;

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _c.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.onMount) _play();
  }

  @override
  void didUpdateWidget(OneShot old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.active) _play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _c.duration!.inMicroseconds;
    final start = total == 0 ? 0.0 : widget.delay.inMicroseconds / total;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => widget.builder(
        context,
        _c.value <= start ? 0 : (_c.value - start) / (1 - start),
        child,
      ),
    );
  }
}

const _kickScale = 0.08;
const _nudgeDp = 4.0;
const _ringGrow = 0.24;
const _ringAlpha = 0.45;

/// One soft scale kick (badges, counters, a CTA asking for attention).
Widget kick(BuildContext context, double t, Widget? child) => Transform.scale(
  scale: 1 + _kickScale * math.sin(math.pi * t),
  child: child,
);

/// One 4dp sideways nudge: "this still needs an answer".
Widget nudge(BuildContext context, double t, Widget? child) =>
    Transform.translate(
      offset: Offset(-_nudgeDp * math.sin(math.pi * t), 0),
      child: child,
    );

/// One ring that grows out of a round [child] of [size] and fades (selection ripple).
Widget ringRipple(double t, double size, Color color, Widget child) => Stack(
  alignment: Alignment.center,
  clipBehavior: Clip.none,
  children: [
    // First and always: the child keeps its slot (and its state) while the ring comes and goes.
    child,
    if (t > 0 && t < 1)
      IgnorePointer(
        child: Transform.scale(
          scale: 1 + _ringGrow * Motion.emphasized.transform(t),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: _ringAlpha * (1 - t)),
                width: 3,
              ),
            ),
          ),
        ),
      ),
  ],
);

/// A number that counts up from zero when it first appears (fact card, paid amount).
class CountIn extends StatelessWidget {
  const CountIn({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });
  final int value;
  final String Function(int) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: motionFor(context, Motion.celebrate),
    curve: Motion.emphasized,
    // The final text is what screen readers get, not the frames in between.
    builder: (_, v, _) =>
        Text(format(v.round()), style: style, semanticsLabel: format(value)),
  );
}

/// The step chip's label rolls up into place when its page comes in.
class RollIn extends StatelessWidget {
  const RollIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: motionFor(context, Motion.route),
      curve: Motion.emphasized,
      child: child,
      builder: (_, dy, child) =>
          FractionalTranslation(translation: Offset(0, dy), child: child),
    ),
  );
}

/// Scales a selection mark in with a small overshoot (check badges, radio dots).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.show, required this.child});
  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: show ? 1 : 0,
    duration: motionFor(context, Motion.standard),
    curve: show ? Curves.easeOutBack : Motion.ease,
    child: child,
  );
}
