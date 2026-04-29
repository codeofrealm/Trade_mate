import 'package:flutter/material.dart';
import '../data/models/home_user_order.dart';

String homeFormatRs(double amount) {
  if (amount >= 100000) return 'Rs ${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

String homeCompactAmount(double amount) {
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}

String homeTimeAgo(DateTime? value) {
  if (value == null) return 'date not available';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
  if (diff.inDays < 1) return '${diff.inHours} hours ago';
  if (diff.inDays == 1) return '1 day ago';
  return '${diff.inDays} days ago';
}

String homeCompactDate(DateTime value) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String homeFullDate(DateTime? value) {
  if (value == null) return 'Unknown date';
  const months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  return '${value.day} ${months[value.month - 1]}, ${value.year}';
}

String homeFormatDate(DateTime? dt) {
  if (dt == null) return 'Unknown';
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String homeShortId(String value) {
  final clean = value.trim();
  if (clean.length <= 10) return clean;
  return '${clean.substring(0, 6)}...${clean.substring(clean.length - 4)}';
}

Color homeOrderStatusColor(HomeUserOrder order) {
  if (order.isCancelled) return const Color(0xFFB91C1C);
  if (order.isDelivered) return const Color(0xFF15803D);
  switch (order.cleanStatus) {
    case 'shipped':
    case 'out_for_delivery':
    case 'out for delivery':
      return const Color(0xFF1D4ED8);
    case 'processing':
    case 'packed':
    case 'confirmed':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF2563EB);
  }
}

Color homeAnalyticsStatusColor(String status) {
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
