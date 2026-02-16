import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/conversation.dart';
import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import '../widgets/adaptive_page.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);
    final List<Conversation> conversations = _filterConversations(
      state.conversations,
    );

    if (state.conversations.isEmpty) {
      return AdaptivePage(
        child: Center(
          child: Text(
            'No messages yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: AdaptivePage(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          itemCount: conversations.isEmpty ? 3 : conversations.length + 2,
          separatorBuilder: (_, int index) => index <= 1
              ? const SizedBox(height: 10)
              : const Divider(height: 20),
          itemBuilder: (_, int index) {
            if (index == 0) {
              return Row(
                children: <Widget>[
                  Text(
                    'Inbox',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (state.unreadInboxCount > 0)
                    TextButton(
                      onPressed: state.markAllConversationsRead,
                      child: Text(
                        'Mark all read',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              );
            }
            if (index == 1) {
              return Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search host, property, message...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      FilterChip(
                        selected: _unreadOnly,
                        onSelected: (bool value) =>
                            setState(() => _unreadOnly = value),
                        label: const Text('Unread only'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${conversations.length} conversations',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: const Color(0xFF98A2B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            if (conversations.isEmpty && index == 2) {
              return Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No conversations match your search.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final Conversation conversation = conversations[index - 2];
            return InkWell(
              onTap: () {
                state.markConversationRead(conversation.id);
                Navigator.of(context).push(
                  MaterialPageRoute<ChatScreen>(
                    builder: (_) => ChatScreen(conversation: conversation),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(conversation.avatarUrl),
                    onBackgroundImageError: (_, error) {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                conversation.hostName,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _fmtTime(conversation.lastTimestamp),
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conversation.propertyTitle,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                conversation.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: conversation.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: conversation.unreadCount > 0
                                      ? AppColors.textPrimary
                                      : const Color(0xFF667085),
                                ),
                              ),
                            ),
                            if (conversation.unreadCount > 0) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> items) {
    return items
        .where((Conversation conversation) {
          final bool matchesUnread =
              !_unreadOnly || conversation.unreadCount > 0;
          final String haystack =
              '${conversation.hostName} ${conversation.propertyTitle} ${conversation.lastMessage}'
                  .toLowerCase();
          final bool matchesQuery = _query.isEmpty || haystack.contains(_query);
          return matchesUnread && matchesQuery;
        })
        .toList(growable: false);
  }

  String _fmtTime(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}
