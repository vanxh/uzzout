import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../controllers/location_controller.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class ProfilePage extends StatelessWidget {
  final Function clearAllCaches;

  const ProfilePage({super.key, this.clearAllCaches = _defaultClearAllCaches});

  static Future<void> _defaultClearAllCaches() async {
    final locationController = Get.find<LocationController>();
    final restaurantController = Get.find<RestaurantController>();
    await locationController.clearLocationCache();
    await restaurantController.clearRestaurantCache();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final LocationController locationController =
        Get.find<LocationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      extendBodyBehindAppBar: true,
      body: Obx(() {
        final userProfile = profileController.currentUserProfile.value;

        if (profileController.isLoading.value && userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final fullName = userProfile?.fullName ?? 'User';
        final email = userProfile?.email ?? 'No email';
        final photoUrl = userProfile?.avatarUrl;
        final bio = userProfile?.bio ?? '';
        final followersCount = userProfile?.followersCount ?? 0;
        final followingCount = userProfile?.followingCount ?? 0;

        return DefaultTabController(
          length: 2,
          child: NestedScrollView(
            physics: const ClampingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.pink.shade100,
                  elevation: 0,
                  toolbarHeight: 40.0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.pink.shade100,
                            const Color(0xFFFFF5F5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _showLocationOptions(context),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(
                          context,
                          fullName,
                          photoUrl,
                          bio,
                          profileController,
                        ),
                        const SizedBox(height: 16),
                        _buildSocialStats(followersCount, followingCount),
                        const SizedBox(height: 16),
                        _buildProfileInfo(
                          context,
                          fullName,
                          email,
                          bio,
                          locationController,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: Colors.pink.shade700,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Colors.pink.shade400,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: "Posts"),
                        Tab(icon: Icon(Icons.bookmark_border), text: "Saved"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              physics: const ClampingScrollPhysics(),
              children: [_buildPostsGrid(context), _buildSavedGrid(context)],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String fullName,
    String? photoUrl,
    String bio,
    ProfileController profileController,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Hero(
                tag: 'profile-image',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child:
                        photoUrl != null
                            ? Image.network(photoUrl, fit: BoxFit.cover)
                            : Center(
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Obx(() {
                final isUploading = profileController.isUploadingAvatar.value;

                return GestureDetector(
                  onTap:
                      isUploading
                          ? null
                          : () async {
                            final File? imageFile =
                                await profileController.pickImage();
                            if (imageFile != null && context.mounted) {
                              final bool shouldUpload =
                                  await _showImageConfirmationDialog(
                                    context,
                                    imageFile,
                                  );

                              if (shouldUpload && context.mounted) {
                                final success = await profileController
                                    .uploadAvatar(imageFile);

                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile picture updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    final errorMsg =
                                        profileController.errorMessage.value;
                                    if (errorMsg != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMsg),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            }
                          },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFF5F5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        isUploading
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.pink.shade400,
                                ),
                              ),
                            )
                            : Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.pink.shade400,
                            ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.pink.shade400,
                      size: 22,
                    ),
                    onPressed:
                        () =>
                            _showEditProfileDialog(context, profileController),
                    tooltip: 'Edit Profile',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (bio.isNotEmpty)
                Text(
                  bio,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialStats(int followersCount, int followingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(followersCount, 'Followers'),
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
          _buildStatColumn(followingCount, 'Following'),
          Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3)),
          _buildStatColumn(0, 'Posts'),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(
    BuildContext context,
    String fullName,
    String email,
    String bio,
    LocationController locationController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileInfoCard(
          children: [
            ProfileInfoTile(
              icon: Icons.person_outline,
              label: 'Name',
              value: fullName,
            ),
            const Divider(),
            ProfileInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProfileInfoCard(
          children: [
            Obx(() {
              final position = locationController.currentPosition.value;
              final isLoading = locationController.isLoadingLocation.value;
              final error = locationController.locationError.value;
              final address = locationController.currentAddress.value;
              final isUsingCache = locationController.isUsingCachedData.value;

              if (isLoading) {
                return const ProfileInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: 'Getting location...',
                  showLoading: true,
                );
              } else if (error != null) {
                return ProfileInfoTile(
                  icon: Icons.location_off_outlined,
                  label: 'Location',
                  value: 'Location unavailable',
                  onTap:
                      () => locationController.refreshLocation(
                        forceRefresh: true,
                      ),
                  trailingIcon: Icons.refresh,
                  trailingIconTooltip: 'Retry',
                );
              } else if (position != null) {
                return ProfileInfoTile(
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.grey.shade700,
                  label: isUsingCache ? 'Location (Cached)' : 'Location',
                  value: address ?? 'Address unavailable',
                  onTap:
                      () => locationController.refreshLocation(
                        forceRefresh: true,
                      ),
                  copyButton: true,
                  trailingIcon: Icons.refresh,
                  trailingIconTooltip: 'Force refresh',
                  onLongPress: () => _showLocationOptions(context),
                );
              } else {
                return ProfileInfoTile(
                  icon: Icons.location_searching_outlined,
                  label: 'Location',
                  value: 'Tap to get location',
                  onTap: () => locationController.refreshLocation(),
                  trailingIcon: Icons.add_location_alt,
                  trailingIconTooltip: 'Get location',
                );
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPostsGrid(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return PostGridItem(
                index: index,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing post $index'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        physics: const ClampingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 3,
        itemBuilder: (context, index) {
          return PostGridItem(
            index: index,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing saved post $index'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            isSaved: true,
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == 'Followers') {
            Get.toNamed('/followers');
          } else if (label == 'Following') {
            Get.toNamed('/following');
          } else if (label == 'Posts') {
            DefaultTabController.of(Get.context!).animateTo(0);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    ProfileController profileController,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: profileController.currentUserProfile.value?.fullName ?? '',
    );

    final TextEditingController bioController = TextEditingController(
      text: profileController.currentUserProfile.value?.bio ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              profileController.isProfileEditing.value
                                  ? null
                                  : () async {
                                    await profileController.updateProfile(
                                      fullName: nameController.text,
                                      bio: bioController.text,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              profileController.isProfileEditing.value
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final RestaurantController restaurantController = Get.find();
        final LocationController locationController = Get.find();
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Obx(
                  () =>
                      locationController.isUsingCachedData.value
                          ? ListTile(
                            leading: Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade400,
                            ),
                            title: const Text('Using Cached Data'),
                            subtitle: const Text(
                              'Location and restaurant data is from cache',
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Refresh Location'),
                  subtitle: const Text(
                    'Get your current location (uses cache if valid)',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    locationController.refreshLocation();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Force Refresh Everything'),
                  subtitle: const Text('Clear all caches and get fresh data'),
                  onTap: () {
                    Navigator.pop(context);
                    locationController.refreshLocation(forceRefresh: true);
                    restaurantController.refreshRestaurants(forceRefresh: true);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Refresh Restaurants Only'),
                  subtitle: const Text(
                    'Get fresh restaurant data for current location',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    restaurantController.refreshRestaurants();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Force Refresh Restaurants'),
                  subtitle: const Text(
                    'Clear restaurant cache and get new data',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    restaurantController.refreshRestaurants(forceRefresh: true);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear All Caches'),
                  subtitle: const Text(
                    'Remove all stored location and restaurant data',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    clearAllCaches();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All caches cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Log out from your account'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Get.find<AuthController>().signOut();
                    Get.offAllNamed('/');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showImageConfirmationDialog(
    BuildContext context,
    File imageFile,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Update Profile Picture'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Do you want to use this image as your profile picture?',
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      imageFile,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Use Photo',
                    style: TextStyle(color: Colors.pink.shade400),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileInfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(children: children),
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showLoading;
  final bool copyButton;
  final IconData? trailingIcon;
  final String? trailingIconTooltip;
  final VoidCallback? onLongPress;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
    this.showLoading = false,
    this.copyButton = false,
    this.trailingIcon,
    this.trailingIconTooltip,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.pink.shade300,
                              ),
                            ),
                          ),
                        if (copyButton && !showLoading)
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () {
                              final data = ClipboardData(text: value);
                              Clipboard.setData(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (trailingIcon != null && !showLoading)
                          Tooltip(
                            message: trailingIconTooltip ?? '',
                            child: Icon(
                              trailingIcon,
                              size: 20,
                              color: Colors.grey.shade600,
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
      ),
    );
  }
}

class PostGridItem extends StatelessWidget {
  final int index;
  final VoidCallback onTap;
  final bool isSaved;

  const PostGridItem({
    super.key,
    required this.index,
    required this.onTap,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.pink.shade200,
      Colors.purple.shade200,
      Colors.blue.shade200,
      Colors.teal.shade200,
      Colors.orange.shade200,
    ];

    final color = colors[index % colors.length];

    return Material(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.restaurant,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            if (isSaved)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bookmark,
                    size: 12,
                    color: Colors.pink.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
