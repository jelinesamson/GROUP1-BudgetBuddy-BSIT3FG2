import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../models/budget.dart';

import '../services/budget_service.dart';

// ---------------------------------------------------------------------------

// Helpers

// ---------------------------------------------------------------------------

/// 1500 -> "₱1,500" , 1500.5 -> "₱1,500.50"

String formatPeso(double value) {
  final isWhole = value == value.roundToDouble();

  final parts = value.toStringAsFixed(isWhole ? 0 : 2).split('.');

  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),

    (m) => ',',
  );

  return '₱$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

enum BudgetPeriod {
  daily('Daily', 'per day', Icons.today_rounded, Color(0xFFF57C00), [
    50,
    100,
    200,
    500,
  ]),

  weekly('Weekly', 'per week', Icons.date_range_rounded, Color(0xFF1E88E5), [
    500,
    1000,
    1500,
    2000,
  ]),

  monthly(
    'Monthly',
    'per month',
    Icons.calendar_month_rounded,

    Color(0xFF176B52),
    [2000, 3000, 5000, 10000],
  );

  final String label;

  final String unit;

  final IconData icon;

  final Color color;

  final List<int> quickAmounts;

  const BudgetPeriod(
    this.label,
    this.unit,
    this.icon,
    this.color,
    this.quickAmounts,
  );

  double? valueOf(Budget b) {
    switch (this) {
      case BudgetPeriod.daily:
        return b.daily;

      case BudgetPeriod.weekly:
        return b.weekly;

      case BudgetPeriod.monthly:
        return b.monthly;
    }
  }

  /// Returns a copy of [b] with this period set to [value] (null = removed).

  Budget apply(Budget b, double? value) {
    switch (this) {
      case BudgetPeriod.daily:
        return Budget(daily: value, weekly: b.weekly, monthly: b.monthly);

      case BudgetPeriod.weekly:
        return Budget(daily: b.daily, weekly: value, monthly: b.monthly);

      case BudgetPeriod.monthly:
        return Budget(daily: b.daily, weekly: b.weekly, monthly: value);
    }
  }
}

// ---------------------------------------------------------------------------

// Screen

// ---------------------------------------------------------------------------

/// Shows the student's daily, weekly and monthly budget as cards.

