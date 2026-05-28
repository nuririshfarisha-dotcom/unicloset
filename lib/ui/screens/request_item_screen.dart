import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/listing_model.dart';
import '../../models/request_model.dart';
import '../../state/auth_provider.dart';
import '../../state/connectivity_provider.dart';
import '../../state/request_provider.dart';

class RequestItemScreen extends ConsumerStatefulWidget {
  final ListingModel listing;

  const RequestItemScreen({
    super.key,
    required this.listing,
  });

  @override
  ConsumerState<RequestItemScreen> createState() => _RequestItemScreenState();
}

class _RequestItemScreenState extends ConsumerState<RequestItemScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController meetUpNoteController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    meetUpNoteController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    final requesterName = nameController.text.trim();
    final requesterPhone = phoneController.text.trim();
    final meetUpNote = meetUpNoteController.text.trim();

    if (requesterName.isEmpty ||
        requesterPhone.isEmpty ||
        meetUpNote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your name, phone number, and meet-up note.',
          ),
        ),
      );
      return;
    }

    if (widget.listing.status.toLowerCase() == 'sold') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is already sold.'),
        ),
      );
      return;
    }

    final currentUser = ref.read(authRepositoryProvider).currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must login before requesting an item.'),
        ),
      );
      return;
    }

    if (currentUser.uid == widget.listing.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot request your own listing.'),
        ),
      );
      return;
    }

    final isOnline = ref.read(connectivityProvider).value ?? true;

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Request submission is disabled.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final request = RequestModel(
      requestId: 'request_${now.millisecondsSinceEpoch}',
      listingId: widget.listing.listingId,
      requesterId: currentUser.uid,
      listingOwnerId: widget.listing.ownerId,
      requesterName: requesterName,
      requesterPhone: requesterPhone,
      meetUpNote: meetUpNote,
      sellerResponse: 'No seller response yet.',
      listingTitle: widget.listing.title,
      listingPrice: widget.listing.price,
      listingImageUrl: widget.listing.imageUrl,
      status: 'Pending',
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(requestControllerProvider.notifier).createRequest(
      request: request,
      isOnline: isOnline,
    );

    final requestState = ref.read(requestControllerProvider);

    if (!mounted) return;

    requestState.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully.'),
          ),
        );

        Navigator.pop(context);
      },
      loading: () {},
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestControllerProvider);
    final isLoading = requestState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Item'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.listing.imageUrl.isEmpty
                              ? const Icon(
                            Icons.image,
                            color: Colors.grey,
                          )
                              : Image.network(
                            widget.listing.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                        title: Text(
                          widget.listing.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'RM ${widget.listing.price.toStringAsFixed(2)} | Size: ${widget.listing.size}',
                        ),
                        trailing: Text(
                          widget.listing.status,
                          style: TextStyle(
                            color:
                            widget.listing.status.toLowerCase() == 'sold'
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Requester Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: meetUpNoteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Meet-up Note / Preferred Time *',
                        hintText: 'Example: Can meet at UNIMAS library at 3 PM.',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 28),
                          child: Icon(Icons.event_note),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade100,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collection Arrangement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'UniCloset uses Cash on Delivery or meet-up arrangement only. After submitting a request, the buyer and listing owner can arrange the collection outside the app.',
                          ),
                          SizedBox(height: 6),
                          Text(
                            'No online payment, cart, or checkout is included in this version of the app.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitRequest,
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Submit Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}