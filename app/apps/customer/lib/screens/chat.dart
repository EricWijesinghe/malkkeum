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

/// Thread title as the design writes it: "이사 청소 상담" for quote threads, "에어컨 청소 문의" otherwise.
String _threadTitle(T t, String topic) => topic == 'other'
    ? t.topicOther
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

/// Room for the empty-state art under the header; it scrolls inside when text is large.
const _emptyHeight = 360.0;

/// Below this logical width (after text scaling) a header pill collapses to its icon so the title keeps its room.
const _pillMinWidth = 360.0;

bool _roomy(BuildContext context) =>
    MediaQuery.sizeOf(context).width /
        MediaQuery.textScalerOf(context).scale(1) >=
    _pillMinWidth;

String _teamName(T t) => '${BrandConfig.placeholder.name} ${t.chatTeam}';

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

  Future<List<ChatThread>> _load() async =>
      (await context.api.get('/chat/threads') as List)
          .map((e) => ChatThread.fromJson(e as Json))
          .toList();

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
        load: _load,
        // The header scrolls with the threads so large text never overflows a short screen.
        builder: (context, threads, reload) => RefreshIndicator(
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
        child: thread.topic == 'other'
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

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.threadId,
    required this.topic,
    this.bookingId,
  });
  final String threadId;
  final String topic;
  final String? bookingId;
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  StreamSubscription<Json>? _sub;
  bool _sending = false;
  bool _loading = true;
  bool _paying = false;

  /// Set when this screen's own payment succeeded, before the `deposit_paid` message arrives.
  bool _paidHere = false;
  late final Future<String?> _hours = _supportHours(context.api);

  /// Messages that arrived while the room is open (live, not history): only these animate in.
  final _arrivedAt = <String, DateTime>{};

  bool get _isQuoteThread => _isQuoteTopic(widget.topic);

  void _arrived(String id) => _arrivedAt[id] = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _sub = context.appRead.realtime.on('chat.message').listen((e) {
      final m = (e['data'] as Json?)?['message'] as Json?;
      if (e['type'] == 'resync') {
        _load();
        return;
      }
      if (m == null || m['thread_id'] != widget.threadId) return;
      final msg = ChatMessage.fromJson(m);
      if (_messages.any((x) => x.id == msg.id)) return;
      _arrived(msg.id);
      setState(() => _messages = [..._messages, msg]);
      _markRead();
    });
  }

  int _loadSeq = 0;

  Future<void> _load() async {
    final seq = ++_loadSeq;
    try {
      final r =
          await context.api.get('/chat/threads/${widget.threadId}/messages')
              as List;
      // A newer load (e.g. after resync) supersedes this one.
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _messages = r.map((e) => ChatMessage.fromJson(e as Json)).toList();
        _loading = false;
      });
      _markRead();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  void _markRead() {
    context.api
        .post('/chat/threads/${widget.threadId}/read')
        .then((_) => mounted ? context.appRead.loadUnread() : null)
        .ignore();
  }

  Future<void> _send(Json body) async {
    setState(() => _sending = true);
    try {
      final m = ChatMessage.fromJson(
        await context.api.post(
              '/chat/threads/${widget.threadId}/messages',
              body,
            )
            as Json,
      );
      if (!mounted) return;
      if (!_messages.any((x) => x.id == m.id)) _arrived(m.id);
      setState(() => _messages = [..._messages.where((x) => x.id != m.id), m]);
      _input.clear();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _photo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final url = await context.api.upload(await file.readAsBytes(), file.name);
      await _send({'kind': 'photo', 'url': url});
    } catch (e) {
      if (!mounted) return;
      showToast(context, context.t.error(e));
      setState(() => _sending = false);
    }
  }

  /// One Idempotency-Key per quote card until its deposit succeeds, so a retry after a
  /// timeout replays the first attempt instead of hitting `already_confirmed`.
  final _depositKeys = <String, String>{};

  /// Quote card pay button: same method choice as checkout and booking detail. The card's
  /// deposit goes along as `expected_deposit`; the server refuses it if the quote changed.
  Future<void> _payDeposit(ChatMessage quote) async {
    final bookingId = quote.body['booking_id'] as String;
    final deposit = quote.body['deposit'];
    final finalPrice = quote.body['final_price'];
    // Never pay a card whose amounts can't be bound: say so and fetch the thread again.
    if (deposit is! int || finalPrice is! int) {
      showToast(context, context.t.errorGeneric);
      unawaited(_load());
      return;
    }
    final seen = {
      'expected_deposit': deposit,
      'expected_final_price': finalPrice,
      'expected_quote_message_id': quote.id,
    };
    final choice = await choosePayMethod(context);
    if (choice == null || !mounted) return;
    setState(() => _paying = true);
    try {
      switch (choice) {
        case SavedChoice(:final methodId):
          final key = _depositKeys.putIfAbsent(
            quote.id,
            ApiClient.newIdempotencyKey,
          );
          await context.api.post('/bookings/$bookingId/deposit', {
            'payment_method_id': methodId,
            ...seen,
          }, key);
          _depositKeys.remove(quote.id);
          _paidHere = true;
        case ChannelChoice(:final channel):
          final result = await payWithChannel(context, channel, {
            'kind': 'deposit',
            'booking_id': bookingId,
            ...seen,
          });
          if (!mounted) return;
          switch (result) {
            case CheckoutAwaitingDeposit(:final account):
              await showVirtualAccount(context, account);
            case CheckoutFailed(:final code):
              showToast(context, context.t.checkoutFailure(code));
              if (code == _priceChanged) unawaited(_load());
              return;
            case CheckoutPaid():
              _paidHere = true;
            case CheckoutPending():
              // Possibly charged: leave so the quote card's pay button is not offered again.
              context.appRead.bookingsChanged();
              Navigator.of(context).popUntil((r) => r.isFirst);
              return;
            case CheckoutCancelled():
              break;
          }
      }
      if (!mounted) return;
      context.appRead.bookingsChanged();
      if (_paidHere) unawaited(_load());
    } on ApiException catch (e) {
      // A definite answer ends this attempt; only a lost or failed-server reply keeps the key.
      if (!e.isNetwork && e.status < 500) _depositKeys.remove(quote.id);
      if (!mounted) return;
      if (e.code == _priceChanged) {
        // The quote changed after this card was shown: reload so the newest card is the one to pay.
        showToast(context, context.t.error(e));
        unawaited(_load());
      } else {
        showToast(context, context.t.payError(e));
      }
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openBooking() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BookingDetailScreen(id: widget.bookingId!),
    ),
  );

  PreferredSizeWidget _appBar(T t) {
    final roomy = _roomy(context);
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _teamName(t),
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FutureBuilder<String?>(
            future: _hours,
            builder: (context, snap) => Text(
              '${snap.data ?? t.chatHours} · ${t.chatReplyFast}',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.inkSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.bookingId != null)
          roomy
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.sm),
                  child: OutlinedButton(
                    onPressed: _openBooking,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: context.colors.line),
                      foregroundColor: context.colors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    ),
                    child: Text(t.viewBooking),
                  ),
                )
              // Small phones and large text: an icon keeps the team name readable.
              : IconButton(
                  tooltip: t.viewBooking,
                  icon: const Icon(Icons.receipt_long_rounded),
                  onPressed: _openBooking,
                ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final depositPaid =
        _paidHere ||
        _messages.any(
          (m) => m.kind == 'system' && m.body['code'] == 'deposit_paid',
        );
    // Only the newest quote is payable: the server charges the booking's current deposit.
    final latestQuote = _messages
        .where((m) => m.kind == 'quote')
        .lastOrNull
        ?.id;
    final quick = _isQuoteThread
        ? [t.quick_confirm, t.quick_quote, t.quick_reschedule]
        : [t.quick_hello, t.quick_price, t.quick_duration, t.quick_date];
    final reversed = _messages.reversed.toList();
    // "상담이 접수됐어요" joins its day's date pill instead of a pill of its own.
    final receivedDays = {
      for (final m in _messages)
        if (_isReceived(m)) _dayOf(m.createdAt),
    };
    final now = DateTime.now();
    bool live(String id) =>
        now.difference(_arrivedAt[id] ?? DateTime(0)) < Motion.celebrate;
    return Scaffold(
      backgroundColor: c.surface,
      appBar: _appBar(t),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.all(Space.md),
                    itemCount: reversed.length,
                    // Keyed so a new message at the bottom never hands its state to an older one.
                    findChildIndexCallback: (key) {
                      final i = reversed.indexWhere(
                        (m) => ValueKey(m.id) == key,
                      );
                      return i < 0 ? null : i;
                    },
                    itemBuilder: (_, i) {
                      final m = reversed[i];
                      final day = _dayOf(m.createdAt);
                      final firstOfDay =
                          i == reversed.length - 1 ||
                          _dayOf(reversed[i + 1].createdAt) != day;
                      return Column(
                        key: ValueKey(m.id),
                        children: [
                          if (firstOfDay)
                            _DayDivider(
                              day: day,
                              received: receivedDays.contains(day),
                            ),
                          if (!_isReceived(m))
                            _Bubble(
                              message: m,
                              depositPaid: depositPaid,
                              latestQuote: latestQuote,
                              live: live(m.id),
                              onPay: _paying ? null : _payDeposit,
                            ),
                        ],
                      );
                    },
                  ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              children: [
                for (final (i, q) in quick.indexed)
                  _Entrance(
                    from: const Offset(24, 0),
                    delay: Duration(milliseconds: 40 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(q),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: Space.xxs,
                        ),
                        // The first reply is the suggested one (design p04).
                        side: BorderSide(
                          color: i == 0 ? context.colors.accent : c.line,
                        ),
                        backgroundColor: i == 0 ? c.primaryTint : c.surface,
                        labelStyle: context.text.labelLarge?.copyWith(
                          color: i == 0 ? context.colors.accent : c.ink,
                          fontWeight: i == 0 ? FontWeight.w700 : null,
                        ),
                        onPressed: _sending
                            ? null
                            : () => _send({'kind': 'text', 'text': q}),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                Space.xs,
                Space.sm,
                Space.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: t.chatPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: _sending ? null : _photo,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: t.chatHint,
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: c.surfaceHigh,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: Space.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.pill),
                          borderSide: BorderSide(color: context.colors.accent),
                        ),
                      ),
                      onSubmitted: (v) => v.trim().isEmpty
                          ? null
                          : _send({'kind': 'text', 'text': v}),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  IconButton.filled(
                    tooltip: t.chatSend,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(44),
                    ),
                    onPressed: _sending
                        ? null
                        : () => _input.text.trim().isEmpty
                              ? null
                              : _send({'kind': 'text', 'text': _input.text}),
                    icon: const Icon(Icons.arrow_upward_rounded),
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
