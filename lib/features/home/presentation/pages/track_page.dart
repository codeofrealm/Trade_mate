import 'package:flutter/cupertino.dart';

import '../widgets/luxury_ui.dart';

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    const timeline = [
      ('Order Placed', '10:12 AM'),
      ('Payment Confirmed', '10:15 AM'),
      ('Broker Executed', '10:16 AM'),
      ('Position Active', 'Live'),
    ];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: LuxuryColors.backgroundBottom.withValues(alpha: 0.38),
        border: null,
        middle: const Text('Tracking'),
      ),
      child: LuxuryBackground(
        child: SafeArea(
          child: ListView(
            padding: LuxuryInsets.page,
            children: [
              const LuxurySectionTitle(
                'Order Journey',
                subtitle: 'Follow each order status update in real-time.',
              ),
              LuxuryGlassCard(
                tint: LuxuryColors.gold.withValues(alpha: 0.14),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: LuxuryColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ticket: TM-2048',
                      style: TextStyle(
                        color: LuxuryColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              LuxuryInsets.sectionGap,
              ...timeline.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LuxuryGlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: step.$2 == 'Live'
                                ? LuxuryColors.gold
                                : CupertinoColors.activeBlue.withValues(
                                    alpha: 0.24,
                                  ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            step.$2 == 'Live'
                                ? CupertinoIcons.clock_fill
                                : CupertinoIcons.checkmark_alt,
                            size: 13,
                            color: step.$2 == 'Live'
                                ? LuxuryColors.backgroundBottom
                                : CupertinoColors.activeBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.$1,
                            style: const TextStyle(
                              color: LuxuryColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          step.$2,
                          style: const TextStyle(
                            color: LuxuryColors.textSoft,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
