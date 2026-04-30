import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../data/models/home_user_order.dart';

class HomeNotificationsPage extends StatefulWidget {
  const HomeNotificationsPage({super.key});

  @override
  State<HomeNotificationsPage> createState() => _HomeNotificationsPageState();
}

class _HomeNotificationsPageState extends State<HomeNotificationsPage> {
  final Set<String> _selected = {};
  bool _isSelecting = false;

  void _onLongPress(String id) {
    setState(() {
      _isSelecting = true;
      _selected.add(id);
    });
  }

  void _onTap(String id, HomeUserOrder order) {
    if (_isSelecting) {
      setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
          if (_selected.isEmpty) _isSelecting = false;
        } else {
          _selected.add(id);
        }
      });
    } else {
      Navigator.of(context).pushNamed(AppRoutes.orderDetails, arguments: order);
    }
  }

  void _cancelSelection() {
    setState(() {
      _selected.clear();
      _isSelecting = false;
    });
  }

  void _showDeleteConfirm() {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
            'Delete ${_selected.length} selected notification${_selected.length > 1 ? 's' : ''}?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelected();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final ids = List<String>.from(_selected);
    setState(() {
      _selected.clear();
      _isSelecting = false;
    });
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.delete(FirebaseFirestore.instance.collection('orders').doc(id));
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: _isSelecting
            ? Text('${_selected.length} Selected',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000)))
            : const Text('Notifications',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000))),
        leading: _isSelecting
            ? TextButton(
                onPressed: _cancelSelection,
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Color(0xFF007AFF), fontSize: 15)),
              )
            : null,
        actions: [
          if (_isSelecting)
            IconButton(
              onPressed: _selected.isNotEmpty ? _showDeleteConfirm : null,
              icon: Icon(
                CupertinoIcons.trash,
                color: _selected.isNotEmpty
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFFC7C7CC),
                size: 20,
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Please login.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CupertinoActivityIndicator());
                }

                final orders = snap.data!.docs
                    .map((d) => HomeUserOrder.fromFirestore(d.id, d.data()))
                    .where((o) => o.isDelivered || o.isCancelled)
                    .toList()
                  ..sort((a, b) =>
                      (b.updatedAt ?? b.createdAt ?? DateTime(0))
                          .compareTo(
                              a.updatedAt ?? a.createdAt ?? DateTime(0)));

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E5EA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.bell_slash,
                            color: Color(0xFF8E8E93),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF000000)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Delivered and cancelled orders\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF8E8E93), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isSelected = _selected.contains(order.id);
                    return _NotifCard(
                      order: order,
                      isSelecting: _isSelecting,
                      isSelected: isSelected,
                      onTap: () => _onTap(order.id, order),
                      onLongPress: () => _onLongPress(order.id),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.order,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final HomeUserOrder order;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.isDelivered;
    final color =
        isDelivered ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
    final icon =
        isDelivered ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill;
    final title = isDelivered ? 'Order Delivered' : 'Order Cancelled';
    final subtitle = order.productName.isEmpty
        ? 'Your order has been ${isDelivered ? 'delivered' : 'cancelled'}.'
        : '${order.productName} has been ${isDelivered ? 'delivered successfully' : 'cancelled'}.';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF007AFF).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF007AFF)
                : const Color(0xFFE5E5EA),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // selection circle or icon
            if (isSelecting)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFC7C7CC),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(CupertinoIcons.checkmark,
                          size: 13, color: Colors.white)
                      : null,
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF000000)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rs ${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_timeAgo(order.updatedAt ?? order.createdAt)}',
                        style: const TextStyle(
                            color: Color(0xFFC7C7CC), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelecting)
              const Icon(CupertinoIcons.chevron_right,
                  color: Color(0xFFC7C7CC), size: 16),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return '1 day ago';
  return '${diff.inDays} days ago';
}
