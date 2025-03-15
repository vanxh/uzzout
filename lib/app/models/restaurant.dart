class Restaurant {
  final String id; // fsq_id from Foursquare
  final String name;
  final String? description;
  final String? address;
  final List<String>? imageUrls;
  final double? rating;
  final String? category;
  final int? priceLevel; // 1-4 representing price tiers
  final String? phone;
  final String? website;
  final double? distance; // in meters
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? hours;
  final bool isClosed;

  Restaurant({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.address,
    this.imageUrls,
    this.rating,
    this.category,
    this.priceLevel,
    this.phone,
    this.website,
    this.distance,
    this.hours,
    this.isClosed = false,
  });

  factory Restaurant.fromFoursquare(Map<String, dynamic> json) {
    // Extract location info
    final location = json['location'] as Map<String, dynamic>?;
    final String formattedAddress =
        location?['formatted_address'] as String? ?? '';

    // Extract coordinates
    final geocodes = json['geocodes'] as Map<String, dynamic>?;
    final main = geocodes?['main'] as Map<String, dynamic>?;
    final double lat = main?['latitude'] as double? ?? 0.0;
    final double lng = main?['longitude'] as double? ?? 0.0;

    // Extract price level
    final price = json['price'] as int?;

    // Extract category
    final categories = json['categories'] as List<dynamic>?;
    final String? categoryName =
        categories != null && categories.isNotEmpty
            ? (categories[0] as Map<String, dynamic>)['name'] as String?
            : null;

    // Extract photos
    final photos = json['photos'] as List<dynamic>?;
    final List<String> photoUrls = [];
    if (photos != null && photos.isNotEmpty) {
      for (var photo in photos) {
        if (photo is Map<String, dynamic>) {
          final prefix = photo['prefix'] as String?;
          final suffix = photo['suffix'] as String?;
          if (prefix != null && suffix != null) {
            photoUrls.add('${prefix}original$suffix');
          }
        }
      }
    }

    final closedBucket = json['closed_bucket'] as String?;
    final bool isClosed =
        closedBucket == 'Temporarily Closed' ||
        closedBucket == 'Permanently Closed';

    return Restaurant(
      id: json['fsq_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: formattedAddress,
      imageUrls: photoUrls.isNotEmpty ? photoUrls : null,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      category: categoryName,
      priceLevel: price,
      phone: json['tel'] as String?,
      website: json['website'] as String?,
      distance:
          json['distance'] != null
              ? (json['distance'] as num).toDouble()
              : null,
      latitude: lat,
      longitude: lng,
      hours: json['hours'] as Map<String, dynamic>?,
      isClosed: isClosed,
    );
  }
}
