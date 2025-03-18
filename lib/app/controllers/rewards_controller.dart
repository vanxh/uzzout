import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RewardsController extends GetxController
    with GetTickerProviderStateMixin {
  late AnimationController wheelController;
  late Animation<double> wheelAnimation;

  var rotationAngle = 0.0.obs;

  var isSpinning = false.obs;

  final List<RewardItem> rewards = [
    RewardItem(name: '10%', color: const Color(0xFFFF5252), icon: Icons.sell),
    RewardItem(
      name: 'Drink',
      color: const Color(0xFF448AFF),
      icon: Icons.emoji_food_beverage,
    ),
    RewardItem(
      name: 'Dessert',
      color: const Color(0xFF66BB6A),
      icon: Icons.cake,
    ),
    RewardItem(
      name: '15%',
      color: const Color(0xFFFFB300),
      icon: Icons.money_off,
    ),
    RewardItem(
      name: 'Starter',
      color: const Color(0xFFAB47BC),
      icon: Icons.lunch_dining,
    ),
    RewardItem(
      name: '20%',
      color: const Color(0xFFEC407A),
      icon: Icons.card_giftcard,
    ),
    RewardItem(
      name: 'None',
      color: const Color(0xFF9E9E9E),
      icon: Icons.do_not_disturb_alt,
    ),
    RewardItem(
      name: 'Meal',
      color: const Color(0xFFFF9800),
      icon: Icons.dinner_dining,
    ),
  ];

  Rx<RewardItem?> currentReward = Rx<RewardItem?>(null);

  var userPoints = 100.obs;

  final int spinCost = 20;

  @override
  void onInit() {
    super.onInit();

    wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    wheelAnimation = CurvedAnimation(
      parent: wheelController,
      curve: Curves.easeOutExpo,
    );

    wheelAnimation.addListener(() {
      rotationAngle.value =
          wheelAnimation.value * 2 * pi * (5 + Random().nextDouble() * 5);
    });

    wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isSpinning.value = false;
        _calculateReward();
        wheelController.reset();
      }
    });
  }

  @override
  void onClose() {
    wheelController.dispose();
    super.onClose();
  }

  void spinWheel() {
    if (isSpinning.value) return;
    if (userPoints.value < spinCost) {
      Get.snackbar(
        'Not Enough Points',
        'You need $spinCost points to spin the wheel.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    userPoints.value -= spinCost;
    currentReward.value = null;
    isSpinning.value = true;
    wheelController.forward(from: 0.0);
  }

  void _calculateReward() {
    final angle = rotationAngle.value % (2 * pi);
    final segmentAngle = 2 * pi / rewards.length;
    final index = (angle / segmentAngle).floor();

    currentReward.value = rewards[index % rewards.length];

    final rewardName = _getFullRewardText(currentReward.value!.name);

    Get.snackbar(
      'Congratulations!',
      'You won: $rewardName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  String _getFullRewardText(String shortName) {
    switch (shortName) {
      case '10%':
        return 'Free 10% Off';
      case '15%':
        return 'Free 15% Off';
      case '20%':
        return 'Free 20% Off';
      case 'Drink':
        return 'Free Drink';
      case 'Dessert':
        return 'Free Dessert';
      case 'Starter':
        return 'Free Appetizer';
      case 'Meal':
        return 'Free Meal';
      case 'None':
        return 'No Reward';
      default:
        return shortName;
    }
  }
}

class RewardItem {
  final String name;
  final Color color;
  final IconData icon;

  RewardItem({required this.name, required this.color, required this.icon});
}
