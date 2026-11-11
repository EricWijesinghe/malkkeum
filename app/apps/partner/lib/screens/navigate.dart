import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A map app: its own URL scheme, and a web page for when the app is not installed.
class NavOption {
  const NavOption(this.name, this.app, this.web);
  final String name;
  final Uri app;
  final Uri web;
}

/// Kakao, Naver and T map search links for a visit address. Only the address leaves the app.
List<NavOption> navOptions(String address) {
  final q = Uri.encodeComponent(address);
  return [
    NavOption('Kakao Map', Uri.parse('kakaomap://search?q=$q'), Uri.parse('https://map.kakao.com/?q=$q')),
    NavOption(
      'Naver Map',
      Uri.parse('nmap://search?query=$q&appname=com.malkkeum.partner'),
      Uri.parse('https://map.naver.com/v5/search/$q'),
    ),
    // T map has no public web search page, so its web fallback is Google Maps.
    NavOption('T map', Uri.parse('tmap://search?name=$q'), Uri.parse('https://www.google.com/maps/search/?api=1&query=$q')),
  ];
}

/// Opens the map app, or its web page when the app does not answer.
Future<void> openNavOption(NavOption o) async {
  final opened = await launchUrl(o.app, mode: LaunchMode.externalApplication);
  if (!opened) await launchUrl(o.web, mode: LaunchMode.externalApplication);
}

Future<void> showNavigateSheet(BuildContext context, String address) => showAppSheet<void>(
  context,
  title: context.t.pNavigate,
  builder: (ctx) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
        child: Text(ctx.t.pNavHint, style: ctx.text.bodyMedium),
      ),
      for (final o in navOptions(address))
        ListTile(
          leading: const Icon(Icons.map_rounded),
          title: Text(o.name),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () {
            Navigator.of(ctx).pop();
            _open(context, o);
          },
        ),
    ],
  ),
);

Future<void> _open(BuildContext context, NavOption o) async {
  try {
    await openNavOption(o);
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}
