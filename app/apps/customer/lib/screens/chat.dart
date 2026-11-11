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

const _topics = ['studio', 'kitchen', 'bathroom', 'mattress', 'aircon', 'sofa', 'move_out', 'move_in', 'other'];

String topicLabel(T t, String topic) => topic == 'other' ? t.topicOther : t.service(topic);

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});
  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  final _view = GlobalKey<AsyncViewState<List<ChatThread>>>();
  StreamSubscription<Json>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.appRead.realtime.on('chat.message').listen((_) => _view.currentState?.reload());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<List<ChatThread>> _load() async => (await context.api.get('/chat/threads') as List).map((e) => ChatThread.fromJson(e as Json)).toList();

  Future<void> _newChat() async {
    final t = context.t;
    final topic = await showAppSheet<String>(
      context,
      title: t.chatTopicTitle,
      builder: (ctx) => GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter),
        childAspectRatio: 1.05,
        children: [
          for (final code in _topics)
            InkWell(
              borderRadius: BorderRadius.circular(Radii.tile),
              onTap: () => Navigator.of(ctx).pop(code),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                code == 'other' ? const CircleAvatar(radius: 26, child: Icon(Icons.more_horiz_rounded)) : ServiceGlyph(code, size: 52),
                const SizedBox(height: 6),
                Text(code == 'other' ? t.topicOther : t.serviceShort(code), style: ctx.text.labelMedium, textAlign: TextAlign.center),
              ]),
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
      floatingActionButton: FloatingActionButton.extended(onPressed: _newChat, icon: const Icon(Icons.add_comment_rounded), label: Text(t.chatNew)),
      body: AsyncView<List<ChatThread>>(
        key: _view,
        load: _load,
        builder: (context, threads, reload) => threads.isEmpty
            ? EmptyState(icon: Icons.forum_rounded, title: t.chatEmpty, body: t.chatHours, hue: ServiceHues.aircon)
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const Divider(indent: 84),
                  itemBuilder: (_, i) => _ThreadTile(thread: threads[i], onReturn: reload),
                ),
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
      'system' => t.system((last!['body'] as Json)['code'] as String? ?? '', ((last['body'] as Json)['params'] as Json?) ?? const {}, context.lang),
      _ => '',
    };
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 6),
      leading: thread.topic == 'other' ? const CircleAvatar(radius: 26, child: Icon(Icons.support_agent_rounded)) : ServiceGlyph(thread.topic, size: 52),
      title: Text(topicLabel(t, thread.topic), style: context.text.titleSmall),
      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(timeLabel(thread.lastMessageAt, context.lang), style: context.text.labelSmall),
        const SizedBox(height: 4),
        if (thread.unreadMember > 0) Badge(label: Text('${thread.unreadMember}')),
      ]),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(threadId: thread.id, topic: thread.topic, bookingId: thread.bookingId)));
        await onReturn();
      },
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.threadId, required this.topic, this.bookingId});
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

  bool get _isQuoteThread => widget.topic == 'move_in' || widget.topic == 'move_out';

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
      final r = await context.api.get('/chat/threads/${widget.threadId}/messages') as List;
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
    context.api.post('/chat/threads/${widget.threadId}/read').then((_) => mounted ? context.appRead.loadUnread() : null).ignore();
  }

  Future<void> _send(Json body) async {
    setState(() => _sending = true);
    try {
      final m = ChatMessage.fromJson(await context.api.post('/chat/threads/${widget.threadId}/messages', body) as Json);
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
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
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

  /// Quote card pay button: same method choice as checkout and booking detail.
  Future<void> _payDeposit(String bookingId) async {
    final choice = await choosePayMethod(context);
    if (choice == null || !mounted) return;
    try {
      switch (choice) {
        case SavedChoice(:final methodId):
          await context.api.post('/bookings/$bookingId/deposit', {'payment_method_id': methodId}, ApiClient.newIdempotencyKey());
        case ChannelChoice(:final channel):
          final result = await payWithChannel(context, channel, {'kind': 'deposit', 'booking_id': bookingId});
          if (!mounted) return;
          switch (result) {
            case CheckoutAwaitingDeposit(:final account):
              await showVirtualAccount(context, account);
            case CheckoutFailed(:final code):
              showToast(context, context.t.checkoutFailure(code));
              return;
            case CheckoutPaid() || CheckoutCancelled():
              break;
          }
      }
      if (!mounted) return;
      context.appRead.bookingsChanged();
    } catch (e) {
      if (mounted) showToast(context, context.t.payError(e));
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
    final depositPaid = _messages.any((m) => m.kind == 'system' && m.body['code'] == 'deposit_paid');
    final quick = _isQuoteThread ? [t.quick_confirm, t.quick_price, t.quick_date, t.quick_parking] : [t.quick_hello, t.quick_price, t.quick_duration, t.quick_date];
    final reversed = _messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${BrandConfig.placeholder.name} ${t.chatTeam}', style: context.text.titleMedium),
          Text('${topicLabel(t, widget.topic)} · ${t.chatHours}', style: context.text.labelSmall),
        ]),
        actions: [
          if (widget.bookingId != null)
            TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: widget.bookingId!))), child: Text(t.viewBooking)),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(Space.md),
                  itemCount: reversed.length,
                  itemBuilder: (_, i) => _Bubble(message: reversed[i], depositPaid: depositPaid, onPay: _payDeposit),
                ),
        ),
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: Space.md), children: [
            for (final q in quick) Padding(padding: const EdgeInsets.only(right: 6), child: ActionChip(label: Text(q), onPressed: _sending ? null : () => _send({'kind': 'text', 'text': q}))),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.xs, Space.xs),
            child: Row(children: [
              IconButton(tooltip: t.chatPhoto, icon: const Icon(Icons.photo_camera_outlined), onPressed: _sending ? null : _photo),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(hintText: t.chatHint, counterText: '', isDense: true),
                  onSubmitted: (v) => v.trim().isEmpty ? null : _send({'kind': 'text', 'text': v}),
                ),
              ),
              const SizedBox(width: Space.xs),
              IconButton.filled(
                tooltip: t.chatSend,
                onPressed: _sending ? null : () => _input.text.trim().isEmpty ? null : _send({'kind': 'text', 'text': _input.text}),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.depositPaid, required this.onPay});
  final ChatMessage message;
  final bool depositPaid;
  final void Function(String bookingId) onPay;

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
          decoration: BoxDecoration(color: context.colors.line, borderRadius: BorderRadius.circular(Radii.pill)),
          child: Text(t.system(m.body['code'] as String? ?? '', (m.body['params'] as Json?) ?? const {}, context.lang), style: context.text.labelSmall, textAlign: TextAlign.center),
        ),
      );
    }
    final Widget content = switch (m.kind) {
      'photo' => ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(m.body['url'] as String, width: 200, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 200, height: 120))),
      'card' => _RequestCard(body: m.body),
      'quote' => _QuoteCard(body: m.body, paid: depositPaid, onPay: () => onPay(m.body['booking_id'] as String)),
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
              if (m.isAi) Text(t.aiLabel, style: context.text.labelSmall?.copyWith(color: mine ? Colors.white70 : context.colors.ink.withValues(alpha: 0.6))),
              Text(m.body['text'] as String? ?? '', style: context.text.bodyMedium?.copyWith(color: mine ? Colors.white : context.colors.ink)),
            ],
          ),
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (!mine) ...[CircleAvatar(radius: 16, backgroundColor: context.primary, child: const Icon(Icons.support_agent_rounded, size: 18, color: Colors.white)), const SizedBox(width: 6)],
        if (mine) Text(timeLabel(m.createdAt, context.lang), style: context.text.labelSmall?.copyWith(fontSize: 10)),
        if (mine) const SizedBox(width: 4),
        Flexible(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: content)),
        if (!mine) const SizedBox(width: 4),
        if (!mine) Text(timeLabel(m.createdAt, context.lang), style: context.text.labelSmall?.copyWith(fontSize: 10)),
      ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Tag(label: t.requestCard, hue: hue),
        const SizedBox(height: Space.xs),
        Text(t.service(code), style: context.text.titleSmall),
        if (body['visit_date'] != null) Text(dateLabel(DateTime.parse(body['visit_date'] as String), context.lang), style: context.text.bodySmall),
        const Divider(height: Space.lg),
        Row(children: [
          Text(t.estimate, style: context.text.bodySmall),
          const Spacer(),
          Text(context.won((body['estimate'] as num? ?? 0).toInt()), style: context.text.titleSmall),
        ]),
        const SizedBox(height: Space.xs),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BookingDetailScreen(id: body['booking_id'] as String))),
          child: Text(t.viewBooking),
        ),
      ]),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.body, required this.paid, required this.onPay});
  final Json body;
  final bool paid;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    int n(String k) => (body[k] as num? ?? 0).toInt();
    return Container(
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(Radii.card), boxShadow: Elevation.raised),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.quoteArrived, style: context.text.labelMedium?.copyWith(color: context.primary)),
            Text(context.won(n('final_price')), style: context.text.headlineMedium),
            const SizedBox(height: Space.xs),
            Row(children: [Expanded(child: Text(t.quoteDepositNow, style: context.text.bodySmall)), Text(context.won(n('deposit')), style: context.text.titleSmall)]),
            Row(children: [Expanded(child: Text(t.quoteBalanceLater, style: context.text.bodySmall)), Text(context.won(n('balance')), style: context.text.bodySmall)]),
            if ((body['note'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: Space.xs), Text(body['note'] as String, style: context.text.bodySmall)],
          ]),
        ),
        FilledButton(
          style: FilledButton.styleFrom(shape: const RoundedRectangleBorder(), backgroundColor: paid ? context.colors.fresh : null),
          onPressed: paid ? null : onPay,
          child: Text(paid ? t.quotePaid : t.quotePay),
        ),
      ]),
    );
  }
}
