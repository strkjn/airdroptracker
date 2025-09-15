import 'package:airdrop_flow/core/widgets/app_background.dart'; // <-- 1. Tambahkan import ini
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2. Bungkus Scaffold dengan widget AppBackground
    return AppBackground(
      child: Scaffold(
        // 3. Buat Scaffold menjadi transparan agar latar belakang terlihat
        backgroundColor: Colors.transparent,
        body: Center(child: _widgetOptions[_selectedIndex]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddEditProjectPage()),
            );
          },
          child: const Icon(Icons.add),
          shape: const CircleBorder(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(
                  icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0),
              _buildNavItem(
                  icon: Icons.list_alt_outlined, label: 'Proyek', index: 1),
              const SizedBox(width: 40),
              _buildNavItem(
                  icon: Icons.explore_outlined, label: 'Discover', index: 2),
              _buildNavItem(
                  icon: Icons.settings_outlined, label: 'Pengaturan', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}