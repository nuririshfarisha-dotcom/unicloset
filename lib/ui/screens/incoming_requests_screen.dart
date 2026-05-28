import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request_model.dart';
import '../../state/auth_provider.dart';
import '../../state/connectivity_provider.dart';
import '../../state/request_provider.dart';

class IncomingRequestsScreen extends ConsumerStatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  ConsumerState<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState
    extends ConsumerState<IncomingRequestsScreen> {
  bool hasLoadedRequests = false;

  Future<String?> showSellerResponseDialog({
    required BuildContext context,
    required String title,
    required String hintText,
  }) async {
    final TextEditingController responseController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: responseController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final response = responseController.text.trim();

                if (response.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, response);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    responseController.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final requestState = ref.watch(incomingRequestControllerProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isOnline = connectivityState.value ?? true;

    if (currentUser != null && !hasLoadedRequests) {
      hasLoadedRequests = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(incomingRequestControllerProvider.notifier)
            .loadRequestsForMyListings(currentUser.uid);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: currentUser == null
              ? const Center(
            child: Text('You must login to view incoming requests.'),
          )
              : Column(
            children: [
              connectivityState.when(
                data: (online) {
                  if (online) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'You are offline. Request status updates are disabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inbox,
                          color: Color(0xFF6FA878),
                          size: 32,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Requests for Your Listings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: requestState.when(
                      data: (requests) {
                        if (requests.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No incoming requests yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Buyer requests for your listings will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(
                              incomingRequestControllerProvider
                                  .notifier,
                            )
                                .loadRequestsForMyListings(
                              currentUser.uid,
                            );
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final request = requests[index];

                              return IncomingRequestCard(
                                request: request,
                                isOnline: isOnline,
                                onAccept: () async {
                                  final sellerResponse =
                                  await showSellerResponseDialog(
                                    context: context,
                                    title: 'Confirm Request',
                                    hintText:
                                    'Example: Confirmed. Meet at PETARY tomorrow at 3 PM.',
                                  );

                                  if (sellerResponse == null ||
                                      sellerResponse.trim().isEmpty) {
                                    return;
                                  }

                                  await ref
                                      .read(
                                    incomingRequestControllerProvider
                                        .notifier,
                                  )
                                      .updateRequestStatus(
                                    requestId: request.requestId,
                                    status: 'Accepted',
                                    sellerResponse: sellerResponse,
                                    currentUserId: currentUser.uid,
                                    isOnline: isOnline,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Request accepted.'),
                                    ),
                                  );
                                },
                                onReject: () async {
                                  final sellerResponse =
                                  await showSellerResponseDialog(
                                    context: context,
                                    title: 'Reject Request',
                                    hintText:
                                    'Example: Sorry, this item is no longer available.',
                                  );

                                  if (sellerResponse == null ||
                                      sellerResponse.trim().isEmpty) {
                                    return;
                                  }

                                  await ref
                                      .read(
                                    incomingRequestControllerProvider
                                        .notifier,
                                  )
                                      .updateRequestStatus(
                                    requestId: request.requestId,
                                    status: 'Rejected',
                                    sellerResponse: sellerResponse,
                                    currentUserId: currentUser.uid,
                                    isOnline: isOnline,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Request rejected.'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                      loading: () {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      error: (error, stackTrace) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncomingRequestCard extends StatelessWidget {
  final RequestModel request;
  final bool isOnline;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const IncomingRequestCard({
    super.key,
    required this.request,
    required this.isOnline,
    required this.onAccept,
    required this.onReject,
  });

  String formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final statusLower = status.toLowerCase();
    final isPending = statusLower == 'pending';

    Color statusColor;

    if (statusLower == 'accepted') {
      statusColor = Colors.green;
    } else if (statusLower == 'rejected') {
      statusColor = Colors.red;
    } else if (statusLower == 'completed') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: request.listingImageUrl.isEmpty
                  ? const Icon(
                Icons.image,
                color: Colors.grey,
              )
                  : Image.network(
                request.listingImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${request.listingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Buyer: ${request.requesterName}'),
                  Text('Phone: ${request.requesterPhone}'),
                  Text('Date: ${formatDate(request.createdAt)}'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Buyer meet-up note: ${request.meetUpNote}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Seller response: ${request.sellerResponse}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isPending && isOnline ? onAccept : null,
                        child: const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: isPending && isOnline ? onReject : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}