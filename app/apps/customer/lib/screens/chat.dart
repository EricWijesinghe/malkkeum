import 'dart:async';

import 'package:core/auth_pay.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'booking_detail.dart';
import 'booking_flow.dart';
import 'pay_flow.dart';

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

/// Below this title width the app-bar avatar is dropped so the team name keeps its room.
const _avatarMinTitleWidth = 180.0;

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

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});
  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  final _view = GlobalKey<AsyncViewState<List<ChatThread>>>();
  StreamSubscription<Json>? _sub;
  late final Future<String?> _hours = _supportHours(context.api);

  @override
  void initState() {
    super.initState();
    _sub = context.appRead.realtime
        .on('chat.message')
        .listen((_) => _view.currentState?.reload());
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
          for (final code in _topics)
            InkWell(
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
      appBar: AppBar(title: Text(t.chatTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newChat,
        icon: const Icon3D('chat_new', size: 28),
        label: Text(t.chatNew),
      ),
      body: AsyncView<List<ChatThread>>(
        key: _view,
        load: _load,
        // The header scrolls with the threads so large text never overflows a short screen.
        builder: (context, threads, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              FutureBuilder<String?>(
                future: _hours,
                builder: (context, snap) =>
                    _TeamHeader(hours: snap.data ?? t.chatHours),
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
              for (final (i, th) in threads.indexed) ...[
                if (i > 0) const Divider(indent: 84),
                _ThreadTile(thread: th, onReturn: reload),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Team profile, operating hours and the usual reply time above the thread list.
class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.hours});
  final String hours;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.xs,
        Space.gutter,
        Space.xs,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            const Icon3D('chat_team_avatar', size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_teamName(t), style: context.text.titleSmall),
                  Text(
                    '${t.chatHoursTitle} · $hours',
                    style: context.text.bodySmall,
                  ),
                  Text(
                    t.chatReplyFast,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.gutter,
        vertical: 6,
      ),
      leading: thread.topic == 'other'
          ? const CircleAvatar(
              radius: 26,
              child: Icon(Icons.support_agent_rounded),
            )
          : ServiceGlyph(thread.topic, size: 52),
      title: Text(topicLabel(t, thread.topic), style: context.text.titleSmall),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeLabel(thread.lastMessageAt, context.lang),
            style: context.text.labelSmall,
          ),
          const SizedBox(height: 4),
          if (thread.unreadMember > 0)
            Badge(label: Text('${thread.unreadMember}')),
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

  bool get _isQuoteThread =>
      widget.topic == 'move_in' || widget.topic == 'move_out';

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

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, c) => Row(
            children: [
              if (c.maxWidth >= _avatarMinTitleWidth) ...[
                const Icon3D('chat_team_avatar', size: 36),
                const SizedBox(width: Space.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _teamName(t),
                      style: context.text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FutureBuilder<String?>(
                      future: _hours,
                      builder: (context, snap) => Text(
                        '${topicLabel(t, widget.topic)} · ${snap.data ?? t.chatHours}',
                        style: context.text.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // An icon, not a text button: a long label squeezes the title out on small phones.
          if (widget.bookingId != null)
            IconButton(
              tooltip: t.viewBooking,
              icon: const Icon(Icons.receipt_long_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookingDetailScreen(id: widget.bookingId!),
                ),
              ),
            ),
        ],
      ),
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
                    itemBuilder: (_, i) => _Bubble(
                      message: reversed[i],
                      depositPaid: depositPaid,
                      latestQuote: latestQuote,
                      onPay: _paying ? null : _payDeposit,
                    ),
                  ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              children: [
                for (final q in quick)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(q),
                      onPressed: _sending
                          ? null
                          : () => _send({'kind': 'text', 'text': q}),
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
                Space.xs,
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
                      ),
                      onSubmitted: (v) => v.trim().isEmpty
                          ? null
                          : _send({'kind': 'text', 'text': v}),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  IconButton.filled(
                    tooltip: t.chatSend,
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.depositPaid,
    required this.latestQuote,
    required this.onPay,
  });
  final ChatMessage message;
  final bool depositPaid;
  final String? latestQuote;

  /// Null while a payment is in flight.
  final void Function(ChatMessage quote)? onPay;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final t = context.t;
    final mine = m.sender == 'customer';
    if (m.kind == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: Space.xs),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.line,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            t.system(
              m.body['code'] as String? ?? '',
              (m.body['params'] as Json?) ?? const {},
              context.lang,
            ),
            style: context.text.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final Widget content = switch (m.kind) {
      'photo' => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          m.body['url'] as String,
          width: 200,
          cacheWidth: 400,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(width: 200, height: 120),
        ),
      ),
      'card' => _RequestCard(body: m.body),
      'quote' => _QuoteCard(
        body: m.body,
        paid: depositPaid,
        superseded: m.id != latestQuote,
        onPay: onPay == null ? null : () => onPay!(m),
      ),
      _ => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? context.primary : context.colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.isAi)
              Text(
                t.aiLabel,
                style: context.text.labelSmall?.copyWith(
                  color: mine
                      ? Colors.white70
                      : context.colors.ink.withValues(alpha: 0.6),
                ),
              ),
            Text(
              m.body['text'] as String? ?? '',
              style: context.text.bodyMedium?.copyWith(
                color: mine ? Colors.white : context.colors.ink,
              ),
            ),
          ],
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            const Icon3D('chat_team_avatar', size: 32),
            const SizedBox(width: 6),
          ],
          if (mine)
            Text(
              timeLabel(m.createdAt, context.lang),
              style: context.text.labelSmall?.copyWith(fontSize: 10),
            ),
          if (mine) const SizedBox(width: 4),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: content,
            ),
          ),
          if (!mine) const SizedBox(width: 4),
          if (!mine)
            Text(
              timeLabel(m.createdAt, context.lang),
              style: context.text.labelSmall?.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.body});
  final Json body;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final code = body['service_code'] as String? ?? 'move_in';
    final hue = ServiceHues.of(code);
    return AppCard(
      border: context.colors.line,
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag(label: t.requestCard, hue: hue),
          const SizedBox(height: Space.xs),
          Text(t.service(code), style: context.text.titleSmall),
          if (body['visit_date'] != null)
            Text(
              dateLabel(
                DateTime.parse(body['visit_date'] as String),
                context.lang,
              ),
              style: context.text.bodySmall,
            ),
          const Divider(height: Space.lg),
          Row(
            children: [
              Text(t.estimate, style: context.text.bodySmall),
              const Spacer(),
              Text(
                context.won((body['estimate'] as num? ?? 0).toInt()),
                style: context.text.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    BookingDetailScreen(id: body['booking_id'] as String),
              ),
            ),
            child: Text(t.viewBooking),
          ),
        ],
      ),
    );
  }
}

