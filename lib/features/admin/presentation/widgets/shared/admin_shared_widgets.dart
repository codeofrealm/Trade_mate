import 'package:flutter/material.dart';

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3),
        ),
      );
}

class AdminInfoCard extends StatelessWidget {
  const AdminInfoCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow(
      {super.key, required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 13)),
            ),
            Text(value,
                style: TextStyle(
                    color: const Color(0xFF000000),
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      );
}

class AdminMiniStat extends StatelessWidget {
  const AdminMiniStat(
      {super.key, required this.label, required this.value, required this.color, this.fontSize = 16});
  final String label;
  final String value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class AdminVertDivider extends StatelessWidget {
  const AdminVertDivider({super.key, this.height = 24});
  final double height;

  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: height, color: const Color(0xFFE5E5EA));
}
