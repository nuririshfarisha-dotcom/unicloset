import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/listing_model.dart';

class ListingCacheService {
  static const String _cachedListingsKey = 'cached_listings';

  Future<void> saveListings(List<ListingModel> listings) async {
    final prefs = await SharedPreferences.getInstance();

    final listingMapList = listings.map((listing) {
      return listing.toMap();
    }).toList();

    final encodedListings = jsonEncode(listingMapList);

    await prefs.setString(_cachedListingsKey, encodedListings);
  }

  Future<List<ListingModel>> getCachedListings() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_cachedListingsKey);

    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }

    final decodedData = jsonDecode(cachedData);

    if (decodedData is! List) {
      return [];
    }

    return decodedData.map((item) {
      final map = Map<String, dynamic>.from(item);
      return ListingModel.fromMap(map);
    }).toList();
  }

  Future<void> clearCachedListings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedListingsKey);
  }
}