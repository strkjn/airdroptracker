import 'dart:ui';
import 'package:airdrop_flow/core/widgets/app_background.dart';
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/dashboard_page.dart';
import 'package:airdrop_flow/features/discover/view/discover_page.dart';
import 'package:airdrop_flow/features/projects/view/add_edit_project_page.dart';
import 'package:airdrop_flow/features/projects/view/project_list_page.dart';
import 'package:airdrop_flow/features/settings/view/settings_page.dart';
import 'package:airdrop_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// IMPORT BARU UNTUK NAVIGASI ANIMASI
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardPage(),
    const ProjectListPage(),
    const DiscoverPage(),
    const SettingsPage(),
  ];

  final iconList = <IconData>[
    Icons.dashboard_outlined,
    Icons.list_alt_outlined,
    Icons.explore_outlined,
    Icons.settings_outlined,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDailyNotification();
    });
  }

  void _scheduleDailyNotification() {
    final tasksAsync = ref.read(todaysTasksProvider);
    tasksAsync.whenData((tasks) {
      if (tasks.isNotEmpty) {
        final taskCount = tasks.length;
        notificationService.scheduleDailySummaryNotification(
          hour: 7,
          minute: 0,
          title: '🔥 Jangan Males Garap Airdrop!',
          body:
              'Anda memiliki $taskCount tugas yang perlu diselesaikan hari ini. Semangat!',
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          title: Text(_getAppBarTitle(_selectedIndex)),
        ),
        body: Center(child: _widgetOptions[_selectedIndex]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddEditProjectPage()),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        
        // --- NAVIGASI BAWAH BARU DENGAN EFEK KACA DAN ANIMASI ---
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: _selectedIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.softEdge,
          onTap: (index) => setState(() => _selectedIndex = index),
          
          // Styling untuk efek kaca
          backgroundColor: Colors.black.withOpacity(0.3),
          inactiveColor: Colors.white70,
          activeColor: Theme.of(context).colorScheme.primary,
          blurEffect: true, // <-- Ini akan mengaktifkan efek blur bawaan
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Pusat Komando (Hari Ini)';
      case 1:
        return 'Daftar Proyek';
      case 2:
        return 'Discover Airdrops';
      case 3:
        return 'Pengaturan & Manajemen';
      default:
        return 'Airdrop Flow';
    }
  }
}