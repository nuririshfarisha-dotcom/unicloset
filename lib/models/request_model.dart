class RequestModel {
  final String requestId;
  final String listingId;
  final String listingOwnerId;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String meetUpNote;
  final String sellerResponse;
  final String listingTitle;
  final double listingPrice;
  final String listingImageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RequestModel({
    required this.requestId,
    required this.listingId,
    required this.listingOwnerId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    required this.meetUpNote,
    required this.sellerResponse,
    required this.listingTitle,
    required this.listingPrice,
    required this.listingImageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'listingId': listingId,
      'listingOwnerId': listingOwnerId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'meetUpNote': meetUpNote,
      'sellerResponse': sellerResponse,
      'listingTitle': listingTitle,
      'listingPrice': listingPrice,
      'listingImageUrl': listingImageUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      requestId: map['requestId'] ?? '',
      listingId: map['listingId'] ?? '',
      listingOwnerId: map['listingOwnerId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterPhone: map['requesterPhone'] ?? '',
      meetUpNote: map['meetUpNote'] ?? 'Not stated',
      sellerResponse: map['sellerResponse'] ?? 'No seller response yet.',
      listingTitle: map['listingTitle'] ?? 'Unknown item',
      listingPrice: (map['listingPrice'] ?? 0).toDouble(),
      listingImageUrl: map['listingImageUrl'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}