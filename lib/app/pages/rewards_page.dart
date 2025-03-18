import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uzzout/app/controllers/rewards_controller.dart';
import 'package:uzzout/app/widgets/spin_wheel.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RewardsController controller = Get.put(RewardsController());

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade100,
              const Color(0xFFFFF5F5),
              Colors.white.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [Colors.pink.shade600, Colors.pink.shade300],
                        ).createShader(bounds),
                    child: const Text(
                      'Spin & Win',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Obx(
                    () => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.shade100.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: Colors.amber.shade500,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${controller.userPoints.value} Points',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.shade100.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Obx(
                          () => SpinWheel(
                            items: controller.rewards,
                            rotationAngle: controller.rotationAngle.value,
                          ),
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () => controller.spinWheel(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.shade400,
                                  Colors.pink.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.shade300.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Obx(
                              () => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    controller.isSpinning.value
                                        ? Icons.hourglass_top
                                        : Icons.touch_app,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    controller.isSpinning.value
                                        ? 'Spinning...'
                                        : 'Spin Now (${controller.spinCost} Points)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Obx(
                    () =>
                        controller.currentReward.value != null
                            ? Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: controller.currentReward.value!.color
                                        .withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: controller.currentReward.value!.color
                                      .withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Your Reward',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: controller
                                          .currentReward
                                          .value!
                                          .color
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          controller.currentReward.value!.icon,
                                          size: 50,
                                          color:
                                              controller
                                                  .currentReward
                                                  .value!
                                                  .color,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          _getFullRewardText(
                                            controller
                                                .currentReward
                                                .value!
                                                .name,
                                          ),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                controller
                                                    .currentReward
                                                    .value!
                                                    .color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 24,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.shade100.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.tips_and_updates,
                                    color: Colors.amber.shade400,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Earn points for dining out and redeem them by spinning the wheel for exclusive rewards!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
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
