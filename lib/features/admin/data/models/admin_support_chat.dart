import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportChat {
  const AdminSupportChat({
    required this.id,
    required this.userName,
    required this.lastMessage,
    required this.unreadCount,
    required this.isOpen,
    this.updatedAt,
  });

  final String id;
  final String userName;
  final String lastMessage;
  final int unreadCount;
  final bool isOpen;
  final DateTime? updatedAt;

  factory AdminSupportChat.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['updatedAt'];
    return AdminSupportChat(
      id: id,
      userName: (data['userName'] ?? '').toString(),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      unreadCount: (data['unreadCount'] is num)
          ? (data['unreadCount'] as num).toInt()
          : int.tryParse(data['unreadCount']?.toString() ?? '') ?? 0,
      isOpen: data['isOpen'] != false,
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
