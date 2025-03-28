import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/restaurant.dart';

class SwipePage extends StatelessWidget {
  const SwipePage({super.key});

  @override
  Widget build(BuildContext context) {
    final RestaurantController restaurantController =
        Get.find<RestaurantController>();
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade100, const Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.pink.shade400),
                        onPressed:
                            () => restaurantController.fetchRestaurants(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (!authController.isAuthenticated) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Authentication required',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Get.offAllNamed('/'),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (restaurantController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (restaurantController.errorMessage.value != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            restaurantController.errorMessage.value!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => restaurantController.fetchRestaurants(),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (restaurantController.restaurants.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_food, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No restaurants found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return RestaurantCardSwiper(
                    restaurants: restaurantController.restaurants,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestaurantCardSwiper extends StatefulWidget {
  final List<Restaurant> restaurants;

  const RestaurantCardSwiper({super.key, required this.restaurants});

  @override
  State<RestaurantCardSwiper> createState() => _RestaurantCardSwiperState();
}

class _RestaurantCardSwiperState extends State<RestaurantCardSwiper> {
  final CardSwiperController controller = CardSwiperController();

  final Map<String, int> _swipeStats = {'likes': 0, 'passes': 0};
  final Map<String, int> _totalRestaurantStats = {'likes': 0, 'dislikes': 0};
  String? _currentUserPreference;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentRestaurantStats();
  }

  Future<void> _fetchCurrentRestaurantStats() async {
    if (widget.restaurants.isEmpty) return;

    final RestaurantController restaurantController =
        Get.find<RestaurantController>();
    try {
      final preferences = await restaurantController.getRestaurantPreferences(
        widget.restaurants[_currentIndex].id,
      );

      setState(() {
        _totalRestaurantStats['likes'] = preferences['data']['likes'] ?? 0;
        _totalRestaurantStats['dislikes'] =
            preferences['data']['dislikes'] ?? 0;
        _currentUserPreference = preferences['data']['userPreference'];
      });
    } catch (error) {
      print('Error fetching restaurant stats: ${error.toString()}');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: widget.restaurants.length,
            onSwipe: _onSwipe,
            onUndo: _onUndo,
            numberOfCardsDisplayed: 2,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.all(24.0),
            isLoop: true,
            maxAngle: 25,
            threshold: 60,
            scale: 0.92,
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) =>
                    _buildRestaurantCard(widget.restaurants[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '👎 ${_totalRestaurantStats['dislikes']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 24),
              Text(
                '👍 ${_totalRestaurantStats['likes']}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => controller.swipe(CardSwiperDirection.left),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.white,
                  elevation: 8,
                ),
                child: const Icon(Icons.close, color: Colors.red, size: 30),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => controller.undo(),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white,
                  elevation: 8,
                ),
                child: const Icon(Icons.undo, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => controller.swipe(CardSwiperDirection.right),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.white,
                  elevation: 8,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.green,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final restaurant = widget.restaurants[previousIndex];
    final RestaurantController restaurantController =
        Get.find<RestaurantController>();

    if (direction == CardSwiperDirection.right) {
      setState(() {
        _swipeStats['likes'] = (_swipeStats['likes'] ?? 0) + 1;

        if (_currentUserPreference == 'dislike') {
          _totalRestaurantStats['dislikes'] =
              (_totalRestaurantStats['dislikes'] ?? 1) - 1;
        } else if (_currentUserPreference != 'like') {
          _totalRestaurantStats['likes'] =
              (_totalRestaurantStats['likes'] ?? 0) + 1;
        }
        _currentUserPreference = 'like';
      });

      restaurantController
          .saveRestaurantPreference(restaurant.id, 'like')
          .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Liked ${restaurant.name}'),
                duration: const Duration(seconds: 1),
              ),
            );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving preference: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          });
    } else if (direction == CardSwiperDirection.left) {
      setState(() {
        _swipeStats['passes'] = (_swipeStats['passes'] ?? 0) + 1;

        if (_currentUserPreference == 'like') {
          _totalRestaurantStats['likes'] =
              (_totalRestaurantStats['likes'] ?? 1) - 1;
        } else if (_currentUserPreference != 'dislike') {
          _totalRestaurantStats['dislikes'] =
              (_totalRestaurantStats['dislikes'] ?? 0) + 1;
        }
        _currentUserPreference = 'dislike';
      });

      restaurantController
          .saveRestaurantPreference(restaurant.id, 'dislike')
          .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Passed on ${restaurant.name}'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.grey,
              ),
            );
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving preference: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          });
    }

    if (currentIndex != null) {
      _currentIndex = currentIndex;
      _fetchCurrentRestaurantStats();
    }

    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    final restaurant = widget.restaurants[currentIndex];
    final RestaurantController restaurantController =
        Get.find<RestaurantController>();

    if (direction == CardSwiperDirection.right) {
      setState(() {
        _swipeStats['likes'] = (_swipeStats['likes'] ?? 1) - 1;

        if (_totalRestaurantStats['likes'] != null &&
            _totalRestaurantStats['likes']! > 0) {
          _totalRestaurantStats['likes'] = _totalRestaurantStats['likes']! - 1;
        }
        _totalRestaurantStats['dislikes'] =
            (_totalRestaurantStats['dislikes'] ?? 0) + 1;
        _currentUserPreference = 'dislike';
      });

      restaurantController
          .saveRestaurantPreference(restaurant.id, 'dislike')
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error updating preference: ${error.toString()}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }

            return {} as Map<String, dynamic>;
          });
    } else if (direction == CardSwiperDirection.left) {
      setState(() {
        _swipeStats['passes'] = (_swipeStats['passes'] ?? 1) - 1;

        if (_totalRestaurantStats['dislikes'] != null &&
            _totalRestaurantStats['dislikes']! > 0) {
          _totalRestaurantStats['dislikes'] =
              _totalRestaurantStats['dislikes']! - 1;
        }
        _totalRestaurantStats['likes'] =
            (_totalRestaurantStats['likes'] ?? 0) + 1;
        _currentUserPreference = 'like';
      });

      restaurantController
          .saveRestaurantPreference(restaurant.id, 'like')
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error updating preference: ${error.toString()}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }

            return {} as Map<String, dynamic>;
          });
    }

    _currentIndex = currentIndex;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Undo swipe for ${restaurant.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );

    return true;
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (restaurant.imageUrls != null &&
                          restaurant.imageUrls!.isNotEmpty)
                      ? Image.network(
                        restaurant.imageUrls!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                restaurant.address ?? 'No address',
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant.category != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              restaurant.category!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          restaurant.rating?.toStringAsFixed(1) ?? 'No rating',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (restaurant.distance != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDistance(restaurant.distance!),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    if (restaurant.description != null)
                      Expanded(
                        child: Text(
                          restaurant.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return "$meters m";
    } else {
      double km = meters / 1000.0;
      return "${km.toStringAsFixed(1)} km";
    }
  }
}
