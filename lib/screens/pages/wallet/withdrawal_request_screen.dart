import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/services/withdrawal_service.dart';

/// Screen for walkers to request withdrawal of their earnings
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

  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bsbController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAvailableBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _bsbController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableBalance() async {
    final balance = await _withdrawalService.getAvailableBalance(widget.walkerId);
    setState(() {
      _availableBalance = balance;
    });
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
                _buildSectionTitle('Bank Account Details', isDark),
                SizedBox(height: DesignSystem.space2),
                _buildAccountNameField(isDark),
                SizedBox(height: DesignSystem.space2),
                _buildBSBField(isDark),
                SizedBox(height: DesignSystem.space2),
                _buildAccountNumberField(isDark),
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
          Text(
            'Available for Withdrawal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: DesignSystem.body,
              fontWeight: FontWeight.w600,
            ),
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
                Icons.info_rounded,
                color: DesignSystem.walkerPrimary,
                size: 18,
              ),
              SizedBox(width: DesignSystem.space1),
              Text(
                'Processing Information',
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
            '• Withdrawals are processed manually within 1-2 business days\n'
            '• A \$${WithdrawalService.processingFee.toStringAsFixed(2)} processing fee will be deducted\n'
            '• Minimum withdrawal amount is \$${WithdrawalService.minimumWithdrawalAmount.toStringAsFixed(2)}',
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: DesignSystem.h3,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: DesignSystem.getTextPrimary(isDark),
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

  Widget _buildAccountNameField(bool isDark) {
    return TextFormField(
      controller: _accountNameController,
      textCapitalization: TextCapitalization.words,
      decoration: _buildInputDecoration(
        'Account Holder Name',
        'John Smith',
        Icons.person_rounded,
        isDark,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Account name is required';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildBSBField(bool isDark) {
    return TextFormField(
      controller: _bsbController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
        _BSBFormatter(),
      ],
      decoration: _buildInputDecoration(
        'BSB',
        '123-456',
        Icons.account_balance_rounded,
        isDark,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'BSB is required';
        }
        if (!WithdrawalService.isValidBSB(value)) {
          return 'BSB must be 6 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAccountNumberField(bool isDark) {
    return TextFormField(
      controller: _accountNumberController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: _buildInputDecoration(
        'Account Number',
        '123456789',
        Icons.numbers_rounded,
        isDark,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Account number is required';
        }
        if (!WithdrawalService.isValidAccountNumber(value)) {
          return 'Account number must be 6-9 digits';
        }
        return null;
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
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special instructions...',
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

  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: DesignSystem.getTextSecondary(isDark)),
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
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: DesignSystem.space1_5),
                  Text(
                    'Submit Request',
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
      final accountName = _accountNameController.text.trim();
      final bsb = _bsbController.text;
      final accountNumber = _accountNumberController.text;
      final notes = _notesController.text.trim();

      await _withdrawalService.requestWithdrawal(
        walkerId: widget.walkerId,
        amount: amount,
        accountName: accountName,
        accountNumber: accountNumber,
        bsb: bsb,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request submitted successfully!'),
            backgroundColor: DesignSystem.success,
          ),
        );
        Navigator.pop(context); // Go back to wallet screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: const Color(0xFFEF4444),
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

/// Text input formatter for BSB (XXX-XXX format)
class _BSBFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 6) {
      return oldValue;
    }

    String formatted = text;
    if (text.length > 3) {
      formatted = '${text.substring(0, 3)}-${text.substring(3)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
