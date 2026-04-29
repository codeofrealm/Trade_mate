import 'package:flutter/material.dart';

import '../../../data/models/admin_support_chat.dart';
import '../../../data/services/admin_catalog_service.dart';

class AdminChatsTab extends StatelessWidget {
  const AdminChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminSupportChat>>(
      stream: AdminCatalogService.instance.streamChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load chats.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!;
        if (chats.isEmpty) {
          return const Center(
            child: Text(
              'No support chats yet.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ChatCard(chat: chats[index]),
        );
      },
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.chat});

  final AdminSupportChat chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE2E8F0),
            child: Text(
              _avatarLetter(chat.userName),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.userName.isEmpty ? 'Unknown user' : chat.userName,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      _timeLabel(chat.updatedAt),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  chat.lastMessage.isEmpty
                      ? 'No message preview.'
                      : chat.lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ChatStatusChip(isOpen: chat.isOpen),
              if (chat.unreadCount > 0) ...[
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFDC2626),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatStatusChip extends StatelessWidget {
  const _ChatStatusChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final background = isOpen
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFE2E8F0);
    final color = isOpen ? const Color(0xFF166534) : const Color(0xFF334155);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

String _timeLabel(DateTime? time) {
  if (time == null) {
    return 'Unknown';
  }

  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) {
    return 'Now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h';
  }
  return '${diff.inDays}d';
}

String _avatarLetter(String userName) {
  final clean = userName.trim();
  if (clean.isEmpty) {
    return 'U';
  }
  return clean[0].toUpperCase();
}
