import '../../firebase/services/firestore_listing_service.dart';
import '../../local/listing_cache_service.dart';
import '../../models/listing_model.dart';

class ListingRepository {
  final FirestoreListingService _listingService;
  final ListingCacheService _cacheService;

  ListingRepository({
    required FirestoreListingService listingService,
    required ListingCacheService cacheService,
  })  : _listingService = listingService,
        _cacheService = cacheService;

  Future<List<ListingModel>> getAllListings({
    required bool isOnline,
  }) async {
    if (isOnline) {
      final listings = await _listingService.getAllListings();

      await _cacheService.saveListings(listings);

      return listings;
    }

    return await _cacheService.getCachedListings();
  }

  Future<List<ListingModel>> getListingsByOwner(String ownerId) async {
    return await _listingService.getListingsByOwner(ownerId);
  }

  Future<void> createListing(ListingModel listing) async {
    await _listingService.createListing(listing);
  }

  Future<void> markListingAsSold({
    required String listingId,
    required String currentUserId,
  }) async {
    await _listingService.markListingAsSold(
      listingId: listingId,
      currentUserId: currentUserId,
    );
  }
}