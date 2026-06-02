import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/models/booking_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _messageIds = {};

  String? _myId;
  String? _customerName;
  String? _assistantName;
  bool _loading = true;

  late final void Function() _onSocketConnect;

  @override
  void initState() {
    super.initState();
    _myId = ref.read(authProvider).user?.id;
    _onSocketConnect = () => ref.read(socketServiceProvider).joinBooking(widget.bookingId);
    _setupRealtime();
    _load();
  }

  void _setupRealtime() {
    final socket = ref.read(socketServiceProvider);
    socket.on('chat:message', _onMessage);
    socket.onConnect(_onSocketConnect);
    socket.joinBooking(widget.bookingId);
  }

  @override
  void dispose() {
    final socket = ref.read(socketServiceProvider);
    socket.off('chat:message', _onMessage);
    socket.offConnect(_onSocketConnect);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    _appendMessage(Map<String, dynamic>.from(data));
  }

  void _appendMessage(Map<String, dynamic> raw) {
    final normalized = _normalizeMessage(raw);
    final id = normalized['id'] as String?;
    if (id != null) {
      if (_messageIds.contains(id)) return;
      _messageIds.add(id);
    }
    if (!mounted) return;
    setState(() => _messages.add(normalized));
    _scrollToBottom();
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> m) {
    final sender = m['sender'] is Map ? Map<String, dynamic>.from(m['sender'] as Map) : null;
    return {
      'id': m['id']?.toString() ?? 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      'bookingId': m['bookingId']?.toString() ?? m['booking_id']?.toString(),
      'senderId': m['senderId']?.toString() ?? m['sender_id']?.toString() ?? sender?['id']?.toString(),
      'message': m['message'] as String? ?? '',
      'createdAt': m['createdAt']?.toString() ?? m['created_at']?.toString(),
      'sender': sender,
    };
  }

  String _senderName(Map<String, dynamic> m, {required bool isMe}) {
    if (isMe) return 'You';
    final sender = m['sender'] as Map<String, dynamic>?;
    final name = sender?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final senderId = m['senderId'] as String?;
    if (senderId != null && senderId == _bookingCustomerId) return _customerName ?? 'Customer';
    if (senderId != null && senderId == _bookingAssistantId) return _assistantName ?? 'Assistant';
    return 'Assistant';
  }

  String? _bookingCustomerId;
  String? _bookingAssistantId;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).getBooking(widget.bookingId);
      final msgs = await ref.read(chatRepositoryProvider).getMessages(widget.bookingId);
      if (!mounted) return;
      _applyBooking(booking);
      _messages.clear();
      _messageIds.clear();
      for (final raw in msgs) {
        final m = _normalizeMessage(Map<String, dynamic>.from(raw));
        final id = m['id'] as String?;
        if (id != null) _messageIds.add(id);
        _messages.add(m);
      }
      setState(() => _loading = false);
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyBooking(BookingModel booking) {
    _bookingCustomerId = booking.customer?['id'] as String?;
    _bookingAssistantId = booking.assistant?['id'] as String?;
    _customerName = booking.customer?['name'] as String? ?? 'Customer';
    _assistantName = booking.assistant?['name'] as String? ?? 'Assistant';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      final msg = await ref.read(chatRepositoryProvider).sendMessage(widget.bookingId, text);
      if (mounted) _appendMessage(Map<String, dynamic>.from(msg));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message. Please try again.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final participantLine = (_customerName != null && _assistantName != null)
        ? '$_customerName · $_assistantName'
        : 'Booking chat';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              participantLine,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary.withValues(alpha: 0.95)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Say hello to your ${_myId == _bookingCustomerId ? _assistantName ?? 'assistant' : _customerName ?? 'customer'}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final senderId = m['senderId'] as String?;
                          final isMe = senderId != null && senderId == _myId;
                          final name = _senderName(m, isMe: isMe);
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isMe ? AppColors.primary : AppColors.navy,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? AppColors.primary : AppColors.surface,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 16),
                                      ),
                                    ),
                                    child: Text(
                                      m['message'] as String? ?? '',
                                      style: TextStyle(color: isMe ? Colors.white : AppColors.charcoal, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    child: InkWell(
                      onTap: _send,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
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
