// Store screenshots for the partner app. Excluded from normal runs (tag `store_screenshots`).
// Generate with `scripts/store/generate.sh`. PNGs land in build/store_shots/raw/partner/<device>/<lang>/.
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/screens/jobs.dart';
import 'package:partner/screens/more.dart';
import 'package:partner/state.dart';
import 'package:test_support/test_support.dart';

import '../support/partner_host.dart';

/// Open direct jobs for today's feed, mixed services, Seoul districts.
List<Json> _jobs() {
  final now = DateTime.now();
  Json job(String id, String code, int price, String district, String? road, int pyeong, {int hour = 9, int ageHours = 1, bool open = true}) => {
        'id': id,
        'number': 'B-20261114-${id.substring(4).padLeft(4, '0')}',
        'service_code': code,
        'answers': null,
        'is_open': open,
        'customer_price': price,
        'created_at': now.subtract(Duration(hours: ageHours)).toUtc().toIso8601String(),
        'district_code': district,
        'road_area': road,
        'size_pyeong': pyeong,
        'visit_date': isoDay(now),
        'start_hour': hour,
        'minutes': 120,
      };
  return [
    job('job-1', 'bathroom', 52000, '11680', '역삼동', 32, hour: 10),
    job('job-2', 'studio', 45000, '11680', '삼성동', 18, hour: 13, ageHours: 5),
    job('job-3', 'sofa', 99000, '11440', '합정동', 24, hour: 15, ageHours: 9, open: false),
    job('job-4', 'mattress', 99000, '11680', '대치동', 20, hour: 17, ageHours: 2),
  ];
}

Json _jobDetail() => {
      'booking': {
        'id': 'job-1',
        'number': 'B-20261114-0042',
        'service_code': 'bathroom',
        'is_quote': false,
        'status': 2,
        'estimate': 52000,
        'size_pyeong': 32,
        'visit_date': isoDay(DateTime.now().add(const Duration(days: 3))),
        'start_hour': 10,
        'minutes': 120,
        'district_code': '11680',
        'road_area': '역삼동',
        'address': {'road_address': '서울특별시 강남구 테헤란로 1', 'detail': '101동 1001호'},
        'visit_notes': <String, dynamic>{'entry': '공동현관 1001# 비밀번호', 'parking': '지하 2층 방문자석'},
        'answers': null,
        'reschedule': null,
        'cancelled': false,
      },
      'committed': true,
      'payout': {'net': 41600, 'fee': 10400},
    };

List<Json> _settlements() => [
      {'service_code': 'studio', 'net': 36000, 'state': 'paid', 'payout_date': '2026-11-05'},
      {'service_code': 'bathroom', 'net': 41600, 'state': 'pending', 'payout_date': null},
      {'service_code': 'sofa', 'net': 79200, 'state': 'waiting_balance', 'payout_date': null},
      {'service_code': 'aircon', 'net': 63200, 'state': 'paid', 'payout_date': '2026-10-29'},
    ];

Future<TestEnv> _env(String lang, ThemeMode mode) {
  final fake = FakeApi()
    ..onGet('/partner/jobs/job-1', (_) => _jobDetail())
    ..reply('GET', '/partner/settlements', _settlements());
  stockPartnerApi(fake, profile: verifiedProfile(name: '김도윤', pendingPayout: 120000), jobs: _jobs());
  return TestEnv.create(fake: fake, role: 'partner', localeCode: lang, themeMode: mode);
}

/// Opens the quote sheet over a host screen as soon as the first frame is up.
class _SheetOver extends StatefulWidget {
  const _SheetOver({required this.child});
  final Widget child;

  @override
  State<_SheetOver> createState() => _SheetOverState();
}

class _SheetOverState extends State<_SheetOver> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showQuoteSheet(context, bookingId: 'bk-7', estimate: 90000);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Shot {
  const _Shot(this.file, {required this.dark, required this.screen});
  final String file;
  final bool dark;
  final Widget Function() screen;
}

final _shots = <_Shot>[
  _Shot('01-jobs', dark: false, screen: () => const Scaffold(body: SafeArea(child: JobsTab()))),
  _Shot('02-job-detail', dark: true, screen: () => const JobDetailScreen(id: 'job-1')),
  _Shot('03-quote', dark: false, screen: () => const _SheetOver(child: Scaffold(body: SafeArea(child: JobsTab())))),
  _Shot('04-earnings', dark: false, screen: () => const SettlementsScreen()),
];

void main() {
  for (final lang in shotLangs) {
    testWidgets('store shots (partner, $lang)', (tester) async {
      await loadShotFonts();
      final envs = {for (final mode in const [ThemeMode.light, ThemeMode.dark]) mode: await _env(lang, mode)};
      final devices = shotDevices.where((d) => shotDeviceSlugs.contains(d.slug));
      for (final device in devices) {
        for (final shot in _shots) {
          final env = envs[shot.dark ? ThemeMode.dark : ThemeMode.light]!;
          final app = PartnerState(env.api, FakeRealtime(env.api));
          await captureShot(
            tester,
            PartnerTestHost(env: env, app: app, home: shot.screen()),
            device,
            '$shotOutRoot/partner/${device.slug}/$lang/${shot.file}.png',
          );
          await unmount(tester);
        }
      }
    });
  }
}
