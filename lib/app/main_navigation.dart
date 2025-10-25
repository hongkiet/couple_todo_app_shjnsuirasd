import 'package:couple_todo_app_shjn/features/couple/couple_page.dart';
import 'package:flutter/material.dart';
import '../features/tasks/ui/home_page.dart';
import '../features/progress/progress_page.dart';
import '../features/profile/profile_page.dart';
import '../features/couple/pairing_page.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCoupleId();
  }

  Future<void> _loadCoupleId() async {
    try {
      final id = await CoupleRepository().myCoupleId();
      setState(() {
        coupleId = id;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        coupleId = null;
        isLoading = false;
      });
    }
  }

  void _onPairingSuccess() {
    _loadCoupleId();
  }

  void _onUnpairSuccess() {
    _loadCoupleId();
  }

  List<Widget> get _pages {
    if (coupleId == null) {
      return [
        PairingPage(onPairingSuccess: _onPairingSuccess),
        const CouplePage(),
        const ProgressPage(),
        ProfilePage(onUnpairSuccess: _onUnpairSuccess),
      ];
    }

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
