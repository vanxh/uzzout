class Restaurant {
  final String id; // fsq_id from Foursquare
  final String name;
  final String? description;
  final String? address;
  final List<String>? imageUrls;
  final double? rating;
  final String? category;
  final List<Map<String, dynamic>>? categories;
  final int? price;
  final String? tel;
  final String? website;
  final int? distance;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? hours;
  final String? closedBucket;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? geocodes;
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? social_media;
  final Map<String, dynamic>? stats;
  final String? timezone;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.imageUrls,
    this.rating,
    this.category,
    this.categories,
    this.price,
    this.tel,
    this.website,
    this.distance,
    this.latitude,
    this.longitude,
    this.hours,
    this.closedBucket,
    this.location,
    this.geocodes,
    this.features,
    this.social_media,
    this.stats,
    this.timezone,
  });

  factory Restaurant.fromFoursquare(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final String formattedAddress =
        location?['formatted_address'] as String? ?? '';

    final geocodes = json['geocodes'] as Map<String, dynamic>?;
    final main = geocodes?['main'] as Map<String, dynamic>?;
    final double? lat = main?['latitude'] as double?;
    final double? lng = main?['longitude'] as double?;

    final price = json['price'] as int?;

    final categories = json['categories'] as List<dynamic>?;
    final String? categoryName =
        categories != null && categories.isNotEmpty
            ? (categories[0] as Map<String, dynamic>)['name'] as String?
            : null;

    final List<String> photoUrls = [];
    if (json['photos'] != null && json['photos'] is List<dynamic>) {
      final photos = json['photos'] as List<dynamic>;
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

    return Restaurant(
      id: json['fsq_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: formattedAddress,
      imageUrls: photoUrls.isNotEmpty ? photoUrls : null,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      category: categoryName,
      categories: categories?.cast<Map<String, dynamic>>(),
      price: price,
      tel: json['tel'] as String?,
      website: json['website'] as String?,
      distance:
          json['distance'] != null ? (json['distance'] as num).toInt() : null,
      latitude: lat,
      longitude: lng,
      hours: json['hours'] as Map<String, dynamic>?,
      closedBucket: json['closed_bucket'] as String?,
      location: location,
      geocodes: geocodes,
      features: json['features'] as Map<String, dynamic>?,
      social_media: json['social_media'] as Map<String, dynamic>?,
      stats: json['stats'] as Map<String, dynamic>?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'imageUrls': imageUrls,
      'rating': rating,
      'category': category,
      'categories': categories,
      'price': price,
      'tel': tel,
      'website': website,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
      'closedBucket': closedBucket,
      'location': location,
      'geocodes': geocodes,
      'features': features,
      'social_media': social_media,
      'stats': stats,
      'timezone': timezone,
    };
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final List<String>? imageUrlsList =
        json['imageUrls'] != null
            ? List<String>.from(json['imageUrls'] as List)
            : null;

    return Restaurant(
      id: json['id'] as String? ?? json['fsq_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      imageUrls: imageUrlsList,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      category: json['category'] as String?,
      categories: json['categories']?.cast<Map<String, dynamic>>(),
      price: json['price'] as int?,
      tel: json['tel'] as String?,
      website: json['website'] as String?,
      distance:
          json['distance'] != null ? (json['distance'] as num).toInt() : null,
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
      hours: json['hours'] as Map<String, dynamic>?,
      closedBucket: json['closed_bucket'] as String?,
      location: json['location'] as Map<String, dynamic>?,
      geocodes: json['geocodes'] as Map<String, dynamic>?,
      features: json['features'] as Map<String, dynamic>?,
      social_media: json['social_media'] as Map<String, dynamic>?,
      stats: json['stats'] as Map<String, dynamic>?,
      timezone: json['timezone'] as String?,
    );
  }
}
