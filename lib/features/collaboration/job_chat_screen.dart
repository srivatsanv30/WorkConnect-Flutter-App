import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'chat_service.dart';
import 'message_service.dart';

class JobChatScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String currentUserId;
  final String? recipientName;

  const JobChatScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.currentUserId,
    this.recipientName,
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
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    
    String? base64Image;
    if (_selectedImage != null) {
      final bytes = _selectedImage!.readAsBytesSync();
      base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    _chatService.sendMessage(widget.jobId, text, imageUrl: base64Image);
    _textController.clear();
    _clearImage();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Workspace Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.notifications_off_outlined),
                title: Text('Mute Notifications'),
                trailing: Switch(value: false, onChanged: (val) {}),
              ),
              ListTile(
                leading: Icon(Icons.folder_shared_outlined),
                title: Text('Shared Files'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName != null ? widget.recipientName! : widget.jobTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.recipientName != null)
              Text(
                widget.jobTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: _showSettings,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSay hello to get started!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
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
                            imageUrl: msg['imageUrl'],
                            senderName: senderName,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, height: 60, width: 60, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: _clearImage,
                          child: Container(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                            child: Icon(Icons.close, color: Theme.of(context).cardColor, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(width: 12),
                  const Expanded(child: Text('Image attached', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined, color: AppTheme.primary),
                    onPressed: _pickImage,
                  ),
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
                  SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.logoGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).cardColor, size: 20),
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
  final String? imageUrl;
  final String senderName;
  final bool isMe;

  const _ChatBubble({required this.text, this.imageUrl, required this.senderName, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primary
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : const Color(0xFFF2F2F7)),
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
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(imageUrl!.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}