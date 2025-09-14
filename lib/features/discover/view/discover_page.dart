import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:airdrop_flow/core/models/project_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:airdrop_flow/features/discover/providers/discover_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAirdropsAsync = ref.watch(filteredAirdropsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover Airdrops')),
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
                  itemCount: airdrops.length,
                  itemBuilder: (context, index) {
                    final airdrop = airdrops[index];
                    return AirdropOpportunityCard(airdrop: airdrop);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal Memuat Data',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString().replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(airdropOpportunitiesProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        )
                      ],
                    ),
                  ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
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
      ),
    );
  }
}