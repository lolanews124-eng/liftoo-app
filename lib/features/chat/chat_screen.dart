import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = ref.read(authProvider).user?.id;
    _load();
    ref.read(socketServiceProvider).on('chat:message', _onMessage);
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('chat:message', _onMessage);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onMessage(dynamic data) {
    if (data is! Map) return;
    final m = Map<String, dynamic>.from(data);
    final msgBookingId = m['bookingId'] as String? ?? m['booking_id'] as String?;
    if (msgBookingId != null && msgBookingId != widget.bookingId) return;
    if (mounted) {
      setState(() => _messages.add(m));
      _scrollToBottom();
    }
  }

  Future<void> _load() async {
    final msgs = await ref.read(chatRepositoryProvider).getMessages(widget.bookingId);
    if (mounted) {
      setState(() => _messages = msgs);
      _scrollToBottom();
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final msg = await ref.read(chatRepositoryProvider).sendMessage(widget.bookingId, text);
    if (mounted) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final sender = m['sender'] as Map<String, dynamic>?;
                final senderId = m['senderId'] as String? ?? sender?['id'] as String?;
                final isMe = senderId == _myId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m['message'] as String? ?? '',
                      style: TextStyle(color: isMe ? Colors.white : AppColors.charcoal),
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
