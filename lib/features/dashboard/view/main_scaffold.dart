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
    
    // --- PERBAIKAN DI BLOK INI ---
    tasksAsync.whenData((dashboardData) {
      // Ambil total tugas dari kedua daftar (sisa kemarin dan hari ini)
      final int taskCount = dashboardData.overdueTasks.length + dashboardData.todaysTasks.length;

      // Periksa apakah total tugas lebih dari 0
      if (taskCount > 0) {
        notificationService.scheduleDailySummaryNotification(
          hour: 7,
          minute: 0,
          title: '🔥 Jangan Males Garap Airdrop!',
          body:
              'Anda memiliki $taskCount tugas yang perlu diselesaikan hari ini. Semangat!',
        );
      }
    });
    // --- AKHIR PERBAIKAN ---
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
        bottomNavigationBar: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                  ),
                ),
              ),
            ),
            AnimatedBottomNavigationBar(
              icons: iconList,
              activeIndex: _selectedIndex,
              gapLocation: GapLocation.center,
              notchSmoothness: NotchSmoothness.softEdge,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              inactiveColor: Colors.white70,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        // Mengubah judul AppBar agar lebih umum
        return 'Pusat Komando';
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