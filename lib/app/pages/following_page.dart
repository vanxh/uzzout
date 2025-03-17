import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final ProfileController _profileController = Get.find<ProfileController>();
  List<UserProfile> _following = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
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
      final following = await _profileController.getFollowing(userId);

      setState(() {
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load following: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text('Following'),
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
              onPressed: _loadFollowing,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_following.isEmpty) {
      return const Center(
        child: Text(
          'Not following anyone yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final profile = _following[index];
        return _buildUserListTile(profile);
      },
    );
  }

  Widget _buildUserListTile(UserProfile user) {
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
        trailing: TextButton(
          onPressed: () async {
            await _profileController.unfollowUser(user.id);
            _loadFollowing();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Unfollow',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        onTap: () {
          Get.toNamed('/user-profile/${user.id}');
        },
      ),
    );
  }
}
