import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:doraa/models/wallet_transaction_model.dart';
import 'package:doraa/services/notification_db_service.dart';
import 'package:doraa/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  final notificationService = ref.read(notificationDbServiceProvider);
  return WalletService(ref, notificationService);
});

class WalletService {
  final Ref _ref;
  final NotificationDBService _notificationService;
  final _client = Supabase.instance.client;

  WalletService(this._ref, this._notificationService);

  static Future<double> getBalance(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('wallet_balance')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null && response['wallet_balance'] != null) {
        return (response['wallet_balance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint("Error fetching balance: $e");
      return 0.0;
    }
  }

  /// Admin recharges an Agent's float
  static Future<Map<String, dynamic>> adminTopupAgent({
    required String adminId,
    required String agentId,
    required double amount,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc('admin_topup_agent', params: {
        'p_admin_id': adminId,
        'p_agent_id': agentId,
        'p_amount': amount,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint("Error in adminTopupAgent: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Agent recharges a Driver's (Customer's) wallet
  static Future<Map<String, dynamic>> agentRechargeCustomer({
    required String agentId,
    required String customerId,
    required double amount,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc('agent_recharge_customer', params: {
        'p_agent_id': agentId,
        'p_customer_id': customerId,
        'p_amount': amount,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint("Error in agentRechargeCustomer: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<WalletTransactionModel>> fetchTransactions() async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => WalletTransactionModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// اقتطاع عمولة التطبيق (Commission Deduction)
  /// عندما تنتهي الرحلة، يمسك السائق المال كاش، والتطبيق يخصم عمولته من المحفظة
  Future<void> deductCommission(double commissionAmount, String rideId) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    try {
      await _client.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': -commissionAmount, // خصم من المحفظة
        'type': 'commission',
        'status': 'completed',
        'description': 'خصم عمولة DORA للرحلة',
      });

      // التحقق من الرصيد المتبقي بعد الخصم (للتنبيه الذكي)
      final profile = await _client
          .from('user_profiles')
          .select('wallet_balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile != null) {
        final currentBalance = (profile['wallet_balance'] ?? 0).toDouble();
        
        // خوارزمية التنبيه الذكي: إذا أصبح الرصيد سلبياً أو قريباً من النفاد
        if (currentBalance < 0) {
          await _notificationService.sendNotification(
            userId: userId,
            title: '⚠️ رصيدك بالسالب!',
            body: 'لقد أصبح رصيد محفظتك (${currentBalance.toStringAsFixed(0)} دج). يرجى شحن رصيدك قريباً لتجنب توقف حسابك عن استقبال الطلبات.',
            type: 'SYSTEM',
          );
        } else if (currentBalance < 200) {
          await _notificationService.sendNotification(
            userId: userId,
            title: 'نزول الرصيد 📉',
            body: 'رصيد محفظتك انخفض إلى ${currentBalance.toStringAsFixed(0)} دج. يرجى الشحن لضمان استمرار عملك.',
            type: 'SYSTEM',
          );
        }
      }
    } catch (e) {
      debugPrint("Error deducting commission: $e");
    }
  }

  /// شحن رصيد المحفظة (Top-up)
  Future<void> topUpWallet(double amount) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    try {
      await _client.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'topup',
        'status': 'completed',
        'description': 'شحن رصيد المحفظة',
      });

      await _notificationService.sendNotification(
        userId: userId,
        title: '💰 تم شحن رصيدك بنجاح',
        body: 'تمت إضافة ${amount.toStringAsFixed(0)} دج إلى محفظتك.',
        type: 'PROMO',
      );

    } catch (e) {
      debugPrint("Error in topUpWallet: $e");
    }
  }

  /// تلقي أموال (Transfer In) - مثلاً تحويل من وكيل
  Future<void> receiveTransfer(double amount, String fromUserName) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    try {
      await _client.from('wallet_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'transfer_in',
        'status': 'completed',
        'description': 'تحويل مستلم من $fromUserName',
      });

      await _notificationService.sendNotification(
        userId: userId,
        title: '💸 رصيد مستلم!',
        body: 'لقد تلقيت تحويلاً بقيمة ${amount.toStringAsFixed(0)} دج من $fromUserName.',
        type: 'SYSTEM',
      );

    } catch (e) {
      debugPrint("Error in receiveTransfer: $e");
    }
  }
}
