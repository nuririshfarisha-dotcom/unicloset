import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/listing_model.dart';
import '../../state/auth_provider.dart';
import '../../state/connectivity_provider.dart';
import '../../state/listing_provider.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController meetUpLocationController =
  TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    sizeController.dispose();
    conditionController.dispose();
    brandController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();
    meetUpLocationController.dispose();
    super.dispose();
  }

  Future<void> submitListing() async {
    final title = titleController.text.trim();
    final priceText = priceController.text.trim();
    final size = sizeController.text.trim();
    final condition = conditionController.text.trim();
    final brand = brandController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final description = descriptionController.text.trim();
    final meetUpLocation = meetUpLocationController.text.trim();

    if (title.isEmpty ||
        priceText.isEmpty ||
        size.isEmpty ||
        condition.isEmpty ||
        imageUrl.isEmpty ||
        description.isEmpty ||
        meetUpLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
        ),
      );
      return;
    }

    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid image URL starting with http or https.',
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price.'),
        ),
      );
      return;
    }

    final currentUser = ref.read(authRepositoryProvider).currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must login before creating a listing.'),
        ),
      );
      return;
    }

    final isOnline = ref.read(connectivityProvider).value ?? true;

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Listing submission is disabled.'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final listing = ListingModel(
      listingId: 'listing_${now.millisecondsSinceEpoch}',
      ownerId: currentUser.uid,
      title: title,
      description: description,
      price: price,
      size: size,
      condition: condition,
      brand: brand,
      imageUrl: imageUrl,
      meetUpLocation: meetUpLocation,
      status: 'Available',
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(listingControllerProvider.notifier).createListing(
      listing: listing,
      isOnline: isOnline,
    );

    final listingState = ref.read(listingControllerProvider);

    if (!mounted) return;

    listingState.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing created successfully.'),
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
    final listingState = ref.watch(listingControllerProvider);
    final isLoading = listingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Listing'),
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
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FA878),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Create New Listing',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F5D3A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Add clear details so buyers can understand the item easily.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Fields marked with * are required. For this app, use a direct image URL instead of gallery upload.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2F5D3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Item Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Clothes Title *',
                        prefixIcon: Icon(Icons.checkroom),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (RM) *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Size *',
                              hintText: 'S, M, L, XL',
                              prefixIcon: Icon(Icons.straighten),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: conditionController,
                            decoration: const InputDecoration(
                              labelText: 'Condition *',
                              hintText: 'New, Good, Used',
                              prefixIcon: Icon(Icons.verified),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand (Optional)',
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL *',
                        hintText:
                        'Paste a direct image link starting with https://',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: meetUpLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Meet-up / Pickup Location *',
                        hintText:
                        'Example: UNIMAS library, Kolej, faculty area',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : submitListing,
                        icon: isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.add),
                        label: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Add Listing'),
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