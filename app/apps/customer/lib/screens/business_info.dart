import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Digits in a 사업자등록번호; the FTC lookup only accepts the full number.
const _registrationDigits = 10;

/// 공정거래위원회 통신판매사업자 정보 조회 for a 사업자등록번호, or null when the number is incomplete.
Uri? ftcLookupUri(String registrationNo) {
  final digits = registrationNo.replaceAll(RegExp(r'\D'), '');
  if (digits.length != _registrationDigits) return null;
  return Uri.https('www.ftc.go.kr', '/bizCommPop.do', {'wrkr_no': digits});
}

Future<void> _launch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// 전자상거래법 제10조 seller details (상호, 대표자, 사업자등록번호, 통신판매업 신고번호, 주소,
/// 고객센터, 호스팅 제공자) from the public `/brand` business profile the console manages.
/// Empty fields are left out; with nothing filled in (or offline) it renders nothing.
class BusinessInfo extends StatefulWidget {
  const BusinessInfo({super.key, required this.api, this.open = _launch});
  final ApiClient api;

  /// Opens the lookup page, dialer or mail app.
  final Future<void> Function(Uri uri) open;

  @override
  State<BusinessInfo> createState() => _BusinessInfoState();
}

class _BusinessInfoState extends State<BusinessInfo> {
  Json? _brand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final brand = await widget.api.get('/brand');
      if (mounted && brand is Json) setState(() => _brand = brand);
    } on Exception {
      // Offline or not set up yet: the footer stays hidden, the screen keeps working.
    }
  }

  static String _s(Object? v) => v is String ? v.trim() : '';

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    if (brand == null) return const SizedBox.shrink();
    final t = context.t;
    final company = brand['company'];
    final c = company is Json ? company : const <String, dynamic>{};
    final regNo = _s(c['registration_no']);
    final phone = _s(brand['support_phone']);
    final email = _s(brand['support_email']);
    final rows = [
      (t.cSetupLegalName, _s(c['legal_name'])),
      (t.cSetupCeo, _s(c['ceo'])),
      (t.cSetupRegNo, regNo),
      (t.cSetupMailOrderNo, _s(c['mail_order_no'])),
      (t.cSetupAddress, _s(c['address'])),
      (t.cSetupSupportHours, _s(brand['support_hours'])),
      (t.cSetupHostingProvider, _s(c['hosting_provider'])),
    ].where((r) => r.$2.isNotEmpty).toList();
    final lookup = ftcLookupUri(regNo);
    final dial = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (rows.isEmpty && dial.isEmpty && email.isEmpty) {
      return const SizedBox.shrink();
    }
    final muted = context.text.bodySmall?.copyWith(
      color: context.colors.inkMuted,
    );
    Widget link(IconData icon, String label, Uri uri) => TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () => widget.open(uri),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.bizInfoTitle, style: context.text.labelMedium),
          const SizedBox(height: Space.xs),
          for (final (label, value) in rows)
            Text('$label  $value', style: muted),
          Wrap(
            spacing: Space.xs,
            children: [
              if (lookup != null)
                link(Icons.open_in_new_rounded, t.bizInfoVerify, lookup),
              if (dial.isNotEmpty)
                link(Icons.call_rounded, phone, Uri(scheme: 'tel', path: dial)),
              if (email.isNotEmpty)
                link(
                  Icons.mail_outline_rounded,
                  email,
                  Uri(scheme: 'mailto', path: email),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
