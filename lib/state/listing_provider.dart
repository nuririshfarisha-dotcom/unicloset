import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/listing_repository.dart';
import '../firebase/services/firestore_listing_service.dart';
import '../local/listing_cache_service.dart';
import '../models/listing_model.dart';

final firestoreListingServiceProvider = Provider<FirestoreListingService>((ref) {
  return FirestoreListingService();
});

final listingCacheServiceProvider = Provider<ListingCacheService>((ref) {
  return ListingCacheService();
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(
    listingService: ref.watch(firestoreListingServiceProvider),
    cacheService: ref.watch(listingCacheServiceProvider),
  );
});

final homeListingControllerProvider =
StateNotifierProvider<ListingController, AsyncValue<List<ListingModel>>>(
      (ref) {
    return ListingController(
      listingRepository: ref.watch(listingRepositoryProvider),
    );
  },
);

final myListingControllerProvider =
StateNotifierProvider<ListingController, AsyncValue<List<ListingModel>>>(
      (ref) {
    return ListingController(
      listingRepository: ref.watch(listingRepositoryProvider),
    );
  },
);

// This keeps older screens working if they still use listingControllerProvider.
final listingControllerProvider = homeListingControllerProvider;

class ListingController extends StateNotifier<AsyncValue<List<ListingModel>>> {
  final ListingRepository _listingRepository;

  ListingController({
    required ListingRepository listingRepository,
  })  : _listingRepository = listingRepository,
        super(const AsyncData([]));

  Future<void> loadAllListings({
    required bool isOnline,
  }) async {
    state = const AsyncLoading();

    try {
      final listings = await _listingRepository.getAllListings(
        isOnline: isOnline,
      );

      state = AsyncData(listings);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadMyListings(String ownerId) async {
    state = const AsyncLoading();

    try {
      final listings = await _listingRepository.getListingsByOwner(ownerId);
      state = AsyncData(listings);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> createListing({
    required ListingModel listing,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      state = AsyncError(
        Exception('You are offline. Listing submission is disabled.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _listingRepository.createListing(listing);

      final listings = await _listingRepository.getAllListings(
        isOnline: true,
      );

      state = AsyncData(listings);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> markListingAsSold({
    required String listingId,
    required String currentUserId,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      state = AsyncError(
        Exception('You are offline. Listing update is disabled.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _listingRepository.markListingAsSold(
        listingId: listingId,
        currentUserId: currentUserId,
      );

      await loadMyListings(currentUserId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}