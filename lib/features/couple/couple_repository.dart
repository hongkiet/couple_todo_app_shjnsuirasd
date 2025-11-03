import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // debugPrint

class CoupleRepository {
  final _supa = Supabase.instance.client;

  String _genCode([int len = 6]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(len, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<String> createCouple() async {
    final userId = _supa.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in.');

    String? lastError;

    for (int i = 0; i < 5; i++) {
      final code = _genCode();
      try {
        // insert couples -> trả về 1 row (Map<String, dynamic>)
        final Map<String, dynamic> couple = await _supa
            .from('couples')
            .insert({
              'code': code, // KHÔNG gửi created_by
            })
            .select('id, code')
            .single();

        await _supa.from('couple_members').insert({
          'couple_id': couple['id'],
          'user_id': userId, // policy: user_id phải = auth.uid()
          'role': 'owner',
        });

        debugPrint('[createCouple] OK code=${couple['code']}');
        return couple['code'] as String;
      } on PostgrestException catch (e) {
        // Lỗi từ Supabase (RLS, policy, duplicate key, v.v.)
        lastError = 'PostgrestException(code=${e.code}, message=${e.message})';
        debugPrint('[createCouple] attempt ${i + 1} failed: $lastError');

        // Nếu trùng code (unique_violation 23505) thì thử lại vòng sau
        if (e.code?.trim() == '23505' ||
            e.message.toLowerCase().contains('duplicate') == true) {
          continue;
        }
        // Lỗi khác: dừng luôn để thấy message thật
        rethrow;
      } catch (e) {
        // Lỗi không phải Postgrest (null user, network,…)
        lastError = e.toString();
        debugPrint('[createCouple] attempt ${i + 1} failed: $lastError');
        rethrow;
      }
    }

    throw Exception(
      'Cannot create couple after retries. Last error: $lastError',
    );
  }

  Future<String> joinByCode(String code) async {
    try {
      final response = await _supa.rpc('join_couple', params: {'p_code': code});
      return response as String; // couple_id
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> myCoupleId() async {
    try {
      // Sử dụng RPC function để tránh infinite recursion trong RLS policy
      final response = await _supa.rpc('get_my_couple_id');
      return response as String?;
    } catch (e) {
      debugPrint('[myCoupleId] Error: $e');
      // Nếu lỗi, trả về null thay vì throw để UI có thể xử lý
      return null;
    }
  }

  Future<String?> getCoupleIdByCode(String code) async {
    try {
      final response = await _supa
          .from('couples')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e) {
      debugPrint('[getCoupleIdByCode] Error: $e');
      return null;
    }
  }

  Future<void> unpairCouple() async {
    final userId = _supa.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in.');

    try {
      // Sử dụng RPC function để tránh infinite recursion trong RLS policy
      await _supa.rpc('leave_couple');
      debugPrint('[unpairCouple] Successfully left couple');
    } catch (e) {
      debugPrint('[unpairCouple] Error: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem couple đã có đủ 2 members chưa
  Future<bool> isCoupleComplete() async {
    try {
      final coupleId = await myCoupleId();
      if (coupleId == null) return false;

      // Sử dụng RPC function để tránh infinite recursion trong RLS policy
      final response = await _supa.rpc(
        'is_couple_complete',
        params: {'p_couple_id': coupleId},
      );

      return response as bool? ?? false;
    } catch (e) {
      debugPrint('[isCoupleComplete] Error: $e');
      return false;
    }
  }

  Future<void> hardDeleteCoupleForOwner() async {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Chưa đăng nhập');
    }

    final coupleId = await myCoupleId();
    if (coupleId == null) {
      throw Exception('Không tìm thấy couple');
    }

    // Kiểm tra role owner từ couple_members
    final member = await client
        .from('couple_members')
        .select('role')
        .eq('couple_id', coupleId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (member == null || member['role'] != 'owner') {
      throw Exception('Chỉ owner mới có quyền xóa vĩnh viễn');
    }

    // Gọi RPC để xóa trong transaction
    await client.rpc('hard_delete_couple', params: {'p_couple_id': coupleId});
  }
}
