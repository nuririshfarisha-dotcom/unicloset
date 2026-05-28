import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/listing_model.dart';
import '../../state/auth_provider.dart';
import '../../state/connectivity_provider.dart';
import '../../state/listing_provider.dart';
import 'incoming_requests_screen.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  bool hasLoadedListings = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final listingsState = ref.watch(myListingControllerProvider);
    final connectivityState = ref.watch(connectivityProvider);
    final isOnline = connectivityState.value ?? true;

    if (currentUser != null && !hasLoadedListings) {
      hasLoadedListings = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(myListingControllerProvider.notifier)
            .loadMyListings(currentUser.uid);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: currentUser == null
              ? const Center(
            child: Text('You must login to view your listings.'),
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
                      'You are offline. Listing updates are disabled.',
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
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.list,
                              color: Color(0xFF6FA878),
                              size: 32,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Listings You Created',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Manage your posted clothes and view buyer requests.',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const IncomingRequestsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.inbox),
                            label: const Text('View Incoming Requests'),
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
                    child: listingsState.when(
                      data: (listings) {
                        if (listings.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'You have not created any listings yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                                .read(myListingControllerProvider.notifier)
                                .loadMyListings(currentUser.uid);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: listings.length,
                            itemBuilder: (context, index) {
                              final listing = listings[index];

                              return MyListingCard(
                                listing: listing,
                                isOnline: isOnline,
                                onMarkAsSold: () async {
                                  if (!isOnline) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You are offline. Listing update is disabled.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  await ref
                                      .read(
                                    myListingControllerProvider
                                        .notifier,
                                  )
                                      .markListingAsSold(
                                    listingId: listing.listingId,
                                    currentUserId: currentUser.uid,
                                    isOnline: isOnline,
                                  );

                                  await ref
                                      .read(
                                    homeListingControllerProvider
                                        .notifier,
                                  )
                                      .loadAllListings(
                                    isOnline: isOnline,
                                  );

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Listing marked as sold.',
                                      ),
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

class MyListingCard extends StatelessWidget {
  final ListingModel listing;
  final bool isOnline;
  final Future<void> Function() onMarkAsSold;

  const MyListingCard({
    super.key,
    required this.listing,
    required this.isOnline,
    required this.onMarkAsSold,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSold = listing.status.toLowerCase() == 'sold';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: listing.imageUrl.isEmpty
                  ? const Icon(
                Icons.image,
                color: Colors.grey,
              )
                  : Image.network(
                listing.imageUrl,
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
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${listing.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${listing.size} | ${listing.condition}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
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
                          color: isSold
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.status,
                          style: TextStyle(
                            color: isSold ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isSold || !isOnline ? null : onMarkAsSold,
                        child: const Text('Mark as Sold'),
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