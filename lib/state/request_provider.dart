import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/request_repository.dart';
import '../firebase/services/firestore_request_service.dart';
import '../models/request_model.dart';

final firestoreRequestServiceProvider = Provider<FirestoreRequestService>((ref) {
  return FirestoreRequestService();
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(
    requestService: ref.watch(firestoreRequestServiceProvider),
  );
});

final myRequestControllerProvider =
StateNotifierProvider<RequestController, AsyncValue<List<RequestModel>>>(
      (ref) {
    return RequestController(
      requestRepository: ref.watch(requestRepositoryProvider),
    );
  },
);

final incomingRequestControllerProvider =
StateNotifierProvider<RequestController, AsyncValue<List<RequestModel>>>(
      (ref) {
    return RequestController(
      requestRepository: ref.watch(requestRepositoryProvider),
    );
  },
);

final requestControllerProvider = myRequestControllerProvider;

class RequestController extends StateNotifier<AsyncValue<List<RequestModel>>> {
  final RequestRepository _requestRepository;

  RequestController({
    required RequestRepository requestRepository,
  })  : _requestRepository = requestRepository,
        super(const AsyncData([]));

  Future<void> createRequest({
    required RequestModel request,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      state = AsyncError(
        Exception('You are offline. Request submission is disabled.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _requestRepository.createRequest(request);
      await loadMyRequests(request.requesterId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadMyRequests(String requesterId) async {
    state = const AsyncLoading();

    try {
      final requests =
      await _requestRepository.getRequestsByRequester(requesterId);

      state = AsyncData(requests);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadRequestsForMyListings(String listingOwnerId) async {
    state = const AsyncLoading();

    try {
      final requests =
      await _requestRepository.getRequestsForListingOwner(listingOwnerId);

      state = AsyncData(requests);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    required String sellerResponse,
    required String currentUserId,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      state = AsyncError(
        Exception('You are offline. Request status update is disabled.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await _requestRepository.updateRequestStatus(
        requestId: requestId,
        status: status,
        sellerResponse: sellerResponse,
      );

      await loadRequestsForMyListings(currentUserId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}