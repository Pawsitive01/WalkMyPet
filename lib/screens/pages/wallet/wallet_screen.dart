import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkmypet/design_system.dart';
import 'package:walkmypet/services/payment_service.dart';
import 'package:walkmypet/services/withdrawal_service.dart';
import 'package:walkmypet/services/stripe_connect_service.dart';
import 'package:walkmypet/services/user_service.dart';
import 'package:walkmypet/models/transaction_model.dart';
import 'package:walkmypet/models/withdrawal_request_model.dart';
import 'package:walkmypet/screens/pages/wallet/withdrawal_request_screen.dart';

/// Wallet screen for walkers to view balance, earnings, and transaction history
class WalletScreen extends StatefulWidget {
  final String walkerId;

  const WalletScreen({
    super.key,
    required this.walkerId,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentService _paymentService = PaymentService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final StripeConnectService _stripeConnectService = StripeConnectService();
  final UserService _userService = UserService();

  StripeConnectResult? _stripeAccountStatus;
  bool _isLoadingStripeStatus = true;
  bool _isSettingUpStripe = false;

  @override
  void initState() {
    super.initState();
    _loadStripeAccountStatus();
  }

  Future<void> _loadStripeAccountStatus() async {
    setState(() => _isLoadingStripeStatus = true);
    try {
      final result = await _stripeConnectService.getAccountStatus();
      if (mounted) {
        setState(() {
          _stripeAccountStatus = result;
          _isLoadingStripeStatus = false;
        });
      }
    } catch (e) {
      // Error handled silently
      if (mounted) {
        setState(() => _isLoadingStripeStatus = false);
      }
    }
  }

  Future<void> _setupStripeAccount() async {
    setState(() => _isSettingUpStripe = true);
    try {
      // First, create the connected account if it doesn't exist
      if (_stripeAccountStatus?.status == StripeAccountStatus.notCreated) {
        final user = FirebaseAuth.instance.currentUser;
        final walkerProfile = await _userService.getUser(widget.walkerId);

        final createResult = await _stripeConnectService.createConnectedAccount(
          email: user?.email ?? '',
          walkerName: walkerProfile?.displayName ?? 'Walker',
        );

        if (!createResult.success) {
          throw Exception(createResult.errorMessage ?? 'Failed to create account');
        }
      }

      // Open the Stripe onboarding flow
      final opened = await _stripeConnectService.openOnboardingFlow();

      if (!opened) {
        throw Exception('Could not open Stripe setup. Please try again.');
      }

      // Show a message that they should complete setup in the browser
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete your account setup in the browser, then return here.'),
            backgroundColor: DesignSystem.walkerPrimary,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set up Stripe: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingUpStripe = false);
        // Reload status after returning
        _loadStripeAccountStatus();
      }
    }
  }

