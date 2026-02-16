import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/conversation.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _controller;
  late final List<_ChatBubbleData> _messages;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _messages = <_ChatBubbleData>[
      _ChatBubbleData(
        text: 'Hi, I am ${widget.conversation.hostName}. Welcome to NovaHomes.',
        isMe: false,
      ),
      _ChatBubbleData(text: widget.conversation.lastMessage, isMe: false),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 17,
              backgroundImage: NetworkImage(widget.conversation.avatarUrl),
              onBackgroundImageError: (_, error) {},
              child: const SizedBox.shrink(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.conversation.hostName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              itemCount: _messages.length,
              separatorBuilder: (_, int index) => const SizedBox(height: 10),
              itemBuilder: (_, int index) {
                final _ChatBubbleData message = _messages[index];
                return Align(
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? const Color(0xFF0B163A)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.text,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: message.isMe
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Write a message',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final String text = _controller.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _messages.add(_ChatBubbleData(text: text, isMe: true));
                      });
                      state.sendMessage(
                        conversationId: widget.conversation.id,
                        text: text,
                      );
                      _controller.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.accent,
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

class _ChatBubbleData {
  const _ChatBubbleData({required this.text, required this.isMe});

  final String text;
  final bool isMe;
}
