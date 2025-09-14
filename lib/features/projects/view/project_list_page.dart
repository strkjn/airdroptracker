// lib/features/projects/view/project_list_page.dart

import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/projects/view/project_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORT BARU UNTUK MEMBUKA URL ---
import 'package:url_launcher/url_launcher.dart';

// Halaman utama yang menampilkan daftar semua proyek
class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau stream dari semua proyek
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Proyek')),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada proyek.\nKlik tombol + di tengah bawah untuk memulai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, height: 1.5),
                ),
              ),
            );
          }
          // Menggunakan ListView.separated untuk memberi jarak antar kartu
          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              // Setiap item dalam list adalah ProjectCard yang kita buat di bawah
              return ProjectCard(project: project);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// Widget kartu kustom untuk menampilkan detail setiap proyek
class ProjectCard extends ConsumerWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  // --- FUNGSI BARU UNTUK MEMBUKA URL ---
  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka URL: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau data yang dibutuhkan secara spesifik untuk proyek ini
    final tasksAsync = ref.watch(tasksStreamProvider(project.id));
    final allWalletsAsync = ref.watch(walletsStreamProvider);
    final allSocialsAsync = ref.watch(socialAccountsStreamProvider);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Penting agar InkWell tidak keluar dari Card
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectDetailPage(project: project)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BARIS HEADER: NAMA PROYEK DAN STATUS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(project.status),
                ],
              ),
              const Divider(height: 24),

              // --- PERUBAHAN: BAGIAN DETAIL SEKARANG MENAMPILKAN URL ---
              // Hanya tampilkan baris URL jika URL-nya ada
              if (project.websiteUrl.isNotEmpty) ...[
                _buildClickableDetailRow(
                  context,
                  icon: Icons.language,
                  label: 'URL',
                  value: project.websiteUrl,
                  onTap: () => _launchURL(project.websiteUrl, context),
                ),
                const SizedBox(height: 12),
              ],
              
              tasksAsync.when(
                data: (tasks) => _buildDetailRow(
                  context,
                  icon: Icons.list_alt_rounded,
                  label: 'Tugas',
                  value: '${tasks.length} item',
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              
              allWalletsAsync.when(
                data: (allWallets) {
                  final usedWallets = allWallets.where((w) => project.associatedWalletIds.contains(w.id)).toList();
                  return _buildDetailRow(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    value: usedWallets.isEmpty ? 'Tidak ada' : usedWallets.map((w) => w.walletName).join(', '),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              
              allSocialsAsync.when(
                data: (allSocials) {
                  final usedSocials = allSocials.where((s) => project.associatedSocialAccountIds.contains(s.id)).toList();
                  return _buildDetailRow(
                    context,
                    icon: Icons.group_outlined,
                    label: 'Akun',
                    value: usedSocials.isEmpty ? 'Tidak ada' : usedSocials.map((s) => s.username).join(', '),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk membuat baris detail (tidak bisa diklik)
  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  // --- WIDGET HELPER BARU: untuk baris detail yang bisa diklik (seperti URL) ---
  Widget _buildClickableDetailRow(BuildContext context, {required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk membuat chip status dengan warna yang berbeda
  Widget _buildStatusChip(ProjectStatus status) {
    Color chipColor;
    String statusText = status.name[0].toUpperCase() + status.name.substring(1);

    switch (status) {
      case ProjectStatus.active:
        chipColor = Colors.green.shade100;
        break;
      case ProjectStatus.completed:
        chipColor = Colors.blue.shade100;
        break;
      case ProjectStatus.potential:
        chipColor = Colors.orange.shade100;
        break;
    }

    return Chip(
      label: Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}