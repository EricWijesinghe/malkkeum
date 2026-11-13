part of 'booking_detail.dart';

class _Timeline extends StatelessWidget {
  const _Timeline({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final b = booking;
    final steps = [
      if (b.isQuote) (0, null),
      (1, null),
      (2, b.teamName == null ? null : t.teamVisiting(b.teamName!)),
      (3, b.status < 3 ? t.photosSoon : null),
    ];
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            EnterMotion(
              delay: Duration(milliseconds: 80 * i),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        _Dot(
                          step: steps[i].$1,
                          done: b.status >= steps[i].$1,
                          current: b.status == steps[i].$1,
                        ),
                        if (i < steps.length - 1)
                          // The connector fills once its step is behind the booking.
                          Expanded(
                            // A one-line step is shorter than its disc: the floor keeps the
                            // discs (and the current one's pulse) apart with a visible line.
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: Space.md,
                              ),
                              child: ProgressLine(
                                axis: Axis.vertical,
                                thickness: 2,
                                fraction: b.status > steps[i].$1 ? 1 : 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookingStepLabel(t, steps[i].$1),
                              style: context.text.titleSmall?.copyWith(
                                color: b.status >= steps[i].$1
                                    ? context.colors.ink
                                    : context.colors.inkMuted,
                              ),
                            ),
                            if (steps[i].$2 != null)
                              Text(steps[i].$2!, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.step, required this.done, required this.current});
  final int step;
  final bool done;
  final bool current;
  static const _size = 40.0;

  @override
  Widget build(BuildContext context) => Pulse(
    active: current,
    child: AnimatedContainer(
      duration: motionFor(context, Motion.standard),
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? context.colors.freshTint : context.colors.surfaceHigh,
        border: Border.all(
          color: current ? context.colors.fresh : context.colors.line,
          width: 2,
        ),
      ),
      // The step name sits next to it, so the art itself is decorative.
      child: ExcludeSemantics(
        child: Icon3D(
          bookingStepIcon(step),
          active: current,
          enabled: done,
          size: 24,
        ),
      ),
    ),
  );
}

class _Photos extends StatelessWidget {
  const _Photos({required this.before, required this.after});
  final List<String> before;
  final List<String> after;

  @override
  Widget build(BuildContext context) {
    Widget strip(String label, List<String> urls) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelMedium),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(
                      urls[i],
                      cacheWidth: 1440,
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(Space.xl),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              child: Semantics(
                button: true,
                image: true,
                label: context.t.photoThumb('${i + 1}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Decode at 2x the 96dp thumbnail: smaller cache entries, sharp on 3x screens.
                  child: Image.network(
                    urls[i],
                    width: 96,
                    height: 96,
                    cacheWidth: 192,
                    cacheHeight: 192,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(width: 96, color: context.colors.line),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (before.isNotEmpty) strip(context.t.before, before),
          if (before.isNotEmpty && after.isNotEmpty)
            const SizedBox(height: Space.md),
          if (after.isNotEmpty) strip(context.t.after, after),
        ],
      ),
    );
  }
}

class _ReviewPrompt extends StatelessWidget {
  const _ReviewPrompt({required this.bookingId, required this.onSaved});
  final String bookingId;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.sunTint,
    onTap: () async {
      final saved = await showReviewSheet(context, bookingId);
      if (saved == true) onSaved();
    },
    child: Row(
      children: [
        Icon(Icons.star_rounded, color: context.colors.sun),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(context.t.reviewTitle, style: context.text.titleSmall),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}
