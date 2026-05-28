import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/listing_model.dart';

class FirestoreListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listingsCollection {
    return _firestore.collection('listings');
  }

  Future<List<ListingModel>> getAllListings() async {
    final snapshot = await _listingsCollection.get();

    final listings = snapshot.docs.map((doc) {
      final data = doc.data();

      return ListingModel.fromMap({
        ...data,
        'listingId': data['listingId'] ?? doc.id,
      });
    }).toList();

    listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return listings;
  }

  Future<List<ListingModel>> getListingsByOwner(String ownerId) async {
    final snapshot =
    await _listingsCollection.where('ownerId', isEqualTo: ownerId).get();

    final listings = snapshot.docs.map((doc) {
      final data = doc.data();

      return ListingModel.fromMap({
        ...data,
        'listingId': data['listingId'] ?? doc.id,
      });
    }).toList();

    listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return listings;
  }

  Future<void> createListing(ListingModel listing) async {
    await _listingsCollection.doc(listing.listingId).set(listing.toMap());
  }

  Future<void> markListingAsSold({
    required String listingId,
    required String currentUserId,
  }) async {
    final docRef = _listingsCollection.doc(listingId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw Exception('Listing not found.');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Listing data is empty.');
    }

    if (data['ownerId'] != currentUserId) {
      throw Exception('You can only update your own listing.');
    }

    await docRef.update({
      'status': 'Sold',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}