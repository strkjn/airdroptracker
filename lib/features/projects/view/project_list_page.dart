import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/projects/view/project_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
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

class ProjectCard extends ConsumerWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka URL: $urlString')),
      );
    }
  }
  
  Color _getStatusGlowColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Colors.greenAccent;
      case ProjectStatus.completed:
        return Colors.blueAccent;
      case ProjectStatus.potential:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(project.id));
    final allWalletsAsync = ref.watch(walletsStreamProvider);
    final allSocialsAsync = ref.watch(socialAccountsStreamProvider);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectDetailPage(project: project)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Divider(height: 24, color: Colors.white24),
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
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableDetailRow(BuildContext context, {required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // --- FUNGSI YANG DIPERBARUI ---
  Widget _buildStatusChip(ProjectStatus status) {
    Color statusColor;
    String statusText = status.name[0].toUpperCase() + status.name.substring(1);

    switch (status) {
      case ProjectStatus.active:
        statusColor = Colors.greenAccent;
        break;
      case ProjectStatus.completed:
        statusColor = Colors.blueAccent;
        break;
      case ProjectStatus.potential:
        statusColor = Colors.orangeAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(40), // Latar belakang sangat transparan
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1), // Border berwarna
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor, // Teks berwarna
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}