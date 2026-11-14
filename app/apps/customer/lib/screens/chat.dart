import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'booking_flow.dart';
import 'pay_flow.dart';

part 'chat_bubbles.dart';
part 'chat_room.dart';

const _topics = [
  'studio',
  'kitchen',
  'bathroom',
  'mattress',
  'aircon',
  'sofa',
  'move_out',
  'move_in',
  'other',
];

String topicLabel(T t, String topic) =>
    topic == 'other' ? t.topicOther : t.service(topic);

bool _isQuoteTopic(String topic) => topic == 'move_in' || topic == 'move_out';

bool _isServiceTopic(T t, String topic) => t.service(topic) != topic;

/// Thread title as the design writes it: "이사 청소 상담" for quote threads, "에어컨 청소 문의" otherwise.
String _threadTitle(T t, String topic) => topic == 'other'
    ? t.topicOther
    : !_isServiceTopic(t, topic)
    // A topic the team typed ("쿠폰 사용 문의") is already a title.
    ? topic
    : _isQuoteTopic(topic)
    ? t.chatThreadConsult(t.service(topic))
    : t.chatThreadAsk(t.service(topic));

/// Today: the time; yesterday: "어제"; older: a short date (11.03).
String _threadTime(T t, DateTime at, String lang) {
  final l = at.toLocal();
  final now = DateTime.now();
  final day = DateTime(l.year, l.month, l.day);
  if (day == DateTime(now.year, now.month, now.day)) return timeLabel(l, lang);
  if (day == DateTime(now.year, now.month, now.day - 1)) return t.chatYesterday;
  return lang == 'ko'
      ? DateFormat('MM.dd').format(l)
      : DateFormat.Md(lang).format(l);
}

/// Operating hours from the console's business profile (`/brand`); null when unset or offline.
Future<String?> _supportHours(ApiClient api) async {
  try {
    final brand = await api.get('/brand');
    final hours = brand is Json ? brand['support_hours'] : null;
    return hours is String && hours.trim().isNotEmpty ? hours.trim() : null;
  } on Exception {
    return null;
  }
}

const _priceChanged = 'price_changed';
const _refundPending = 'checkout_refund_pending';

/// Room for the empty-state art under the header; it scrolls inside when text is large.
const _emptyHeight = 360.0;

/// Below this logical width (after text scaling) a header pill collapses to its icon so the title keeps its room.
const _pillMinWidth = 360.0;

bool _roomy(BuildContext context) =>
    MediaQuery.sizeOf(context).width /
        MediaQuery.textScalerOf(context).scale(1) >=
    _pillMinWidth;

String _teamName(BuildContext context, T t) =>
    '${BrandScope.of(context).name} ${t.chatTeam}';

String _buildingLabel(T t, String code) => switch (code) {
  'apartment' => t.building_apartment,
  'villa' => t.building_villa,
  'officetel' => t.building_officetel,
  'house' => t.building_house,
  _ => t.building_other,
};

String _layoutLabel(T t, String code) => switch (code) {
  'studio' => t.layout_studio,
  'one_and_half' => t.layout_one_and_half,
  'two_rooms' => t.layout_two_rooms,
  'three_rooms' => t.layout_three_rooms,
  _ => t.layout_four_plus,
};

