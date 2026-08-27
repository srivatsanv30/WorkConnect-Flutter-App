import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'chat_service.dart';
import 'message_service.dart';

class JobChatScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String currentUserId;

  const JobChatScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.currentUserId,
  });
  @override
  State<JobChatScreen> createState() => _JobChatScreenState();
}

class _JobChatScreenState extends State<JobChatScreen> {
  final _chatService = ChatService();
  final _messageService = MessageService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final history = await _messageService.fetchMessages(widget.jobId);
    if (!mounted) return;

    setState(() {
      _messages = history;
      _isLoading = false;
    });

    await _chatService.connect(
      jobId: widget.jobId,
      onMessage: (message) {
        if (!mounted) return;
        setState(() => _messages.add(message));
        _scrollToBottom();
      },
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(widget.jobId, text);
    _textController.clear();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jobTitle, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nSay hello to get started!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final senderId = (msg['sender'] is Map)
                              ? msg['sender']['_id']
                              : msg['sender'];
                          final senderName = (msg['sender'] is Map)
                              ? msg['sender']['name'] ?? 'Unknown'
                              : 'Unknown';
                          final isMe = senderId == widget.currentUserId;

                          return _ChatBubble(
                            text: msg['text'] ?? '',
                            senderName: senderName,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.logoGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _handleSend,
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

class _ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final bool isMe;

  const _ChatBubble({required this.text, required this.senderName, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white70 : AppTheme.primary,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}