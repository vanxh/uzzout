import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage>
    with SingleTickerProviderStateMixin {
  final ProfileController _profileController = Get.find<ProfileController>();
  List<UserProfile> _followers = [];
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadFollowers();

    _scrollController.addListener(() {
      final showIndicator =
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0 &&
          _scrollController.offset < 10;

      if (showIndicator != _showScrollIndicator) {
        setState(() {
          _showScrollIndicator = showIndicator;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      final cachedFollowers = await _profileController.getFollowers(userId);

      setState(() {
        _followers = cachedFollowers;
        _isLoading = false;
        _showScrollIndicator = cachedFollowers.length > 2;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load followers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFollowers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _profileController.currentUserProfile.value!.id;
      final followers = await _profileController.getFollowers(userId);

      if (!mounted) return;
      setState(() {
        _followers = followers;
        _isLoading = false;
        _showScrollIndicator = followers.length > 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to refresh followers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.pink.shade100, const Color(0xFFFFF5F5)],
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _refreshFollowers,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(color: Colors.pink.shade100),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 20,
              ),
            ),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 16),
          const Text(
            'Followers',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_followers.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            itemCount: _followers.length,
            itemBuilder: (context, index) {
              final follower = _followers[index];
              return _buildUserListTile(follower);
            },
          ),
        ),
        if (_showScrollIndicator)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildScrollIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScrollIndicator() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.pink.shade400),
        onPressed: () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade300),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your followers...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFollowers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.pink.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No followers yet',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When people follow you, they\'ll appear here',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile(UserProfile user) {
    final bool isCurrentUser =
        user.id == _profileController.currentUserProfile.value?.id;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isCurrentUser) {
              Get.toNamed('/user-profile/${user.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade300, Colors.purple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 28,
                    child: CircleAvatar(
                      backgroundColor: Colors.pink.shade200,
                      radius: 26,
                      backgroundImage:
                          user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? Text(
                                user.fullName?.isNotEmpty == true
                                    ? user.fullName![0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isCurrentUser)
                  FutureBuilder<bool>(
                    future: _profileController.isFollowing(user.id),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;

                      return Container(
                        height: 36,
                        margin: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            if (isFollowing) {
                              _profileController.unfollowUser(user.id);
                            } else {
                              _profileController.followUser(user.id);
                            }
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFollowing
                                    ? Colors.grey.shade200
                                    : Colors.pink.shade400,
                            foregroundColor:
                                isFollowing ? Colors.black87 : Colors.white,
                            elevation: isFollowing ? 0 : 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side:
                                  isFollowing
                                      ? BorderSide(color: Colors.grey.shade400)
                                      : BorderSide.none,
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Unfollow' : 'Follow',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
