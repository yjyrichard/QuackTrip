import 'package:flutter/material.dart';
import '../../../icons/lucide_adapter.dart';
import '../../home/pages/home_page.dart';
import '../../attractions/pages/attractions_manage_page.dart';
import '../../trips/pages/trips_list_page.dart';
import '../../settings/pages/settings_page.dart';

/// QuackTrip 主页面 - 带底部导航栏
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  // 页面列表
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(), // 聊天主页
      const AttractionsManagePage(), // 景点管理
      const TripsListPage(), // 旅行列表
      const SettingsPage(), // 设置页面
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        height: 70,
        destinations: [
          NavigationDestination(
            icon: Icon(Lucide.MessageCircle),
            selectedIcon: Icon(Lucide.MessageCircle),
            label: '聊天',
          ),
          NavigationDestination(
            icon: Icon(Lucide.Map),
            selectedIcon: Icon(Lucide.Map),
            label: '景点',
          ),
          NavigationDestination(
            icon: Icon(Lucide.Calendar),
            selectedIcon: Icon(Lucide.Calendar),
            label: '旅行',
          ),
          NavigationDestination(
            icon: Icon(Lucide.Settings),
            selectedIcon: Icon(Lucide.Settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
