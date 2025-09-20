// lib/features/dashboard/view/main_scaffold.dart

import 'dart:ui';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/app_background.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/dashboard/providers/dashboard_providers.dart';
import 'package:airdrop_flow/features/dashboard/view/dashboard_page.dart';
import 'package:airdrop_flow/features/discover/view/discover_page.dart';
import 'package:airdrop_flow/features/notifications/view/notification_page.dart';
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

  // Daftar halaman/widget untuk setiap tab
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardPage(),
    ProjectListPage(),
    DiscoverPage(),
    SettingsPage(),
  ];

  // --- PERUBAHAN 1: Daftar judul untuk setiap halaman ---
  // Judul ini akan ditampilkan di AppBar sesuai tab yang aktif.
  // Untuk dashboard (indeks 0), kita biarkan kosong karena akan diganti sapaan.
  static const List<String> _widgetTitles = <String>[
    '', // Judul untuk Dashboard (tidak digunakan)
    'Proyek Saya',
    'Discover Airdrops',
    'Pengaturan'
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDailyNotification();
    });
  }

  void _scheduleDailyNotification() {
    final tasksAsync = ref.read(dashboardTasksProvider);

    tasksAsync.whenData((dashboardData) {
      final tasks = dashboardData.today;

      if (tasks.isNotEmpty) {
        final taskCount = tasks.where((t) => !t.isCompleted).length;
        if (taskCount > 0) {
          ref.read(firestoreServiceProvider).addNotification(
                'Tugas Harian Tersedia',
                'Ada $taskCount tugas yang perlu diselesaikan hari ini. Semangat!',
              );

          notificationService.scheduleDailySummaryNotification(
            hour: 7,
            minute: 5,
            title: '🔥 Waktunya Garap Airdrop!',
            body: 'Anda memiliki $taskCount tugas yang perlu diselesaikan hari ini. Semangat!',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

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
          // --- PERUBAHAN 2: Logika Judul AppBar Dinamis ---
          // Jika tab dashboard (indeks 0) aktif, tampilkan sapaan.
          // Jika tidak, tampilkan judul halaman dari daftar _widgetTitles.
          title: _selectedIndex == 0
              ? const _DashboardAppBarTitle()
              : Text(_widgetTitles[_selectedIndex]),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Center(child: _widgetOptions[_selectedIndex]),

        floatingActionButton: Transform.translate(
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
}

// --- PERUBAHAN 3: Widget baru untuk Sapaan di AppBar ---
// Widget ini berisi sapaan "Hallo!" yang sebelumnya ada di DashboardPage.
class _DashboardAppBarTitle extends StatelessWidget {
  const _DashboardAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hallo !',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
        // Placeholder, nantinya bisa diganti dengan nama user yang login
        Text(
          'nama user',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20, // Sedikit disesuaikan ukurannya
              ),
        ),
      ],
    );
  }
}