import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../couple_repository.dart';

class PairingPage extends StatefulWidget {
  final VoidCallback? onPairingSuccess;

  const PairingPage({super.key, this.onPairingSuccess});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final repo = CoupleRepository();
  final codeCtrl = TextEditingController();
  String? myCode;
  bool loading = false;
  RealtimeChannel? _coupleChannel;
  Timer? _pollingTimer;

  Future<void> _create() async {
    setState(() => loading = true);
    try {
      final code = await repo.createCouple();
      setState(() => myCode = code);

      _listenForNewMember(code);
    } catch (e) {
      _toast(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void _listenForNewMember(String code) async {
    try {
      // Lấy couple_id từ code
      final coupleId = await repo.getCoupleIdByCode(code);
      debugPrint('[PairingPage] coupleId: $coupleId');
      if (coupleId == null) return;

      // Subscribe để lắng nghe thay đổi trong couple_members
      _coupleChannel = Supabase.instance.client
          .channel('couple_members_$coupleId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'couple_members',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'couple_id',
              value: coupleId,
            ),
            callback: (payload) {
              debugPrint('[PairingPage] New member joined via realtime: $payload');
              _onMemberJoined();
            },
          )
          .subscribe();

      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final isComplete = await repo.isCoupleComplete();
          debugPrint('[PairingPage] Polling: isCoupleComplete = $isComplete');
          if (isComplete) {
            timer.cancel(); // Dừng polling
            _onMemberJoined();
          }
        } catch (e) {
          debugPrint('[PairingPage] Polling error: $e');
        }
      });
    } catch (e) {
      debugPrint('[PairingPage] Error setting up listener: $e');
    }
  }

  void _onMemberJoined() {
    if (mounted) {
      debugPrint('[PairingPage] Member joined - notifying MainNavigation');
      _toast('Partner đã join! Đang chuyển vào HomePage...');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onPairingSuccess?.call();
        }
      });
    }
  }

  Future<void> _join() async {
    setState(() => loading = true);
    try {
      final _ = await repo.joinByCode(codeCtrl.text.trim().toUpperCase());
      if (mounted) {
        _toast('Join thành công! Đang chuyển vào HomePage...');
        // Đợi 1 giây để đảm bảo DB đã sync
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            widget.onPairingSuccess?.call();
          }
        });
      }
    } catch (e) {
      _toast(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _coupleChannel?.unsubscribe();
    _pollingTimer?.cancel();
    codeCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair with your partner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Bước 1: Một người tạo mã (Create).'),
            const Text('Bước 2: Người kia nhập mã (Join).'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _create,
              child: const Text('Create couple code'),
            ),
            if (myCode != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Your code: ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectableText(
                myCode!,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Text('Gửi mã này cho partner để họ Join.'),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Enter couple code'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: loading ? null : _join,
              child: const Text('Join couple'),
            ),
          ],
        ),
      ),
    );
  }
}


