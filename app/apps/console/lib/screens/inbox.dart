import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'bookings.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with LiveReload {
  String _audience = 'customer';
  List<ChatThread> _threads = [];
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onLive() => _load();

  Future<void> _load() async {
    try {
      final r =
          await context.api.get(
                '/admin/threads',
                query: {'audience': _audience},
              )
              as List;
      if (!mounted) return;
      setState(() {
        _threads = r.map((e) => ChatThread.fromJson(e as Json)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    }
  }

  void _open(ChatThread th) {
    if (context.isWide) {
      setState(() => _selected = th.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(context.t.service(th.topic))),
            body: ThreadView(threadId: th.id, bookingId: th.bookingId),
          ),
        ),
      );
    }
  }

  void _move(int delta) {
    if (_threads.isEmpty) return;
    final i = _threads.indexWhere((t) => t.id == _selected);
    final next = (i + delta).clamp(0, _threads.length - 1);
    setState(() => _selected = _threads[next].id);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final list = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'customer', label: Text(t.cCustomerChats)),
                ButtonSegment(value: 'partner', label: Text(t.cPartnerChats)),
              ],
              selected: {_audience},
              onSelectionChanged: (s) {
                setState(() {
                  _audience = s.first;
                  _selected = null;
                });
                _load();
              },
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const SkeletonList()
              : ListView.builder(
                  itemCount: _threads.length,
                  itemBuilder: (_, i) {
                    final th = _threads[i];
                    final last = th.lastMessage;
                    final preview = last == null
                        ? ''
                        : ((last['body'] as Json)['text'] as String? ??
                              last['kind'] as String);
                    return ListTile(
                      selected: th.id == _selected,
                      selectedTileColor: context.colors.primaryTint,
                      leading:
                          [
                            'other',
                            'settlement',
                            'reschedule',
                            'app',
                          ].contains(th.topic)
                          ? const CircleAvatar(child: Icon(Icons.chat_rounded))
                          : ServiceGlyph(th.topic, size: 40),
                      title: Text(
                        th.topic == 'other'
                            ? t.topicOther
                            : t.service(th.topic),
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: th.unreadStaff > 0
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: th.unreadStaff > 0
                          ? Badge(label: Text('${th.unreadStaff}'))
                          : Text(
                              timeLabel(th.lastMessageAt, context.lang),
                              style: context.text.labelSmall,
                            ),
                      onTap: () => _open(th),
                    );
                  },
                ),
        ),
        if (context.isWide)
          Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: Text(t.cShortcuts, style: context.text.labelSmall),
          ),
      ],
    );
    if (!context.isWide) return list;
    final selected = _threads.where((x) => x.id == _selected).firstOrNull;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyJ): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.keyK): () => _move(-1),
      },
      child: Focus(
        autofocus: true,
        child: Row(
          children: [
            SizedBox(width: 360, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? EmptyState(
                      icon: Icons.forum_rounded,
                      title: t.cSelectThread,
                    )
                  : ThreadView(
                      key: ValueKey(selected.id),
                      threadId: selected.id,
                      bookingId: selected.bookingId,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conversation + composer. Marks the thread read for staff on open and on new messages.
class ThreadView extends StatefulWidget {
  const ThreadView({super.key, required this.threadId, this.bookingId});
  final String threadId;
  final String? bookingId;
  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final _input = TextEditingController();
  List<ChatMessage> _msgs = [];
  StreamSubscription<Json>? _sub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = context.consoleRead.realtime.on('chat.message').listen((e) {
      final m = (e['data'] as Json?)?['message'] as Json?;
      if (m == null || m['thread_id'] != widget.threadId) return;
      final msg = ChatMessage.fromJson(m);
      if (_msgs.any((x) => x.id == msg.id)) return;
      setState(() => _msgs = [..._msgs, msg]);
      _read();
    });
  }

  Future<void> _load() async {
    final r =
        await context.api.get('/admin/threads/${widget.threadId}/messages')
            as List;
    if (!mounted) return;
    setState(
      () => _msgs = r.map((e) => ChatMessage.fromJson(e as Json)).toList(),
    );
    _read();
  }

  void _read() =>
      context.api.post('/admin/threads/${widget.threadId}/read').ignore();

  Future<void> _send() async {
    if (_input.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final m = ChatMessage.fromJson(
        await context.api.post('/admin/threads/${widget.threadId}/messages', {
              'kind': 'text',
              'text': _input.text,
            })
            as Json,
      );
      if (!mounted) return;
      setState(() => _msgs = [..._msgs.where((x) => x.id != m.id), m]);
      _input.clear();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final reversed = _msgs.reversed.toList();
    return Column(
      children: [
        if (widget.bookingId != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(t.cOpenBooking),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookingDetailPage(id: widget.bookingId),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(Space.lg),
            itemCount: reversed.length,
            itemBuilder: (_, i) => _Message(m: reversed[i]),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter, control: true):
                  _send,
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: t.cReplyHint,
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: _sending ? null : _send,
                  child: Text(t.chatSend),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.m});
  final ChatMessage m;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final staff = m.sender == 'staff';
    if (m.kind == 'system') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            t.system(
              m.body['code'] as String? ?? '',
              (m.body['params'] as Json?) ?? const {},
              context.lang,
            ),
            style: context.text.labelSmall,
          ),
        ),
      );
    }
    final Widget content = switch (m.kind) {
      'photo' => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          m.body['url'] as String,
          width: 220,
          fit: BoxFit.cover,
        ),
      ),
      'card' => Text(
        '${t.requestCard} · ${t.service(m.body['service_code'] as String? ?? '')} · ${t.estimate} ${context.won((m.body['estimate'] as num? ?? 0).toInt())}',
      ),
      'quote' => Text(
        '${t.finalPrice} ${context.won((m.body['final_price'] as num).toInt())} · ${t.deposit} ${context.won((m.body['deposit'] as num).toInt())}',
        style: context.text.titleSmall,
      ),
      _ => SelectableText(m.body['text'] as String? ?? ''),
    };
    return Align(
      alignment: staff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: staff ? context.colors.primaryTint : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            const SizedBox(height: 2),
            Text(
              timeLabel(m.createdAt, context.lang),
              style: context.text.labelSmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
