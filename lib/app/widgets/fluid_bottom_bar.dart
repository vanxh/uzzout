import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';

class FluidBottomBar extends StatelessWidget {
  final NavigationController controller;
  final List<FluidNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final Color? selectedBackgroundColor;

  const FluidBottomBar({
    super.key,
    required this.controller,
    required this.items,
    this.backgroundColor = Colors.white,
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = Colors.grey,
    this.selectedBackgroundColor = Colors.pink,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 90,
      alignment: Alignment.topCenter,
      child: Container(
        height: 65,
        width: screenWidth * 0.85,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            items.length,
            (index) => _buildNavItem(index, context),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, BuildContext context) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;

      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.changePage(index);
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: isSelected ? 45 : 40,
              height: isSelected ? 45 : 40,
              decoration: BoxDecoration(
                color:
                    isSelected ? selectedBackgroundColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  items[index].icon,
                  color: isSelected ? selectedIconColor : unselectedIconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class FluidNavBarItem {
  final IconData icon;
  final String label;

  const FluidNavBarItem({required this.icon, required this.label});
}
