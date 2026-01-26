import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/services/withdrawal_service.dart';
import 'package:walkmypet/services/stripe_connect_service.dart';

/// Screen for walkers to request withdrawal of their earnings via Stripe
class WithdrawalRequestScreen extends StatefulWidget {
  final String walkerId;

  const WithdrawalRequestScreen({
    super.key,
    required this.walkerId,
  });

  @override
  State<WithdrawalRequestScreen> createState() => _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final StripeConnectService _stripeConnectService = StripeConnectService();

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  double _availableBalance = 0.0;
  bool _isStripeReady = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load balance and Stripe status in parallel
    final results = await Future.wait([
      _withdrawalService.getAvailableBalance(widget.walkerId),
      _stripeConnectService.isReadyForPayouts(),
    ]);

    if (mounted) {
      setState(() {
        _availableBalance = results[0] as double;
        _isStripeReady = results[1] as bool;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DesignSystem.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: DesignSystem.getBackground(isDark),
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(DesignSystem.space1),
          decoration: BoxDecoration(
            color: DesignSystem.getSurface(isDark),
            shape: BoxShape.circle,
            border: Border.all(
              color: DesignSystem.getBorderColor(isDark),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: DesignSystem.getTextPrimary(isDark),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Request Withdrawal',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(DesignSystem.space2),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvailableBalanceCard(isDark),
                SizedBox(height: DesignSystem.space3),
                _buildInformationBanner(isDark),
                SizedBox(height: DesignSystem.space4),
                _buildAmountField(isDark),
                SizedBox(height: DesignSystem.space3),
                _buildQuickAmountButtons(isDark),
                SizedBox(height: DesignSystem.space3),
                _buildNotesField(isDark),
                SizedBox(height: DesignSystem.space4),
                _buildSubmitButton(isDark),
                SizedBox(height: DesignSystem.space3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableBalanceCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space3),
      decoration: BoxDecoration(
        gradient: DesignSystem.successGradient,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available for Withdrawal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: DesignSystem.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isStripeReady)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignSystem.space1,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Stripe Ready',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: DesignSystem.small,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            '\$${_availableBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: DesignSystem.walkerPrimary,
                size: 18,
              ),
              SizedBox(width: DesignSystem.space1),
              Text(
                'Instant Stripe Payouts',
                style: TextStyle(
                  color: DesignSystem.walkerPrimary,
                  fontSize: DesignSystem.bodySmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            '• Funds are transferred instantly to your connected bank account\n'
            '• No additional fees - we cover Stripe processing costs\n'
            '• Minimum withdrawal amount is \$${WithdrawalService.minimumWithdrawalAmount.toStringAsFixed(2)}\n'
            '• Typically arrives in 1-2 business days',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.small,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal Amount',
          style: TextStyle(
            fontSize: DesignSystem.bodySmall,
            fontWeight: FontWeight.w600,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        SizedBox(height: DesignSystem.space1),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              color: DesignSystem.getTextPrimary(isDark),
              fontSize: DesignSystem.h2,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: DesignSystem.getSurface(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.getBorderColor(isDark),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.getBorderColor(isDark),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.success,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w700,
            color: DesignSystem.getTextPrimary(isDark),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid amount';
            }
            if (amount < WithdrawalService.minimumWithdrawalAmount) {
              return 'Minimum withdrawal is \$${WithdrawalService.minimumWithdrawalAmount.toStringAsFixed(2)}';
            }
            if (amount > _availableBalance) {
              return 'Insufficient balance';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountButtons(bool isDark) {
    final amounts = [25.0, 50.0, 100.0];
    // Add "All" option if balance is significant
    final showAll = _availableBalance >= WithdrawalService.minimumWithdrawalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: TextStyle(
            fontSize: DesignSystem.small,
            fontWeight: FontWeight.w600,
            color: DesignSystem.getTextSecondary(isDark),
          ),
        ),
        SizedBox(height: DesignSystem.space1),
        Wrap(
          spacing: DesignSystem.space1,
          runSpacing: DesignSystem.space1,
          children: [
            ...amounts
                .where((a) => a <= _availableBalance)
                .map((amount) => _buildQuickAmountChip(amount, isDark)),
            if (showAll)
              _buildQuickAmountChip(_availableBalance, isDark, label: 'All'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(double amount, bool isDark, {String? label}) {
    return ActionChip(
      label: Text(label ?? '\$${amount.toStringAsFixed(0)}'),
      labelStyle: TextStyle(
        color: DesignSystem.walkerPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: DesignSystem.walkerPrimary.withValues(alpha: 0.1),
      side: BorderSide(
        color: DesignSystem.walkerPrimary.withValues(alpha: 0.3),
      ),
      onPressed: () {
        _amountController.text = amount.toStringAsFixed(2);
      },
    );
  }

  Widget _buildNotesField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: DesignSystem.bodySmall,
            fontWeight: FontWeight.w600,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
        SizedBox(height: DesignSystem.space1),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Any notes for this withdrawal...',
            filled: true,
            fillColor: DesignSystem.getSurface(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.getBorderColor(isDark),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.getBorderColor(isDark),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              borderSide: BorderSide(
                color: DesignSystem.success,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitWithdrawalRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          elevation: 8,
          shadowColor: DesignSystem.success.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, size: 20),
                  SizedBox(width: DesignSystem.space1_5),
                  Text(
                    'Withdraw Now',
                    style: TextStyle(
                      fontSize: DesignSystem.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitWithdrawalRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      final notes = _notesController.text.trim();

      // Use the new Stripe-based withdrawal
      await _withdrawalService.requestWithdrawalWithStripePayout(
        walkerId: widget.walkerId,
        amount: amount,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: DesignSystem.space1),
                Expanded(
                  child: Text(
                    'Withdrawal processed! Funds will arrive in 1-2 business days.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: DesignSystem.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            ),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Go back to wallet screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                SizedBox(width: DesignSystem.space1),
                Expanded(
                  child: Text(
                    'Failed: ${e.toString().replaceAll('Exception: ', '')}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