/// Tab-root title: large, bold and left-aligned (design p03, p05).
Widget tabRootTitle(BuildContext context, String title) => Text(
  title,
  style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
);

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});
  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  final _view = GlobalKey<AsyncViewState<List<ChatThread>>>();
  StreamSubscription<Json>? _sub;
  late final Future<String?> _hours = _supportHours(context.api);

  /// Bumped once after the first frame: the new-chat glyph gives one nudge when the tab opens.
  int _nudge = 0;

  @override
  void initState() {
    super.initState();
    _sub = context.appRead.realtime
        .on('chat.message')
        .listen((_) => _view.currentState?.reload());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _nudge = 1);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  late final _pager = Pager<ChatThread>(
    context.api,
    '/chat/threads',
    ChatThread.fromJson,
  );

  Future<void> _newChat() async {
    final t = context.t;
    final topic = await showAppSheet<String>(
      context,
      title: t.chatTopicTitle,
      builder: (ctx) => GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.gutter,
        ),
        childAspectRatio: 1.05,
        children: [
          for (final (i, code) in _topics.indexed)
            StaggerIn(
              index: i,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.tile),
                onTap: () => Navigator.of(ctx).pop(code),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    code == 'other'
                        ? const CircleAvatar(
                            radius: 26,
                            child: Icon(Icons.more_horiz_rounded),
                          )
                        : ServiceGlyph(code, size: 52),
                    const SizedBox(height: 6),
                    Text(
                      code == 'other' ? t.topicOther : t.serviceShort(code),
                      style: ctx.text.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (topic != null && mounted) {
      await openTopicChat(context, topic);
      await _view.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: context.colors.surface,
        title: tabRootTitle(context, t.chatTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: Space.md),
            // Small phones and large text: the glyph alone, so the title keeps its room.
            child: _roomy(context)
                ? OutlinedButton.icon(
                    onPressed: _newChat,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: context.colors.line),
                      foregroundColor: context.colors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    ),
                    icon: Icon3D('chat_new', size: 20, attention: _nudge),
                    label: Text(t.chatNew),
                  )
                : IconButton(
                    tooltip: t.chatNew,
                    onPressed: _newChat,
                    icon: Icon3D('chat_new', size: 24, attention: _nudge),
                  ),
          ),
        ],
      ),
      body: AsyncView<List<ChatThread>>(
        key: _view,
        load: _pager.first,
        // The header scrolls with the threads so large text never overflows a short screen.
        builder: (context, _, reload) => LoadMore<ChatThread>(
          pager: _pager,
          builder: (context, threads) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [
                FutureBuilder<String?>(
                  future: _hours,
                  builder: (context, snap) =>
                      _HoursBar(hours: snap.data ?? t.chatHours),
                ),
                if (threads.isEmpty)
                  SizedBox(
                    height: _emptyHeight,
                    child: EmptyState(
                      icon: Icons.forum_rounded,
                      title: t.chatEmpty,
                      body: t.chatReplyFast,
                      hue: ServiceHues.aircon,
                    ),
                  ),
                for (final (i, th) in threads.indexed)
                  StaggerIn(
                    key: ValueKey(th.id),
                    index: i,
                    child: Column(
                      children: [
                        _ThreadTile(thread: th, onReturn: reload),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One grey bar: operating hours and the usual reply time (design p03).
class _HoursBar extends StatelessWidget {
  const _HoursBar({required this.hours});
  final String hours;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.md,
        Space.xxs,
        Space.md,
        Space.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.schedule_rounded, size: 16, color: c.accent),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${t.chatHoursTitle} · $hours',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · ${t.chatReplyFast}'),
                ],
              ),
              style: context.text.bodySmall?.copyWith(color: c.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onReturn});
  final ChatThread thread;
  final Future<void> Function() onReturn;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final last = thread.lastMessage;
    final preview = switch (last?['kind']) {
      'text' => (last!['body'] as Json)['text'] as String? ?? '',
      'photo' => t.chatPhoto,
      'quote' => t.quoteArrived,
      'card' => t.requestCard,
      'system' => t.system(
        (last!['body'] as Json)['code'] as String? ?? '',
        ((last['body'] as Json)['params'] as Json?) ?? const {},
        context.lang,
      ),
      _ => '',
    };
    final unread = thread.unreadMember;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: 6,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: c.primaryTint,
        child: !_isServiceTopic(t, thread.topic)
            ? Icon(Icons.chat_bubble_outline_rounded, color: c.inkSoft)
            : ServiceGlyph(thread.topic, size: 30),
      ),
      title: Text(
        _threadTitle(t, thread.topic),
        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(color: c.inkSoft),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _threadTime(t, thread.lastMessageAt, context.lang),
            style: context.text.labelSmall?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: 4),
          if (unread > 0)
            // A new count pops in once: keyed so a rising count replays it.
            TweenAnimationBuilder<double>(
              key: ValueKey(unread),
              tween: Tween(begin: 0, end: 1),
              duration: motionFor(context, Motion.iconPop),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Badge(label: Text('$unread')),
            ),
        ],
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatRoomScreen(
              threadId: thread.id,
              topic: thread.topic,
              bookingId: thread.bookingId,
            ),
          ),
        );
        await onReturn();
      },
    );
  }
}
