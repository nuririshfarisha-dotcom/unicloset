class ListingModel {
  final String listingId;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String size;
  final String condition;
  final String brand;
  final String imageUrl;
  final String meetUpLocation;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListingModel({
    required this.listingId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.size,
    required this.condition,
    required this.brand,
    required this.imageUrl,
    required this.meetUpLocation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'size': size,
      'condition': condition,
      'brand': brand,
      'imageUrl': imageUrl,
      'meetUpLocation': meetUpLocation,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map) {
    return ListingModel(
      listingId: map['listingId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      size: map['size'] ?? '',
      condition: map['condition'] ?? '',
      brand: map['brand'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      meetUpLocation: map['meetUpLocation'] ?? '',
      status: map['status'] ?? 'Available',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}