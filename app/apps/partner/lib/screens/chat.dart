import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ui/ui.dart';

import '../state.dart';
import 'jobs.dart';

String opsTopicLabel(T t, String topic) => switch (topic) {
      'settlement' => t.pTopic_settlement,
      'reschedule' => t.pTopic_reschedule,
      'app' => t.pTopic_app,
      'other' => t.topicOther,
      _ => t.service(topic),
    };

Future<void> openOpsThread(BuildContext context, {required String topic, String? bookingId}) async {
  try {
    final r = await context.api.post('/chat/threads', {'topic': topic, 'booking_id': bookingId}) as Json;
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OpsRoom(threadId: r['id'] as String, topic: topic, bookingId: bookingId)));
  } catch (e) {
    if (context.mounted) showToast(context, context.t.error(e));
  }
}

class OpsChatTab extends StatefulWidget {
  const OpsChatTab({super.key});
  @override
  State<OpsChatTab> createState() => _OpsChatTabState();
}

class _OpsChatTabState extends State<OpsChatTab> {
  final _view = GlobalKey<AsyncViewState<List<ChatThread>>>();
  StreamSubscription<Json>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.proRead.realtime.on('chat.message').listen((_) => _view.currentState?.reload());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _new() async {
    final t = context.t;
    final topic = await showAppSheet<String>(
      context,
      title: t.pNewInquiry,
      builder: (ctx) => ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gutter), children: [
        for (final (code, icon) in const [('settlement', Icons.payments_rounded), ('reschedule', Icons.event_repeat_rounded), ('app', Icons.phone_iphone_rounded), ('other', Icons.more_horiz_rounded)])
          ListTile(leading: Icon(icon), title: Text(opsTopicLabel(t, code)), onTap: () => Navigator.of(ctx).pop(code)),
      ]),
    );
    if (topic != null && mounted) {
      await openOpsThread(context, topic: topic);
      await _view.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: Text(t.chatTitle, style: context.text.headlineSmall)),
      floatingActionButton: FloatingActionButton.extended(onPressed: _new, icon: const Icon(Icons.add_comment_rounded), label: Text(t.pNewInquiry)),
      body: AsyncView<List<ChatThread>>(
        key: _view,
        load: () async => (await context.api.get('/partner/threads') as List).map((e) => ChatThread.fromJson(e as Json)).toList(),
        builder: (context, threads, reload) => threads.isEmpty
            ? EmptyState(icon: Icons.forum_rounded, title: t.chatEmpty, hue: ServiceHues.aircon)
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const Divider(indent: 76),
                  itemBuilder: (_, i) {
                    final th = threads[i];
                    final last = th.lastMessage;
                    final preview = last == null ? '' : ((last['body'] as Json)['text'] as String? ?? (last['kind'] == 'photo' ? t.chatPhoto : ''));
                    return ListTile(
                      leading: th.bookingId != null ? ServiceGlyph(th.topic, size: 44) : const CircleAvatar(radius: 22, child: Icon(Icons.support_agent_rounded)),
                      title: Text(opsTopicLabel(t, th.topic)),
                      subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: th.unreadMember > 0 ? Badge(label: Text('${th.unreadMember}')) : Text(timeLabel(th.lastMessageAt, context.lang), style: context.text.labelSmall),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OpsRoom(threadId: th.id, topic: th.topic, bookingId: th.bookingId)));
                        await reload();
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class OpsRoom extends StatefulWidget {
  const OpsRoom({super.key, required this.threadId, required this.topic, this.bookingId});
  final String threadId;
  final String topic;
  final String? bookingId;
  @override
  State<OpsRoom> createState() => _OpsRoomState();
}

class _OpsRoomState extends State<OpsRoom> {
  final _input = TextEditingController();
  List<ChatMessage> _msgs = [];
  StreamSubscription<Json>? _sub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = context.proRead.realtime.on('chat.message').listen((e) {
      final m = (e['data'] as Json?)?['message'] as Json?;
      if (m == null || m['thread_id'] != widget.threadId) return;
      final msg = ChatMessage.fromJson(m);
      if (_msgs.any((x) => x.id == msg.id)) return;
      setState(() => _msgs = [..._msgs, msg]);
      _read();
    });
  }

  Future<void> _load() async {
    final r = await context.api.get('/chat/threads/${widget.threadId}/messages') as List;
    if (!mounted) return;
    setState(() => _msgs = r.map((e) => ChatMessage.fromJson(e as Json)).toList());
    _read();
  }

  void _read() => context.api.post('/chat/threads/${widget.threadId}/read').then((_) => mounted ? context.proRead.loadBadges() : null).ignore();

  Future<void> _send(Json body) async {
    setState(() => _sending = true);
    try {
      final m = ChatMessage.fromJson(await context.api.post('/chat/threads/${widget.threadId}/messages', body) as Json);
      if (!mounted) return;
      setState(() => _msgs = [..._msgs.where((x) => x.id != m.id), m]);
      _input.clear();
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _photo() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
    if (f == null || !mounted) return;
    try {
      final url = await context.api.upload(await f.readAsBytes(), f.name);
      await _send({'kind': 'photo', 'url': url});
    } catch (e) {
      if (mounted) showToast(context, context.t.error(e));
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.pOpsTeam, style: context.text.titleMedium), Text(opsTopicLabel(t, widget.topic), style: context.text.labelSmall)]),
        actions: [if (widget.bookingId != null) TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JobDetailScreen(id: widget.bookingId!))), child: Text(t.pViewJob))],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(Space.md),
            itemCount: reversed.length,
            itemBuilder: (_, i) {
              final m = reversed[i];
              final mine = m.sender == 'partner';
              if (m.kind == 'system') {
                return Center(child: Padding(padding: const EdgeInsets.all(Space.xs), child: Text(t.system(m.body['code'] as String? ?? '', (m.body['params'] as Json?) ?? const {}, context.lang), style: context.text.labelSmall)));
              }
              final child = m.kind == 'photo'
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(m.body['url'] as String, width: 200, fit: BoxFit.cover))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: mine ? context.colors.ink : context.colors.surface, borderRadius: BorderRadius.circular(18)),
                      child: Text(m.body['text'] as String? ?? '', style: context.text.bodyMedium?.copyWith(color: mine ? context.colors.surface : context.colors.ink)),
                    );
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 300), child: child)),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Space.xs),
            child: Row(children: [
              IconButton(tooltip: t.chatPhoto, icon: const Icon(Icons.photo_camera_outlined), onPressed: _sending ? null : _photo),
              Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 4, maxLength: 2000, decoration: InputDecoration(hintText: t.chatHint, counterText: '', isDense: true))),
              const SizedBox(width: Space.xs),
              IconButton.filled(tooltip: t.chatSend, onPressed: _sending ? null : () => _input.text.trim().isEmpty ? null : _send({'kind': 'text', 'text': _input.text}), icon: const Icon(Icons.arrow_upward_rounded)),
            ]),
          ),
        ),
      ]),
    );
  }
}
