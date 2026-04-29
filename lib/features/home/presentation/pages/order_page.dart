import 'package:flutter/cupertino.dart';

import '../widgets/luxury_ui.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    const orders = [
      ('EUR/USD', 'Buy', '0.30 Lot', '2m ago', '1.08412'),
      ('BTC/USDT', 'Sell', '0.12 Lot', '15m ago', '64,102.20'),
      ('AAPL', 'Buy', '5 Shares', '1h ago', '186.43'),
    ];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: LuxuryColors.backgroundBottom.withValues(alpha: 0.38),
        border: null,
        middle: const Text('Orders'),
      ),
      child: LuxuryBackground(
        child: SafeArea(
          child: ListView(
            padding: LuxuryInsets.page,
            children: [
              const LuxurySectionTitle(
                'Open Orders',
                subtitle: 'Review active orders and latest execution price.',
              ),
              LuxuryGlassCard(
                tint: LuxuryColors.gold.withValues(alpha: 0.13),
                child: Row(
                  children: const [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: LuxuryColors.gold,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '3 active orders • all synced successfully',
                        style: TextStyle(
                          color: LuxuryColors.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LuxuryInsets.sectionGap,
              ...orders.map((order) {
                final isBuy = order.$2 == 'Buy';
                final signalColor = isBuy
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.destructiveRed;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LuxuryGlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: signalColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            isBuy
                                ? CupertinoIcons.arrow_up_right
                                : CupertinoIcons.arrow_down_right,
                            color: signalColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${order.$1} • ${order.$2}',
                                style: const TextStyle(
                                  color: LuxuryColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${order.$3} • ${order.$4}',
                                style: const TextStyle(
                                  color: LuxuryColors.textSoft,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order.$5,
                          style: const TextStyle(
                            color: LuxuryColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
