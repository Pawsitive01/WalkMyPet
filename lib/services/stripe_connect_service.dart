import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

/// Status of a walker's Stripe Connect account
enum StripeAccountStatus {
  notCreated,
  pending,
  pendingVerification,
  active,
}

/// Result of Stripe Connect account operations
class StripeConnectResult {
  final bool success;
  final String? accountId;
  final String? url;
  final String? errorMessage;
  final StripeAccountStatus status;
  final bool detailsSubmitted;
  final bool payoutsEnabled;

  StripeConnectResult({
    required this.success,
    this.accountId,
    this.url,
    this.errorMessage,
    this.status = StripeAccountStatus.notCreated,
    this.detailsSubmitted = false,
    this.payoutsEnabled = false,
  });

  factory StripeConnectResult.success({
    String? accountId,
    String? url,
    StripeAccountStatus status = StripeAccountStatus.active,
    bool detailsSubmitted = false,
    bool payoutsEnabled = false,
  }) {
    return StripeConnectResult(
      success: true,
      accountId: accountId,
      url: url,
      status: status,
      detailsSubmitted: detailsSubmitted,
      payoutsEnabled: payoutsEnabled,
    );
  }

  factory StripeConnectResult.failure(String message) {
    return StripeConnectResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Result of withdrawal payout operation
class PayoutResult {
  final bool success;
  final String? transferId;
  final double? amount;
  final String? message;
  final String? errorMessage;

  PayoutResult({
    required this.success,
    this.transferId,
    this.amount,
    this.message,
    this.errorMessage,
  });

  factory PayoutResult.success({
    required String transferId,
    required double amount,
    String? message,
  }) {
    return PayoutResult(
      success: true,
      transferId: transferId,
      amount: amount,
      message: message,
    );
  }

  factory PayoutResult.failure(String message) {
    return PayoutResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for managing Stripe Connect accounts and payouts
class StripeConnectService {
  // Singleton pattern
  static final StripeConnectService _instance = StripeConnectService._internal();
  factory StripeConnectService() => _instance;
  StripeConnectService._internal();

  // Use australia-southeast1 region to match Cloud Functions deployment
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'australia-southeast1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a Stripe Connect account for the current walker
  Future<StripeConnectResult> createConnectedAccount({
    required String email,
    required String walkerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StripeConnectResult.failure('User not authenticated');
      }

      final callable = _functions.httpsCallable('createConnectedAccount');
      final response = await callable.call({
        'email': email,
        'walkerName': walkerName,
      });

      final data = response.data;
      if (data['success'] != true) {
        return StripeConnectResult.failure(
            data['error'] ?? 'Failed to create account');
      }

      final status = _parseAccountStatus(
        detailsSubmitted: data['detailsSubmitted'] ?? false,
        payoutsEnabled: data['payoutsEnabled'] ?? false,
      );

      return StripeConnectResult.success(
        accountId: data['accountId'],
        status: status,
        detailsSubmitted: data['detailsSubmitted'] ?? false,
        payoutsEnabled: data['payoutsEnabled'] ?? false,
      );
    } catch (e) {
      // Error handled silently
      return StripeConnectResult.failure(_parseError(e));
    }
  }

  /// Get the onboarding URL for Stripe Connect
  /// Walker will complete identity verification and bank details on Stripe's hosted page
  Future<StripeConnectResult> getOnboardingUrl({
    String? refreshUrl,
    String? returnUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StripeConnectResult.failure('User not authenticated');
      }

      final callable = _functions.httpsCallable('createAccountLink');
      final response = await callable.call({
        'refreshUrl': refreshUrl ?? 'https://walkmypet.app/stripe-refresh',
        'returnUrl': returnUrl ?? 'https://walkmypet.app/stripe-return',
      });

      final data = response.data;
      if (data['success'] != true) {
        return StripeConnectResult.failure(
            data['error'] ?? 'Failed to create onboarding link');
      }

      return StripeConnectResult.success(url: data['url']);
    } catch (e) {
      // Error handled silently
      return StripeConnectResult.failure(_parseError(e));
    }
  }

  /// Get the current status of the walker's Stripe Connect account
  Future<StripeConnectResult> getAccountStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StripeConnectResult.failure('User not authenticated');
      }

      final callable = _functions.httpsCallable('getConnectedAccountStatus');
      final response = await callable.call({});

      final data = response.data;
      if (data['success'] != true) {
        return StripeConnectResult.failure(
            data['error'] ?? 'Failed to get account status');
      }

      if (data['hasAccount'] != true) {
        return StripeConnectResult.success(
          status: StripeAccountStatus.notCreated,
        );
      }

      final status = _parseAccountStatus(
        detailsSubmitted: data['detailsSubmitted'] ?? false,
        payoutsEnabled: data['payoutsEnabled'] ?? false,
      );

      return StripeConnectResult.success(
        accountId: data['accountId'],
        status: status,
        detailsSubmitted: data['detailsSubmitted'] ?? false,
        payoutsEnabled: data['payoutsEnabled'] ?? false,
      );
    } catch (e) {
      // Error handled silently
      return StripeConnectResult.failure(_parseError(e));
    }
  }

  /// Open the Stripe onboarding flow in the browser
  Future<bool> openOnboardingFlow({
    String? refreshUrl,
    String? returnUrl,
  }) async {
    try {
      final result = await getOnboardingUrl(
        refreshUrl: refreshUrl,
        returnUrl: returnUrl,
      );

      if (!result.success || result.url == null) {
        // Error handled silently
        return false;
      }

      final uri = Uri.parse(result.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Error handled silently
        return false;
      }
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Open the Stripe Express Dashboard for the walker
  Future<bool> openDashboard() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final callable = _functions.httpsCallable('createDashboardLink');
      final response = await callable.call({});

      final data = response.data;
      if (data['success'] != true || data['url'] == null) {
        // Error handled silently
        return false;
      }

      final uri = Uri.parse(data['url']);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Error handled silently
        return false;
      }
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Process a withdrawal payout via Stripe Transfer
  Future<PayoutResult> processWithdrawalPayout(String withdrawalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return PayoutResult.failure('User not authenticated');
      }

      final callable = _functions.httpsCallable('processWithdrawalPayout');
      final response = await callable.call({
        'withdrawalId': withdrawalId,
      });

      final data = response.data;
      if (data['success'] != true) {
        return PayoutResult.failure(
            data['error'] ?? 'Failed to process withdrawal');
      }

      return PayoutResult.success(
        transferId: data['transferId'],
        amount: (data['amount'] ?? 0).toDouble(),
        message: data['message'],
      );
    } catch (e) {
      // Error handled silently
      return PayoutResult.failure(_parseError(e));
    }
  }

  /// Check if the walker has a fully setup Stripe account ready for payouts
  Future<bool> isReadyForPayouts() async {
    final result = await getAccountStatus();
    return result.success && result.payoutsEnabled;
  }

  /// Parse account status from Stripe response
  StripeAccountStatus _parseAccountStatus({
    required bool detailsSubmitted,
    required bool payoutsEnabled,
  }) {
    if (payoutsEnabled) {
      return StripeAccountStatus.active;
    } else if (detailsSubmitted) {
      return StripeAccountStatus.pendingVerification;
    } else {
      return StripeAccountStatus.pending;
    }
  }

  /// Parse error message from exception
  String _parseError(dynamic error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'An error occurred';
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
