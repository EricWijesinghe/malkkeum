part of 'chat.dart';

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

  /// Why the first load failed; cleared by the load that succeeds.
  Object? _error;
  bool _paying = false;

  /// Set when this screen's own payment succeeded, before the `deposit_paid` message arrives.
  bool _paidHere = false;

  /// The quote whose deposit was charged and is being given back (the push says when it lands).
  String? _refundingQuote;
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
      final r = await context.api.get(
        '/chat/threads/${widget.threadId}/messages',
      ) as List;
      // A newer load (e.g. after resync) supersedes this one.
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _messages = r.map((e) => ChatMessage.fromJson(e as Json)).toList();
        _loading = false;
        _error = null;
      });
      _markRead();
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      // Nothing loaded yet: an error with retry instead of a spinner that never ends.
      // With the room on screen the messages stay and a toast says why.
      if (_loading) {
        setState(() => _error = e);
      } else {
        showToast(context, context.t.error(e));
      }
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
        ) as Json,
      );
      if (!mounted) return;
      if (!_messages.any((x) => x.id == m.id)) _arrived(m.id);
      setState(() => _messages = [..._messages.where((x) => x.id != m.id), m]);
      _input.clear();
      // The send got through, so the history that failed to load will too.
      if (_error != null) unawaited(_load());
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
              if (code == _refundPending) {
                setState(() => _refundingQuote = quote.id);
              }
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
      if (e.code == _refundPending) setState(() => _refundingQuote = quote.id);
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
            _teamName(context, t),
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
            child: _error != null
                ? ErrorRetry(
                    message: t.error(_error!),
                    retryLabel: t.retry,
                    onRetry: _load,
                  )
                : _loading
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
                              refundingQuote: _refundingQuote,
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
