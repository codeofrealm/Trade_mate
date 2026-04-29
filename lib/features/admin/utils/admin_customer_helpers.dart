import 'package:flutter/material.dart';

Color adminStatusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'delivered':
      return const Color(0xFF34C759);
    case 'cancelled':
    case 'canceled':
      return const Color(0xFFFF3B30);
    case 'shipped':
      return const Color(0xFF007AFF);
    case 'processing':
    case 'packed':
      return const Color(0xFFFF9500);
    default:
      return const Color(0xFF5856D6);
  }
}

String formatRs(double amount) {
  if (amount >= 100000) return 'Rs ${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

String timeLabel(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
