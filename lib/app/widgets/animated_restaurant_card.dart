import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryWithIcon {
  final String name;
  final String? iconUrl;

  CategoryWithIcon(this.name, this.iconUrl);
}

class AnimatedRestaurantCard extends StatefulWidget {
  final dynamic restaurant;

  const AnimatedRestaurantCard({super.key, required this.restaurant});

  @override
  State<AnimatedRestaurantCard> createState() => _AnimatedRestaurantCardState();
}

class _AnimatedRestaurantCardState extends State<AnimatedRestaurantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String? _getFsqId() {
    try {
      return widget.restaurant.id?.toString() ??
          widget.restaurant.fsq_id?.toString();
    } catch (e) {
      return null;
    }
  }

  String _getRestaurantType() {
    try {
      if (widget.restaurant.categories != null &&
          widget.restaurant.categories is List &&
          widget.restaurant.categories.isNotEmpty) {
        return widget.restaurant.categories[0]["name"] ?? "Restaurant";
      } else if (widget.restaurant.cuisineType != null) {
        return widget.restaurant.cuisineType;
      } else if (widget.restaurant.cuisine != null) {
        return widget.restaurant.cuisine;
      } else if (widget.restaurant.category != null) {
        return widget.restaurant.category;
      }
      return "Restaurant";
    } catch (e) {
      return "Restaurant";
    }
  }

  List<CategoryWithIcon> _getCategoriesWithIcons() {
    try {
      List<CategoryWithIcon> categories = [];

      if (widget.restaurant.categories != null &&
          widget.restaurant.categories is List) {
        for (var category in widget.restaurant.categories) {
          String name = category["name"] ?? category.toString();
          String? iconUrl;

          if (category["icon"] != null) {
            final prefix = category["icon"]["prefix"] as String?;
            final suffix = category["icon"]["suffix"] as String?;

            if (prefix != null && suffix != null) {
              iconUrl = "${prefix}120$suffix";
            }
          }

          categories.add(CategoryWithIcon(name, iconUrl));
        }
      } else if (widget.restaurant.cuisineType != null) {
        categories.add(
          CategoryWithIcon(widget.restaurant.cuisineType.toString(), null),
        );
      } else if (widget.restaurant.cuisine != null) {
        categories.add(
          CategoryWithIcon(widget.restaurant.cuisine.toString(), null),
        );
      } else if (widget.restaurant.category != null) {
        categories.add(
          CategoryWithIcon(widget.restaurant.category.toString(), null),
        );
      }

      if (categories.isEmpty) {
        categories.add(CategoryWithIcon(_getRestaurantType(), null));
      }

      return categories;
    } catch (e) {
      return [CategoryWithIcon(_getRestaurantType(), null)];
    }
  }

  bool _isOpenNow() {
    try {
      if (widget.restaurant.hours != null) {
        if (widget.restaurant.hours!['open_now'] != null) {
          return widget.restaurant.hours!['open_now'] == true;
        }
      }

      if (widget.restaurant.closedBucket != null) {
        return widget.restaurant.closedBucket == "LikelyOpen" ||
            widget.restaurant.closedBucket == "Open";
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  String _getOpenHoursText() {
    try {
      if (widget.restaurant.hours != null) {
        if (widget.restaurant.hours!['display'] != null) {
          return widget.restaurant.hours!['display'];
        }
        return _isOpenNow() ? "Open Now" : "Closed";
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  String _getAddress() {
    try {
      if (widget.restaurant.address != null &&
          widget.restaurant.address!.isNotEmpty) {
        return widget.restaurant.address!;
      }

      if (widget.restaurant.location != null) {
        if (widget.restaurant.location!['formatted_address'] != null) {
          return widget.restaurant.location!['formatted_address'];
        }

        List<String> addressParts = [];
        if (widget.restaurant.location!['address'] != null) {
          addressParts.add(widget.restaurant.location!['address']);
        }

        String? crossStreet = widget.restaurant.location!['cross_street'];
        if (crossStreet != null && crossStreet.isNotEmpty) {
          addressParts.add(crossStreet);
        }

        if (widget.restaurant.location!['locality'] != null) {
          addressParts.add(widget.restaurant.location!['locality']);
        } else if (widget.restaurant.location!['region'] != null) {
          addressParts.add(widget.restaurant.location!['region']);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(", ");
        }
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  String? _getLocality() {
    try {
      if (widget.restaurant.location != null) {
        if (widget.restaurant.location!['locality'] != null) {
          return widget.restaurant.location!['locality'];
        } else if (widget.restaurant.location!['region'] != null) {
          return widget.restaurant.location!['region'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  int? _getDistance() {
    try {
      if (widget.restaurant.distance != null) {
        return widget.restaurant.distance;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  String _formatDistance(int? meters) {
    if (meters == null) return "";

    if (meters < 1000) {
      return "$meters m";
    } else {
      double km = meters / 1000.0;
      return "${km.toStringAsFixed(1)} km";
    }
  }

  double _getRating() {
    try {
      return (widget.restaurant.rating ?? 0) / 2;
    } catch (e) {
      return 0;
    }
  }

  void _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
          ),
        );
      }
    }
  }

  String _getDescription() {
    try {
      return widget.restaurant.description ?? '';
    } catch (e) {
      return '';
    }
  }

  bool _hasDelivery() {
    try {
      if (widget.restaurant.features != null &&
          widget.restaurant.features!['services'] != null &&
          widget.restaurant.features!['services']['delivery'] != null) {
        return widget.restaurant.features!['services']['delivery'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _getAttributes() {
    try {
      if (widget.restaurant.features != null &&
          widget.restaurant.features!['attributes'] != null) {
        return widget.restaurant.features!['attributes'];
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  void _openMaps() {
    try {
      double? lat;
      double? lng;

      if (widget.restaurant.latitude != null &&
          widget.restaurant.longitude != null) {
        lat = widget.restaurant.latitude;
        lng = widget.restaurant.longitude;
      } else if (widget.restaurant.geocodes != null &&
          widget.restaurant.geocodes!['main'] != null) {
        lat = widget.restaurant.geocodes!['main']['latitude'];
        lng = widget.restaurant.geocodes!['main']['longitude'];
      }

      if (lat != null && lng != null) {
        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        _launchUrl(url);
      } else {
        final address = _getAddress();
        if (address.isNotEmpty) {
          final url =
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
          _launchUrl(url);
        }
      }
    } catch (e) {
      final address = _getAddress();
      if (address.isNotEmpty) {
        final url =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
        _launchUrl(url);
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    List<Widget> features = [];

    try {
      if (widget.restaurant.features != null) {
        final amenities = widget.restaurant.features!['amenities'];
        if (amenities != null) {
          final wifiStatus = amenities['wifi'];
          if (wifiStatus != null) {
            if (wifiStatus == "free") {
              features.add(_buildFeatureItem(Icons.wifi, 'Free WiFi'));
            } else if (wifiStatus == "paid") {
              features.add(_buildFeatureItem(Icons.wifi, 'Paid WiFi'));
            } else if (wifiStatus != "n") {
              features.add(_buildFeatureItem(Icons.wifi, 'WiFi Available'));
            }
          }

          final hasOutdoorSeating = amenities['outdoor_seating'] == true;
          if (hasOutdoorSeating) {
            features.add(_buildFeatureItem(Icons.deck, 'Outdoor Seating'));
          }

          final hasLiveMusic = amenities['live_music'] == true;
          if (hasLiveMusic) {
            features.add(_buildFeatureItem(Icons.music_note, 'Live Music'));
          }
        }

        final services = widget.restaurant.features!['services'];
        if (services != null && services['dine_in'] != null) {
          final dineIn = services['dine_in'];
          final acceptsReservations = dineIn['reservations'] == true;
          if (acceptsReservations) {
            features.add(
              _buildFeatureItem(Icons.calendar_today, 'Reservations'),
            );
          }
        }

        final payment = widget.restaurant.features!['payment'];
        if (payment != null && payment['credit_cards'] != null) {
          final creditCards = payment['credit_cards'];
          final acceptsCreditCards =
              creditCards['accepts_credit_cards'] == true;
          if (acceptsCreditCards) {
            features.add(_buildFeatureItem(Icons.credit_card, 'Credit Cards'));
          }
        }

        final attributes = _getAttributes();
        if (attributes.isNotEmpty) {
          if (attributes['clean'] != null) {
            features.add(
              _buildFeatureItem(
                Icons.cleaning_services,
                'Cleanliness: ${attributes['clean']}',
              ),
            );
          }

          if (attributes['quick_bite'] != null) {
            features.add(
              _buildFeatureItem(
                Icons.timer,
                'Quick Bite: ${attributes['quick_bite']}',
              ),
            );
          }

          if (attributes['service_quality'] != null) {
            features.add(
              _buildFeatureItem(
                Icons.room_service,
                'Service: ${attributes['service_quality']}',
              ),
            );
          }

          if (attributes['value_for_money'] != null) {
            features.add(
              _buildFeatureItem(
                Icons.attach_money,
                'Value: ${attributes['value_for_money']}',
              ),
            );
          }

          if (attributes['good_for_dogs'] != null) {
            final dogFriendly = attributes['good_for_dogs'] != 'Poor';
            if (dogFriendly) {
              features.add(_buildFeatureItem(Icons.pets, 'Dog Friendly'));
            }
          }

          if (attributes['noisy'] != null) {
            features.add(
              _buildFeatureItem(
                Icons.volume_up,
                'Noise: ${attributes['noisy']}',
              ),
            );
          }
        }
      }
    } catch (e) {
      // DO NOTHING
    }

    if (features.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: features),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinks() {
    List<Widget> socialLinks = [];

    try {
      if (widget.restaurant.social_media != null) {
        final String? facebookId =
            widget.restaurant.social_media!['facebook_id'];
        if (facebookId != null && facebookId.isNotEmpty) {
          socialLinks.add(
            _buildSocialButton(
              icon: Icons.facebook,
              color: Colors.blue[800]!,
              onTap: () => _launchUrl('https://facebook.com/$facebookId'),
            ),
          );
        }

        final String? instagram = widget.restaurant.social_media!['instagram'];
        if (instagram != null && instagram.isNotEmpty) {
          socialLinks.add(
            _buildSocialButton(
              icon: FontAwesomeIcons.instagram,
              color: Colors.purple,
              onTap: () => _launchUrl('https://instagram.com/$instagram'),
              label: '@$instagram',
            ),
          );
        }

        final String? twitter = widget.restaurant.social_media!['twitter'];
        if (twitter != null && twitter.isNotEmpty) {
          socialLinks.add(
            _buildSocialButton(
              icon: FontAwesomeIcons.xTwitter,
              color: Colors.grey[800]!,
              onTap: () => _launchUrl('https://twitter.com/$twitter'),
              label: '@$twitter',
            ),
          );
        }
      }
    } catch (e) {
      // DO NOTHING
    }

    if (socialLinks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Social Media',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: socialLinks),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<CategoryWithIcon> categoriesWithIcons =
        _getCategoriesWithIcons();
    final List<String> photoUrls = _getPhotoUrls();
    final double rating = _getRating();
    final int? distance = _getDistance();
    final String description = _getDescription();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag:
                      'restaurant-${_getFsqId() ?? widget.restaurant.name ?? "restaurant"}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child:
                        photoUrls.isNotEmpty
                            ? Stack(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.1),
                                        Colors.black.withValues(alpha: 0.5),
                                      ],
                                    ),
                                  ),
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemCount: photoUrls.length,
                                    itemBuilder: (context, index) {
                                      return Image.network(
                                        photoUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.restaurant,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                if (photoUrls.length > 1)
                                  Positioned(
                                    bottom: 10,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        photoUrls.length,
                                        (index) => AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          height: 6,
                                          width: _currentPage == index ? 18 : 6,
                                          decoration: BoxDecoration(
                                            color:
                                                _currentPage == index
                                                    ? Colors.white
                                                    : Colors.white.withValues(
                                                      alpha: 0.5,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _isOpenNow()
                                              ? Colors.green
                                              : Colors.red,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _isOpenNow() ? 'OPEN' : 'CLOSED',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child:
                                      _hasDelivery()
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.delivery_dining,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'DELIVERY',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : const SizedBox(),
                                ),
                                if (rating > 0)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (distance != null)
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.directions,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDistance(distance),
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.restaurant,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.restaurant.name ?? "Restaurant",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      categoriesWithIcons.map((category) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[600]!,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (category.iconUrl != null)
                                                Image.network(
                                                  category.iconUrl!,
                                                  width: 16,
                                                  height: 16,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return const SizedBox(
                                                      width: 0,
                                                    );
                                                  },
                                                ),
                                              if (category.iconUrl != null)
                                                const SizedBox(width: 4),
                                              Text(
                                                category.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                          _buildPriceLevel(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_getLocality() != null || distance != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_getLocality() != null) ...[
                                const Icon(
                                  Icons.location_city,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getLocality()!,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (_getLocality() != null &&
                                  distance != null) ...[
                                const SizedBox(width: 12),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (distance != null) ...[
                                const Icon(
                                  Icons.directions,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistance(distance),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      if (_getAddress().isNotEmpty)
                        InkWell(
                          onTap: () => _openMaps(),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getAddress(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_getOpenHoursText().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: _isOpenNow() ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getOpenHoursText(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      _isOpenNow() ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_getPhoneNumber() != null)
                              _buildActionButton(
                                icon: Icons.phone,
                                label: 'Call',
                                color: Colors.green,
                                onTap: () => _makePhoneCall(_getPhoneNumber()),
                              ),

                            if (_getWebsite() != null)
                              _buildActionButton(
                                icon: Icons.language,
                                label: 'Website',
                                color: Colors.blue,
                                onTap: () => _launchUrl(_getWebsite()),
                              ),

                            _buildActionButton(
                              icon: Icons.map,
                              label: 'Directions',
                              color: Colors.orange,
                              onTap: () => _openMaps(),
                            ),
                          ],
                        ),
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      _buildFeaturesList(),

                      _buildSocialMediaLinks(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceLevel() {
    int priceLevel = 0;
    try {
      priceLevel = widget.restaurant.price ?? 0;
    } catch (e) {
      priceLevel = 0;
    }

    if (priceLevel <= 0) return const SizedBox();

    String priceText = '';
    for (int i = 0; i < priceLevel; i++) {
      priceText += '\$';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priceText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }

  String? _getPhoneNumber() {
    try {
      return widget.restaurant.tel;
    } catch (e) {
      return null;
    }
  }

  String? _getWebsite() {
    try {
      return widget.restaurant.website;
    } catch (e) {
      return null;
    }
  }

  List<String> _getPhotoUrls() {
    try {
      if (widget.restaurant.imageUrls != null &&
          widget.restaurant.imageUrls!.isNotEmpty) {
        return widget.restaurant.imageUrls!;
      }

      final List<String> urls = [];
      if (widget.restaurant.photos != null &&
          widget.restaurant.photos is List) {
        for (var photo in widget.restaurant.photos) {
          if (photo is Map<String, dynamic>) {
            final prefix = photo['prefix'] as String?;
            final suffix = photo['suffix'] as String?;
            if (prefix != null && suffix != null) {
              urls.add('${prefix}original$suffix');
            }
          }
        }
      }
      return urls;
    } catch (e) {
      return [];
    }
  }
}
