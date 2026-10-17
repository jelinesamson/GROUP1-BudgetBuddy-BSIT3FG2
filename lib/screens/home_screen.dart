import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import 'budget_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenBudget});

  final VoidCallback onOpenBudget;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: scheme.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text('BudgetBuddy'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Log out',
              onPressed: () => AuthService().logout(),
              icon: const Icon(Icons.logout_rounded),
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final storedName = snapshot.data?.data()?['name'];
          final profileName = storedName is String ? storedName.trim() : '';
          final authName = user.displayName?.trim() ?? '';
          final emailName = user.email?.split('@').first.trim() ?? '';
          final name = profileName.isNotEmpty
              ? profileName
              : authName.isNotEmpty
              ? authName
              : emailName.isNotEmpty
              ? emailName
              : 'User';
          final firstName = name.split(RegExp(r'\s+')).first;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8,
                      bottom: -12,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 106,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'YOUR MONEY, YOUR PLAN',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.05,
                                ),
                              ),
                            ),
                            const Spacer(),
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          _greeting(),
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Small steps today, better money habits tomorrow.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget at a glance',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your planned spending limits · tap to edit',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BudgetOverviewCard(onTap: onOpenBudget),
              const SizedBox(height: 26),
              Text(
                'Quick actions',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_card_rounded,
                      label: 'Add expense',
                      color: scheme.secondaryContainer,
                      onColor: scheme.onSecondaryContainer,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'History',
                      color: scheme.tertiaryContainer,
                      onColor: scheme.onTertiaryContainer,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.savings_rounded,
                      label: 'Savings',
                      color: scheme.surfaceContainerHighest,
                      onColor: scheme.onSurface,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A little reminder',
                            style: textTheme.titleSmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A budget is a guide, not a judgment. Adjust your limits whenever life changes.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: onColor, size: 23),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetOverviewCard extends StatefulWidget {
  const _BudgetOverviewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BudgetOverviewCard> createState() => _BudgetOverviewCardState();
}

class _BudgetOverviewCardState extends State<_BudgetOverviewCard> {
  late final Stream<Budget> _budgetStream = BudgetService().budgetStream();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<Budget>(
      stream: _budgetStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not load your budget. Check your connection and try again.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final budget = snapshot.data;
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            budget == null;
        final hasMonthlyLimit = budget?.monthly != null;

        return Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Monthly limit',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (isLoading)
                    const SizedBox(
                      height: 38,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (!hasMonthlyLimit)
                    Text(
                      'Set your first monthly limit',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Text(
                      formatPeso(budget!.monthly!),
                      style: textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _LimitValue(
                          label: 'Weekly',
                          value: budget?.weekly,
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: scheme.outlineVariant,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _LimitValue(
                            label: 'Daily',
                            value: budget?.daily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LimitValue extends StatelessWidget {
  const _LimitValue({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value == null ? 'Not set' : formatPeso(value!),
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
