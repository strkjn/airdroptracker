// lib/features/discover/view/discover_page.dart

import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/core/widgets/glass_container.dart';
import 'package:airdrop_flow/features/discover/providers/discover_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- IMPORT BARU ---
import 'package:airdrop_flow/core/widgets/error_display.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAirdropsAsync = ref.watch(filteredAirdropsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari airdrop...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 8),
                _buildFilterChips(context, ref),
              ],
            ),
          ),
          Expanded(
            child: filteredAirdropsAsync.when(
              data: (airdrops) {
                if (airdrops.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada airdrop yang cocok.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemCount: airdrops.length,
                  itemBuilder: (context, index) {
                    final airdrop = airdrops[index];
                    return AirdropOpportunityCard(airdrop: airdrop);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              // --- PERUBAHAN DI SINI ---
              // Mengganti tampilan error lama dengan widget baru
              error: (err, stack) {
                return ErrorDisplay(
                  errorMessage: err.toString(),
                  onRetry: () => ref.invalidate(airdropOpportunitiesProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(difficultyFilterProvider);
    return Wrap(
      spacing: 8.0,
      children: AirdropDifficulty.values.map((difficulty) {
        return FilterChip(
          label: Text(difficulty.name),
          selected: selectedFilter == difficulty,
          onSelected: (isSelected) {
            if (isSelected) {
              ref.read(difficultyFilterProvider.notifier).state = difficulty;
            } else {
              ref.read(difficultyFilterProvider.notifier).state = null;
            }
          },
        );
      }).toList(),
    );
  }
}

class AirdropOpportunityCard extends ConsumerWidget {
  final AirdropOpportunity airdrop;
  const AirdropOpportunityCard({super.key, required this.airdrop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(airdrop.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Chip(label: Text(airdrop.difficulty.name)),
          const SizedBox(height: 8),
          Text(
            airdrop.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambahkan ke Proyek Saya'),
              onPressed: () {
                final newProject = Project(
                  id: '',
                  name: airdrop.name,
                  notes:
                      'Peluang dari fitur Discover.\n\nDeskripsi: ${airdrop.description}\n\nSumber: ${airdrop.sourceUrl}',
                  status: ProjectStatus.potential,
                );
                ref.read(firestoreServiceProvider).addProject(newProject);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${airdrop.name}" ditambahkan ke proyek!'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}