/// Staff quote: booking rows, confirmed total and the deposit button. Every amount is read
/// from the message body the server wrote; nothing is computed here.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.body,
    required this.paid,
    required this.superseded,
    required this.onPay,
  });
  final Json body;
  final bool paid;
  final bool superseded;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lang = context.lang;
    int n(String k) => (body[k] as num? ?? 0).toInt();
    final visit = DateTime.tryParse(body['visit_date'] as String? ?? '');
    final hour = (body['start_hour'] as num?)?.toInt();
    final code = body['service_code'] as String?;
    final answers = body['answers'] is Json
        ? body['answers'] as Json
        : const <String, dynamic>{};
    final structure = [
      if (answers['building'] case final String b) _buildingLabel(t, b),
      if (answers['layout'] case final String l) _layoutLabel(t, l),
    ].join(' · ');
    final estimate = body['estimate'] as num?;
    final rows = [
      if (visit != null)
        (
          t.quoteVisit,
          [
            dateLabel(visit, lang),
            if (hour != null) hour < 12 ? t.morning : t.afternoon,
          ].join(' '),
        ),
      if (code != null) (t.quoteKind, t.service(code)),
      if (structure.isNotEmpty) (t.layoutTitle, structure),
      if (estimate != null) (t.estimate, context.won(estimate.toInt())),
    ];
    Widget line(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.only(top: Space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: context.text.bodySmall)),
          const SizedBox(width: Space.xs),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: style ?? context.text.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
    final payable = !paid && !superseded;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: Elevation.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon3D('chat_quote', size: 28),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Text(
                        t.quoteArrived,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final (label, value) in rows) line(label, value),
                const Divider(height: Space.lg),
                Text(t.finalPrice, style: context.text.bodySmall),
                Text(
                  context.won(n('final_price')),
                  style: context.text.headlineMedium,
                ),
                line(
                  t.quoteDepositNow,
                  context.won(n('deposit')),
                  style: context.text.titleSmall,
                ),
                line(
                  t.quoteBalanceLater,
                  context.won(n('balance')),
                  style: context.text.bodySmall,
                ),
                if ((body['note'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: Space.xs),
                  Text(body['note'] as String, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              minimumSize: const Size.fromHeight(52),
              // Accent CTA: check yellow with ink label (never white on yellow).
              backgroundColor: paid ? context.colors.fresh : context.colors.sun,
              foregroundColor: Neutral.c900,
            ),
            onPressed: payable ? onPay : null,
            child: Text(
              paid
                  ? t.quotePaid
                  : superseded
                  ? t.quoteSuperseded
                  : t.quotePayAmount(context.won(n('deposit'))),
            ),
          ),
        ],
      ),
    );
  }
}
