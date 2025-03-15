import 'package:flutter/material.dart';
import 'dart:math';

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
      duration: const Duration(milliseconds: 500),
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

  // Generate a colorful background based on restaurant type
  Color _getBackgroundColor() {
    switch (_currentPage) {
      case 0:
        return Colors.pink.shade200;
      case 1:
        return Colors.purple.shade200;
      case 2:
        return Colors.orange.shade200;
      default:
        return Colors.pink.shade200;
    }
  }

  // Safely get restaurant cuisine type or category
  String _getRestaurantType() {
    try {
      if (widget.restaurant.cuisineType != null) {
        return widget.restaurant.cuisineType;
      } else if (widget.restaurant.cuisine != null) {
        return widget.restaurant.cuisine;
      } else if (widget.restaurant.category != null) {
        return widget.restaurant.category;
      } else if (widget.restaurant.categories != null) {
        if (widget.restaurant.categories is List) {
          return (widget.restaurant.categories as List).join(', ');
        }
        return widget.restaurant.categories.toString();
      }
      return "Restaurant";
    } catch (e) {
      return "Restaurant";
    }
  }

  // Safely get restaurant categories as list
  List<String> _getCategories() {
    try {
      List<String> categories = [];

      // Try to get categories from the restaurant object
      if (widget.restaurant.categories != null &&
          widget.restaurant.categories is List) {
        categories = List<String>.from(widget.restaurant.categories);
      } else if (widget.restaurant.cuisineType != null) {
        categories = [widget.restaurant.cuisineType.toString()];
      } else if (widget.restaurant.cuisine != null) {
        categories = [widget.restaurant.cuisine.toString()];
      } else if (widget.restaurant.category != null) {
        categories = [widget.restaurant.category.toString()];
      }

      // If we still don't have any categories, use the restaurant type
      if (categories.isEmpty) {
        categories = [_getRestaurantType()];
      }

      return categories;
    } catch (e) {
      return [_getRestaurantType()];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = _getCategories();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildFoodCard(categories[index], index);
                    },
                  ),
                ),
              ),
              if (categories.length > 1) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        categories.asMap().entries.map((entry) {
                          return _buildCategoryTab(entry.value, entry.key);
                        }).toList(),
                  ),
                ),
              ] else
                const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodCard(String category, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Restaurant name at top left
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant.name ?? "Restaurant",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Centered food image with floating items
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main dish image
                _buildMainDishImage(),

                // Floating food elements
                ..._buildFloatingFoodItems(category),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDishImage() {
    return Container(
      height: 240,
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildRestaurantImage(),
      ),
    );
  }

  List<Widget> _buildFloatingFoodItems(String category) {
    // Get appropriate food items based on category
    List<Widget> items = [];

    // Color selection based on category type
    Color itemColor;
    if (category.toLowerCase().contains('italian') ||
        category.toLowerCase().contains('pizza')) {
      itemColor = Colors.red.shade300;
    } else if (category.toLowerCase().contains('asian') ||
        category.toLowerCase().contains('chinese')) {
      itemColor = Colors.amber.shade300;
    } else if (category.toLowerCase().contains('dessert') ||
        category.toLowerCase().contains('sweets')) {
      itemColor = Colors.pink.shade300;
    } else {
      itemColor = Colors.red.shade400;
    }

    // Add multiple floating items in different positions
    for (int i = 0; i < 8; i++) {
      items.add(
        Positioned(
          left: (i % 2 == 0) ? 30 + (i * 20) : null,
          right: (i % 2 != 0) ? 30 + ((i - 1) * 20) : null,
          top: (i < 4) ? 40 + (i * 40) : null,
          bottom: (i >= 4) ? 40 + ((i - 4) * 40) : null,
          child: Transform.rotate(
            angle: (i * 0.3),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    sin(_controller.value * 2 * 3.14 + i) * 10,
                    cos(_controller.value * 2 * 3.14 + i) * 10,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: itemColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return items;
  }

  // Build restaurant image with proper error handling
  Widget _buildRestaurantImage() {
    String? photoUrl;

    try {
      photoUrl = widget.restaurant.photoUrl;
    } catch (e) {
      photoUrl = null;
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        height: 240,
        width: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/placeholder_food.jpg',
            height: 240,
            width: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 240,
                width: 180,
                color: Colors.grey[200],
                child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
              );
            },
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 240,
            width: 180,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        height: 240,
        width: 180,
        color: Colors.grey[200],
        child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
      );
    }
  }

  Widget _buildCategoryTab(String category, int index) {
    final isSelected = index == _currentPage;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.black45,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