/// Tap a card to set or edit it.

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();

  late final Stream<Budget> _stream = _budgetService.budgetStream();

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _openEditor(Budget current, BudgetPeriod period) {
    return showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      useSafeArea: true,

      showDragHandle: false,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      builder: (_) => _EditSheet(
        period: period,

        initial: period.valueOf(current),

        onSave: (value) async {
          final error = await _budgetService.saveBudget(
            period.apply(current, value),
          );

          if (error == null && mounted) {
            _snack(
              value == null
                  ? '${period.label} budget removed.'
                  : '${period.label} budget saved!',
            );
          }

          return error;
        },
      ),
    );
  }

  // Suggest daily & weekly from the monthly amount.

  Future<void> _autoFill(Budget current) async {
    final monthly = current.monthly;

    if (monthly == null || monthly <= 0) {
      _snack('Set a monthly budget first.');

      return;
    }

    final daily = double.parse((monthly / 30).toStringAsFixed(2));

    final weekly = double.parse((monthly / 30 * 7).toStringAsFixed(2));

    final error = await _budgetService.saveBudget(
      Budget(daily: daily, weekly: weekly, monthly: monthly),
    );

    if (mounted) {
      _snack(error ?? 'Daily and weekly filled from your monthly budget.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Budget>(
          stream: _stream,

          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Icon(
                        Icons.cloud_off_rounded,

                        size: 48,
                        color: scheme.error,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Could not load your budget.\nCheck your connection and Firestore rules.',

                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Budget budget) {
    final scheme = Theme.of(context).colorScheme;

    final textTheme = Theme.of(context).textTheme;
    final configuredLimits = [
      budget.monthly,
      budget.weekly,
      budget.daily,
    ].whereType<double>().length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your budget',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Set simple limits for your spending.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    '$configuredLimits',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'OF 3',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: configuredLimits / 3,
            minHeight: 5,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 25),
        _HeroCard(
          value: budget.monthly,
          onTap: () => _openEditor(budget, BudgetPeriod.monthly),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Short-term limits',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Icon(Icons.touch_app_outlined, color: scheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a card to set or edit your limit.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        _PeriodBox(
          period: BudgetPeriod.weekly,
          value: budget.weekly,
          onTap: () => _openEditor(budget, BudgetPeriod.weekly),
        ),
        const SizedBox(height: 10),
        _PeriodBox(
          period: BudgetPeriod.daily,
          value: budget.daily,
          onTap: () => _openEditor(budget, BudgetPeriod.daily),
        ),

        // Insight: do daily / weekly limits fit inside the monthly one?
        if (budget.monthly != null &&
            (budget.daily != null || budget.weekly != null)) ...[
          const SizedBox(height: 14),

          _InsightCard(budget: budget),
        ],

        const SizedBox(height: 22),

        // Auto-fill tip
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.58),

          borderRadius: BorderRadius.circular(22),

          child: InkWell(
            borderRadius: BorderRadius.circular(22),

            onTap: () => _autoFill(budget),

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.75),

                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: scheme.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Auto-fill from monthly',
                          style: textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Calculates your daily and weekly limits for you.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

// Cards

// ---------------------------------------------------------------------------

/// Big green card for the monthly budget.

class _HeroCard extends StatelessWidget {
  final double? value;

  final VoidCallback onTap;

  const _HeroCard({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(28),

          onTap: onTap,

          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: 12,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 142,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'MONTHLY LIMIT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Icon(
                          isSet ? Icons.edit_outlined : Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isSet ? formatPeso(value!) : 'Set your limit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSet ? 40 : 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isSet
                          ? 'Your plan for the month · tap to update'
                          : 'Start with a monthly spending plan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width row for the weekly / daily budget.

class _PeriodBox extends StatelessWidget {
  final BudgetPeriod period;

  final double? value;

  final VoidCallback onTap;

  const _PeriodBox({
    required this.period,

    required this.value,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isSet = value != null;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSet
              ? period.color.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: period.color),
              const SizedBox(width: 14),
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: period.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(period.icon, color: period.color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${period.label} limit',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSet ? formatPeso(value!) : 'Not set',
                        style: TextStyle(
                          color: isSet
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant.withValues(alpha: 0.65),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSet ? period.unit : 'Set limit',
                      style: TextStyle(
                        color: period.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isSet ? Icons.edit_outlined : Icons.add_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small card that checks if daily / weekly limits fit inside the monthly one.

class _InsightCard extends StatelessWidget {
  final Budget budget;

  const _InsightCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final monthly = budget.monthly!;

    // Estimated monthly totals if the person spends the full daily / weekly limit.

    final fromDaily = budget.daily == null ? null : budget.daily! * 30;

    final fromWeekly = budget.weekly == null ? null : budget.weekly! * 4.3;

    final highest = [
      fromDaily,
      fromWeekly,
    ].whereType<double>().reduce((a, b) => a > b ? a : b);

    final overBudget = highest > monthly * 1.02; // small tolerance

    final color = overBudget ? scheme.error : const Color(0xFF43A047);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),

      child: Row(
        children: [
          Icon(
            overBudget
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,

            color: color,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              overBudget
                  ? 'Heads up: spending your full daily/weekly limit would reach about ${formatPeso(highest)} a month, above your ${formatPeso(monthly)} budget.'
                  : 'Looking good: your daily and weekly limits fit within your monthly budget.',

              style: TextStyle(
                fontSize: 13,

                height: 1.35,

                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// Edit bottom sheet

// ---------------------------------------------------------------------------

class _EditSheet extends StatefulWidget {
  final BudgetPeriod period;

  final double? initial;

  /// Saves the value (null = remove). Returns null on success or an error text.

  final Future<String?> Function(double? value) onSave;

  const _EditSheet({
    required this.period,

    required this.initial,

    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    final v = widget.initial;

    _controller = TextEditingController(
      text: v == null
          ? ''
          : (v == v.roundToDouble()
                ? v.toInt().toString()
                : v.toStringAsFixed(2)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _submit(double? value) async {
    setState(() {
      _saving = true;

      _error = null;
    });

    final error = await widget.onSave(value);

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;

        _error = error;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    _submit(double.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final period = widget.period;

    final color = period.color;

    return Padding(
      // Lifts the sheet above the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),

      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),

        child: Form(
          key: _formKey,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,

                  height: 4,

                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,

                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(period.icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${period.label} budget',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose a comfortable limit ${period.unit}.',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                'Limit amount',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,

                autofocus: true,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],

                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),

                decoration: InputDecoration(
                  hintText: '0.00',

                  prefixText: '₱ ',

                  prefixStyle: TextStyle(
                    fontSize: 30,

                    fontWeight: FontWeight.bold,

                    color: color,
                  ),

                  filled: true,

                  fillColor: color.withValues(alpha: 0.08),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),

                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),

                    borderSide: BorderSide(color: color, width: 1.5),
                  ),

                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),

                    borderSide: BorderSide(color: scheme.error),
                  ),

                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),

                    borderSide: BorderSide(color: scheme.error, width: 1.5),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }

                  final n = double.tryParse(value.trim());

                  if (n == null) return 'Enter a valid number';

                  if (n <= 0) return 'Amount must be more than 0';

                  return null;
                },
              ),

              const SizedBox(height: 14),

              Text(
                'Quick picks',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in period.quickAmounts)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: color,
                        side: BorderSide(color: color.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(formatPeso(amount.toDouble())),
                      onPressed: () {
                        setState(() => _controller.text = amount.toString());
                      },
                    ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),

                Text(_error!, style: TextStyle(color: scheme.error)),
              ],

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,

                height: 54,

                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: color,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  onPressed: _saving ? null : _save,

                  child: _saving
                      ? const SizedBox(
                          height: 22,

                          width: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,

                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              if (widget.initial != null) ...[
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,

                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: scheme.error),

                    onPressed: _saving ? null : () => _submit(null),

                    child: Text('Remove ${period.label.toLowerCase()} budget'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