  Future<void> _openStripeDashboard() async {
    final opened = await _stripeConnectService.openDashboard();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open Stripe dashboard'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
          'My Wallet',
          style: TextStyle(
            fontSize: DesignSystem.h2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: DesignSystem.getTextPrimary(isDark),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh streams
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(DesignSystem.space2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceSummaryCard(isDark),
                      SizedBox(height: DesignSystem.space3),
                      _buildStripeAccountCard(isDark),
                      SizedBox(height: DesignSystem.space3),
                      _buildQuickActions(isDark),
                      SizedBox(height: DesignSystem.space4),
                      _buildPendingWithdrawalsSection(isDark),
                      SizedBox(height: DesignSystem.space4),
                      _buildSectionTitle('Recent Transactions', isDark),
                      SizedBox(height: DesignSystem.space2),
                    ],
                  ),
                ),
              ),
              _buildTransactionsList(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard(bool isDark) {
    return StreamBuilder<double>(
      stream: _paymentService.getAvailableBalance(widget.walkerId),
      builder: (context, availableSnapshot) {
        return FutureBuilder<List<double>>(
          future: Future.wait([
            _paymentService.getPendingEarnings(widget.walkerId),
            _paymentService.getTotalEarnings(widget.walkerId),
            _paymentService.getWalletBalance(widget.walkerId),
          ]),
          builder: (context, snapshot) {
            final pendingEarnings = snapshot.data?[0] ?? 0.0;
            final totalEarnings = snapshot.data?[1] ?? 0.0;
            final walletBalance = snapshot.data?[2] ?? 0.0;
            final availableBalance = availableSnapshot.data ?? walletBalance;

            return Container(
              padding: EdgeInsets.all(DesignSystem.space3),
              decoration: BoxDecoration(
                gradient: DesignSystem.successGradient,
                borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
                boxShadow: DesignSystem.shadowGlow(DesignSystem.success),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: DesignSystem.body,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(DesignSystem.space1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.space2),
                  Text(
                    '\$${availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: DesignSystem.space3),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  SizedBox(height: DesignSystem.space2),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceItem(
                          'Pending',
                          pendingEarnings,
                          Icons.schedule_rounded,
                          isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildBalanceItem(
                          'Total Earned',
                          totalEarnings,
                          Icons.trending_up_rounded,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignSystem.space1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              SizedBox(width: DesignSystem.space0_5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: DesignSystem.small,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space0_5),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeAccountCard(bool isDark) {
    if (_isLoadingStripeStatus) {
      return Container(
        padding: EdgeInsets.all(DesignSystem.space2),
        decoration: BoxDecoration(
          color: DesignSystem.getSurface(isDark),
          borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
          border: Border.all(
            color: DesignSystem.getBorderColor(isDark),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignSystem.walkerPrimary,
              ),
            ),
            SizedBox(width: DesignSystem.space2),
            Text(
              'Loading payout account status...',
              style: TextStyle(
                color: DesignSystem.getTextSecondary(isDark),
                fontSize: DesignSystem.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final status = _stripeAccountStatus?.status ?? StripeAccountStatus.notCreated;
    final isActive = status == StripeAccountStatus.active;
    final isPending = status == StripeAccountStatus.pending ||
                      status == StripeAccountStatus.pendingVerification;

    IconData statusIcon;
    Color statusColor;
    String statusTitle;
    String statusSubtitle;

    if (isActive) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = DesignSystem.success;
      statusTitle = 'Payout Account Ready';
      statusSubtitle = 'Your bank account is connected and ready to receive withdrawals';
    } else if (isPending) {
      statusIcon = Icons.schedule_rounded;
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'Setup Incomplete';
      statusSubtitle = 'Complete your account setup to start receiving withdrawals';
    } else {
      statusIcon = Icons.account_balance_rounded;
      statusColor = DesignSystem.walkerPrimary;
      statusTitle = 'Set Up Payouts';
      statusSubtitle = 'Connect your bank account to withdraw your earnings';
    }

    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignSystem.space1_5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              SizedBox(width: DesignSystem.space1_5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: DesignSystem.getTextPrimary(isDark),
                        fontSize: DesignSystem.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        color: DesignSystem.getTextSecondary(isDark),
                        fontSize: DesignSystem.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isActive) ...[
            SizedBox(height: DesignSystem.space2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSettingUpStripe ? null : _setupStripeAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: DesignSystem.space1_5),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
                  ),
                ),
                child: _isSettingUpStripe
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isPending ? 'Continue Setup' : 'Connect Bank Account',
                        style: TextStyle(
                          fontSize: DesignSystem.bodySmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ] else ...[
            SizedBox(height: DesignSystem.space1_5),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _openStripeDashboard,
                  icon: Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text('Manage Account'),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignSystem.walkerPrimary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: DesignSystem.space2),
                TextButton.icon(
                  onPressed: _loadStripeAccountStatus,
                  icon: Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignSystem.getTextSecondary(isDark),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final isStripeReady = _stripeAccountStatus?.status == StripeAccountStatus.active;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isStripeReady
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WithdrawalRequestScreen(
                          walkerId: widget.walkerId,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              padding: EdgeInsets.symmetric(vertical: DesignSystem.space2),
              elevation: isStripeReady ? 4 : 0,
              shadowColor: DesignSystem.success.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_circle_up_rounded, size: 20),
                SizedBox(width: DesignSystem.space1),
                Text(
                  isStripeReady ? 'Request Withdrawal' : 'Set up payouts first',
                  style: TextStyle(
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingWithdrawalsSection(bool isDark) {
    return StreamBuilder<List<WithdrawalRequest>>(
      stream: _withdrawalService.getWalkerWithdrawals(widget.walkerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final pendingWithdrawals = snapshot.data!
            .where((w) =>
                w.status == WithdrawalStatus.pending ||
                w.status == WithdrawalStatus.approved ||
                w.status == WithdrawalStatus.processing)
            .toList();

        if (pendingWithdrawals.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pending Withdrawals', isDark),
            SizedBox(height: DesignSystem.space2),
            ...pendingWithdrawals.map((withdrawal) =>
              _buildWithdrawalCard(withdrawal, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWithdrawalCard(WithdrawalRequest withdrawal, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (withdrawal.status) {
      case WithdrawalStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
        break;
      case WithdrawalStatus.approved:
        statusColor = DesignSystem.verified;
        statusIcon = Icons.check_circle_rounded;
        break;
      case WithdrawalStatus.processing:
        statusColor = DesignSystem.walkerPrimary;
        statusIcon = Icons.sync_rounded;
        break;
      default:
        statusColor = DesignSystem.getTextSecondary(isDark);
        statusIcon = Icons.info_rounded;
    }

    return Container(
      margin: EdgeInsets.only(bottom: DesignSystem.space2),
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    size: 16,
                    color: statusColor,
                  ),
                  SizedBox(width: DesignSystem.space1),
                  Text(
                    withdrawal.statusDisplayText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: DesignSystem.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${withdrawal.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: DesignSystem.getTextPrimary(isDark),
                  fontSize: DesignSystem.h3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignSystem.space1),
          Text(
            'Requested ${DateFormat('MMM dd, yyyy').format(withdrawal.createdAt)}',
            style: TextStyle(
              color: DesignSystem.getTextSecondary(isDark),
              fontSize: DesignSystem.small,
            ),
          ),
          if (withdrawal.canBeCancelled) ...[
            SizedBox(height: DesignSystem.space1_5),
            TextButton(
              onPressed: () => _cancelWithdrawal(withdrawal.id),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Cancel Request',
                style: TextStyle(
                  fontSize: DesignSystem.small,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

  Widget _buildTransactionsList(bool isDark) {
    return StreamBuilder<List<Transaction>>(
      stream: _paymentService.getWalkerTransactions(widget.walkerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(DesignSystem.space4),
                child: CircularProgressIndicator(
                  color: DesignSystem.success,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(DesignSystem.space4),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 64,
                      color: DesignSystem.getTextTertiary(isDark),
                    ),
                    SizedBox(height: DesignSystem.space2),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: DesignSystem.getTextSecondary(isDark),
                        fontSize: DesignSystem.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final transactions = snapshot.data!.take(10).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final transaction = transactions[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSystem.space2,
                  vertical: DesignSystem.space1,
                ),
                child: _buildTransactionCard(transaction, isDark),
              );
            },
            childCount: transactions.length,
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction, bool isDark) {
    IconData icon;
    Color color;
    String title;

    switch (transaction.type) {
      case TransactionType.earning:
        icon = Icons.arrow_circle_down_rounded;
        color = DesignSystem.success;
        title = transaction.dogName ?? 'Walk Earning';
        break;
      case TransactionType.withdrawal:
        icon = Icons.arrow_circle_up_rounded;
        color = const Color(0xFFEF4444);
        title = 'Withdrawal';
        break;
      case TransactionType.refund:
        icon = Icons.refresh_rounded;
        color = const Color(0xFFF59E0B);
        title = 'Refund';
        break;
      case TransactionType.platformFee:
        icon = Icons.info_rounded;
        color = DesignSystem.walkerPrimary;
        title = 'Platform Fee';
        break;
    }

    final isNegative = transaction.amount < 0;
    final displayAmount = transaction.amount.abs();

    return Container(
      padding: EdgeInsets.all(DesignSystem.space2),
      decoration: BoxDecoration(
        color: DesignSystem.getSurface(isDark),
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: DesignSystem.getBorderColor(isDark),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignSystem.space1_5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: DesignSystem.space1_5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: DesignSystem.getTextPrimary(isDark),
                    fontSize: DesignSystem.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: DesignSystem.space0_5),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
                  style: TextStyle(
                    color: DesignSystem.getTextSecondary(isDark),
                    fontSize: DesignSystem.small,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isNegative ? '-' : '+'}\$${displayAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isNegative ? const Color(0xFFEF4444) : DesignSystem.success,
              fontSize: DesignSystem.h3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelWithdrawal(String withdrawalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Withdrawal'),
        content: Text('Are you sure you want to cancel this withdrawal request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _withdrawalService.cancelWithdrawal(withdrawalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Withdrawal request cancelled'),
              backgroundColor: DesignSystem.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel withdrawal: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }
}
