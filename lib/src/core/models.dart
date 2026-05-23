part of '../../main.dart';

class AiRecommendation {
  const AiRecommendation({
    required this.cardType,
    required this.storeName,
    required this.reason,
  });

  final String cardType;
  final String storeName;
  final String reason;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      cardType: (json['card_type'] as String?)?.trim().isNotEmpty == true
          ? (json['card_type'] as String).trim()
          : '추천U',
      storeName: (json['store_name'] as String?)?.trim().isNotEmpty == true
          ? (json['store_name'] as String).trim()
          : '이름 없는 가게',
      reason: (json['reason'] as String?)?.trim().isNotEmpty == true
          ? (json['reason'] as String).trim()
          : '입력한 조건과 잘 맞는 가게예요.',
    );
  }

  Map<String, dynamic> toJson() {
    return {'card_type': cardType, 'store_name': storeName, 'reason': reason};
  }
}

class DongNeuStore {
  const DongNeuStore({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.description,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.priceRange,
    this.openingHours,
    this.phone,
    required this.tags,
    required this.features,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String? description;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? priceRange;
  final String? openingHours;
  final String? phone;
  final List<String> tags;
  final List<String> features;

  factory DongNeuStore.fromJson(Map<String, dynamic> json) {
    return DongNeuStore(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '이름 없는 가게',
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : '카테고리 없음',
      address: (json['address'] as String?)?.trim().isNotEmpty == true
          ? (json['address'] as String).trim()
          : '주소 정보 없음',
      description: (json['description'] as String?)?.trim(),
      imageUrl: (json['image_url'] as String?)?.trim(),
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '') ?? 0,
      priceRange: (json['price_range'] as String?)?.trim(),
      openingHours: (json['opening_hours'] as String?)?.trim(),
      phone: (json['phone'] as String?)?.trim(),
      tags: _stringListFromDynamic(json['tags']),
      features: _stringListFromDynamic(json['features']),
    );
  }

  String get ratingLabel => rating == 0 ? '-' : rating.toStringAsFixed(1);
}

class StoreMenuItem {
  const StoreMenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isRepresentative,
  });

  final String id;
  final String name;
  final String? description;
  final int price;
  final bool isRepresentative;

  factory StoreMenuItem.fromJson(Map<String, dynamic> json) {
    return StoreMenuItem(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '이름 없는 메뉴',
      description: (json['description'] as String?)?.trim(),
      price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      isRepresentative: json['is_representative'] == true,
    );
  }
}

List<String> _stringListFromDynamic(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

String _formatWon(int price) {
  final text = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '$buffer원';
}

class AddressSearchResult {
  const AddressSearchResult({
    required this.address,
    this.roadAddress,
    this.lat,
    this.lng,
  });

  final String address;
  final String? roadAddress;
  final double? lat;
  final double? lng;

  String get displayAddress =>
      roadAddress?.isNotEmpty == true ? roadAddress! : address;

  factory AddressSearchResult.fromKakao(Map<String, dynamic> json) {
    final addressData = json['address'];
    final roadAddressData = json['road_address'];
    final addressName = addressData is Map
        ? addressData['address_name'] as String?
        : null;
    final roadAddressName = roadAddressData is Map
        ? roadAddressData['address_name'] as String?
        : null;
    return AddressSearchResult(
      address: addressName ?? roadAddressName ?? '주소 정보 없음',
      roadAddress: roadAddressName,
      lat: double.tryParse(json['y']?.toString() ?? ''),
      lng: double.tryParse(json['x']?.toString() ?? ''),
    );
  }
}

class _MenuDraft {
  _MenuDraft();

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}
