import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final ProfileController _profileController = Get.find<ProfileController>();
  List<UserProfile> _followers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    if (_profileController.currentUserProfile.value == null) {
      setState(() {
        _error = 'No user profile found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _profileController.currentUserProfile.value!.id;
      final followers = await _profileController.getFollowers(userId);

      setState(() {
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load followers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Text(
          'No followers yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index];
        return _buildUserListTile(follower);
      },
    );
  }

  Widget _buildUserListTile(UserProfile user) {
    final bool isCurrentUser =
        user.id == _profileController.currentUserProfile.value?.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.pink.shade200,
          radius: 25,
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child:
              user.avatarUrl == null
                  ? Text(
                    user.fullName?.isNotEmpty == true
                        ? user.fullName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          user.fullName ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            user.bio != null && user.bio!.isNotEmpty
                ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
        trailing:
            !isCurrentUser
                ? FutureBuilder<bool>(
                  future: _profileController.isFollowing(user.id),
                  builder: (context, snapshot) {
                    final isFollowing = snapshot.data ?? false;

                    return TextButton(
                      onPressed: () {
                        if (isFollowing) {
                          _profileController.unfollowUser(user.id);
                        } else {
                          _profileController.followUser(user.id);
                        }

                        setState(() {});
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            isFollowing
                                ? Colors.grey.shade200
                                : Colors.pink.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Unfollow' : 'Follow',
                        style: TextStyle(
                          color:
                              isFollowing
                                  ? Colors.black87
                                  : Colors.pink.shade700,
                        ),
                      ),
                    );
                  },
                )
                : null,
        onTap: () {
          if (!isCurrentUser) {
            Get.toNamed('/user-profile/${user.id}');
          }
        },
      ),
    );
  }
}
