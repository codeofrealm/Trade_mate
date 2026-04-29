import 'admin_user_order.dart';

class AdminCustomer {
  AdminCustomer({
    required this.userId,
    required this.orders,
    required this.totalSpent,
  });

  final String userId;
  final List<AdminUserOrder> orders;
  double totalSpent;

  String get shortUserId {
    if (userId.length <= 12) return userId;
    return '${userId.substring(0, 8)}...${userId.substring(userId.length - 4)}';
  }
}
