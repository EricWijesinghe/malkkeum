import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'state.dart';

/// Public offer terms from `GET /public/offers`: owner settings only, the same for every visitor.
class PublicOffers {
  const PublicOffers({
    required this.welcomeOn,
    required this.welcomePercent,
    required this.welcomeValue,
    required this.referralOn,
    required this.referralAmount,
    required this.couponDays,
  });

  factory PublicOffers.fromJson(Json j) {
    final welcome = j['welcome'] as Json;
    final referral = j['referral'] as Json;
    return PublicOffers(
      welcomeOn: welcome['enabled'] == true,
      welcomePercent: welcome['kind'] == 'percent',
      welcomeValue: (welcome['value'] as num).toInt(),
      referralOn: referral['enabled'] == true,
      referralAmount: (referral['amount'] as num).toInt(),
      couponDays: (j['coupon_days'] as num).toInt(),
    );
  }

  final bool welcomeOn;
  final bool welcomePercent;
  final int welcomeValue;
  final bool referralOn;
  final int referralAmount;
  final int couponDays;

  /// Null when the terms cannot be read: every line then stays hidden.
  static Future<PublicOffers?> load(ApiClient api) async {
    try {
      return PublicOffers.fromJson(await api.get('/public/offers') as Json);
    } on Object {
      // Decoration only: without the terms the offer lines simply do not show.
      return null;
    }
  }
}

/// Loads [PublicOffers] once for its subtree and hands the result (null while loading or on failure) to [builder].
class PublicOffersBuilder extends StatefulWidget {
  const PublicOffersBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, PublicOffers? offers) builder;

  @override
  State<PublicOffersBuilder> createState() => _PublicOffersBuilderState();
}

class _PublicOffersBuilderState extends State<PublicOffersBuilder> {
  PublicOffers? _offers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final offers = await PublicOffers.load(context.api);
    if (mounted) setState(() => _offers = offers);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _offers);
}

/// Welcome offer with its conditions, for guests only. Hidden while the offer is off.
class WelcomeOfferLine extends StatelessWidget {
  const WelcomeOfferLine({super.key});

  @override
  Widget build(BuildContext context) => PublicOffersBuilder(
    builder: (context, offers) {
      if (offers == null || !offers.welcomeOn) return const SizedBox.shrink();
      final value = offers.welcomePercent
          ? '${offers.welcomeValue}%'
          : context.won(offers.welcomeValue);
      return Padding(
        padding: const EdgeInsets.only(top: Space.xs),
        child: Text(
          context.t.welcomeOfferLine(value, '${offers.couponDays}'),
          style: context.text.bodySmall?.copyWith(color: context.primary),
        ),
      );
    },
  );
}
