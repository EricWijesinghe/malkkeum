import 'package:core/core.dart';

/// Payout rows as `GET /admin/settlements/payouts` sends them, one per state the payouts tab shows.
Json payoutJson(String id, String state, {String? failure}) => {
  'id': id,
  'pro_id': 'pro-1',
  'pro_name': '김민수 Kim Minsoo',
  'team_name': '민수 청소팀',
  'payout_date': '2026-11-10',
  'amount': 386000,
  'items': const <Json>[],
  'provider': state == 'paid' ? 'toss' : 'manual',
  'state': state,
  'bank': '국민은행',
  'account_last4': '1234',
  'attempts': 1,
  'failure_reason': failure,
  'provider_transfer_id': null,
  'created_at': '2026-11-10T09:00:00Z',
  'paid_at': state == 'paid' ? '2026-11-10T12:00:00Z' : null,
};

final payoutRows = <Json>[
  payoutJson('po-1', 'requested'),
  payoutJson('po-2', 'sent'),
  payoutJson('po-3', 'paid'),
  payoutJson('po-4', 'failed', failure: 'account_closed'),
];

