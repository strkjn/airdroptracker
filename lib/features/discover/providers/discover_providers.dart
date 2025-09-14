import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:airdrop_flow/core/providers/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final difficultyFilterProvider = StateProvider<AirdropDifficulty?>(
  (ref) => null,
);

final filteredAirdropsProvider = Provider<AsyncValue<List<AirdropOpportunity>>>(
  (ref) {
    final airdropsAsync = ref.watch(airdropOpportunitiesProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    final difficultyFilter = ref.watch(difficultyFilterProvider);

    return airdropsAsync.whenData((airdrops) {
      var filteredList = airdrops;

      if (searchQuery.isNotEmpty) {
        filteredList = filteredList.where((airdrop) {
          return airdrop.name.toLowerCase().contains(searchQuery) ||
              airdrop.description.toLowerCase().contains(searchQuery);
        }).toList();
      }

      if (difficultyFilter != null) {
        filteredList = filteredList.where((airdrop) {
          return airdrop.difficulty == difficultyFilter;
        }).toList();
      }

      return filteredList;
    });
  },
);