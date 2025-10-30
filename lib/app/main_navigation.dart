import 'package:couple_todo_app_shjn/features/couple/ui/pages/couple_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../features/tasks/ui/home_page.dart';
import '../features/progress/progress_page.dart';
import '../features/profile/ui/pages/profile_page.dart';
import '../features/couple/ui/pages/pairing_page.dart';
import '../features/couple/couple_repository.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? coupleId;
  bool isLoading = true;
  bool isCoupleComplete = false;

  @override
  void initState() {
    super.initState();
    _loadCoupleData();
  }

  Future<void> _loadCoupleData() async {
    try {
      final repo = CoupleRepository();
      final id = await repo.myCoupleId();
      final isComplete = id != null ? await repo.isCoupleComplete() : false;
      
      debugPrint('[MainNavigation] Loaded coupleId: $id, isComplete: $isComplete');
      if (mounted) {
        setState(() {
          coupleId = id;
          isCoupleComplete = isComplete;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MainNavigation] Error loading coupleData: $e');
      if (mounted) {
        setState(() {
          coupleId = null;
          isCoupleComplete = false;
          isLoading = false;
        });
      }
    }
  }


  void _onPairingSuccess() {
    debugPrint('[MainNavigation] onPairingSuccess called');
    // Đợi một chút để đảm bảo DB đã sync
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadCoupleData();
    });
  }

  void _onUnpairSuccess() {
    _loadCoupleData();
  }

  List<Widget> get _pages {
    debugPrint('[MainNavigation] _pages getter called, coupleId: $coupleId, isComplete: $isCoupleComplete');
    // Chỉ vào HomePage khi có coupleId VÀ couple đã hoàn chỉnh (có 2 members)
    if (coupleId == null || !isCoupleComplete) {
      debugPrint('[MainNavigation] Returning PairingPage');
      return [
        PairingPage(onPairingSuccess: _onPairingSuccess),
        const CouplePage(),
        const ProgressPage(),
        ProfilePage(onUnpairSuccess: _onUnpairSuccess),
      ];
    }

    debugPrint('[MainNavigation] Returning HomePage');
    return [
      HomePage(coupleId: coupleId!),
      const CouplePage(),
      const ProgressPage(),
      ProfilePage(onUnpairSuccess: _onUnpairSuccess),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Couple',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
