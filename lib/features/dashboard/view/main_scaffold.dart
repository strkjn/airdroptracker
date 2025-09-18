// lib/features/dashboard/view/main_scaffold.dart

import 'dart:ui';
import 'package:airdrop_flow/core/widgets/app_background.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart'; 
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/dashboard_page.dart';
import 'package:airdrop_flow/features/discover/view/discover_page.dart';
import 'package:airdrop_flow/features/projects/view/add_edit_project_page.dart';
import 'package:airdrop_flow/features/projects/view/project_list_page.dart';
import 'package:airdrop_flow/features/settings/view/settings_page.dart';
import 'package:airdrop_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.3),
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
        
        // --- PERUBAHAN 2: Menyesuaikan posisi Tombol ---
        floatingActionButton: Transform.translate(
          // Geser tombol ke bawah agar pas dengan lekukan
          offset: const Offset(0, 15),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddEditProjectPage()),
              );
            },
            backgroundColor: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          // --- PERUBAHAN 1: Menyesuaikan ukuran Navigasi ---
          height: 75.0, 
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(icon: Icons.dashboard_outlined, index: 0),
                _buildNavItem(icon: Icons.list_alt_outlined, index: 1),
                const SizedBox(width: 40), 
                _buildNavItem(icon: Icons.explore_outlined, index: 2),
                _buildNavItem(icon: Icons.settings_outlined, index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Center(
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? theme.colorScheme.onPrimary : Colors.white70,
            ),
          ),
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