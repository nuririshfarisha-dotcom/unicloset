import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/request_model.dart';

class FirestoreRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCollection {
    return _firestore.collection('requests');
  }

  Future<void> createRequest(RequestModel request) async {
    await _requestsCollection.doc(request.requestId).set(request.toMap());
  }

  Future<bool> hasActiveRequestForListing({
    required String requesterId,
    required String listingId,
  }) async {
    final snapshot = await _requestsCollection
        .where('requesterId', isEqualTo: requesterId)
        .get();

    final requests = snapshot.docs.map((doc) {
      final data = doc.data();

      return RequestModel.fromMap({
        ...data,
        'requestId': data['requestId'] ?? doc.id,
      });
    }).toList();

    return requests.any((request) {
      final sameListing = request.listingId == listingId;
      final status = request.status.toLowerCase();

      final activeStatus = status == 'pending' || status == 'accepted';

      return sameListing && activeStatus;
    });
  }

  Future<List<RequestModel>> getRequestsByRequester(String requesterId) async {
    final snapshot = await _requestsCollection
        .where('requesterId', isEqualTo: requesterId)
        .get();

    final requests = snapshot.docs.map((doc) {
      final data = doc.data();

      return RequestModel.fromMap({
        ...data,
        'requestId': data['requestId'] ?? doc.id,
      });
    }).toList();

    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  Future<List<RequestModel>> getRequestsForListingOwner(
      String listingOwnerId,
      ) async {
    final snapshot = await _requestsCollection
        .where('listingOwnerId', isEqualTo: listingOwnerId)
        .get();

    final requests = snapshot.docs.map((doc) {
      final data = doc.data();

      return RequestModel.fromMap({
        ...data,
        'requestId': data['requestId'] ?? doc.id,
      });
    }).toList();

    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return requests;
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    required String sellerResponse,
  }) async {
    await _requestsCollection.doc(requestId).update({
      'status': status,
      'sellerResponse': sellerResponse,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}