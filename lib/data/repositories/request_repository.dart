import '../../firebase/services/firestore_request_service.dart';
import '../../models/request_model.dart';

class RequestRepository {
  final FirestoreRequestService _requestService;

  RequestRepository({
    required FirestoreRequestService requestService,
  }) : _requestService = requestService;

  Future<void> createRequest(RequestModel request) async {
    final hasActiveRequest =
    await _requestService.hasActiveRequestForListing(
      requesterId: request.requesterId,
      listingId: request.listingId,
    );

    if (hasActiveRequest) {
      throw Exception(
        'You have already requested this item. Please wait for the seller response.',
      );
    }

    await _requestService.createRequest(request);
  }

  Future<List<RequestModel>> getRequestsByRequester(String requesterId) async {
    return await _requestService.getRequestsByRequester(requesterId);
  }

  Future<List<RequestModel>> getRequestsForListingOwner(
      String listingOwnerId,
      ) async {
    return await _requestService.getRequestsForListingOwner(listingOwnerId);
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    required String sellerResponse,
  }) async {
    await _requestService.updateRequestStatus(
      requestId: requestId,
      status: status,
      sellerResponse: sellerResponse,
    );
  }
}