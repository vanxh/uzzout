import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage>
    with SingleTickerProviderStateMixin {
  final ProfileController _profileController = Get.find<ProfileController>();
  List<UserProfile> _following = [];
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
    _loadFollowing();

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
      final cachedFollowing = await _profileController.getFollowing(userId);

      setState(() {
        _following = cachedFollowing;
        _isLoading = false;
        _showScrollIndicator = cachedFollowing.length > 2;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load following: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFollowing() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _profileController.currentUserProfile.value!.id;
      final following = await _profileController.getFollowing(userId);

      if (!mounted) return;
      setState(() {
        _following = following;
        _isLoading = false;
        _showScrollIndicator = following.length > 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to refresh following: ${e.toString()}';
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
                onRefresh: _refreshFollowing,
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
            'Following',
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

    if (_following.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            itemCount: _following.length,
            itemBuilder: (context, index) {
              final profile = _following[index];
              return _buildUserListTile(profile);
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
            'Loading accounts you follow...',
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
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFollowing,
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
            'You\'re not following anyone yet',
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
              'Follow users to see them here',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/explore'),
            icon: const Icon(Icons.explore),
            label: const Text('Explore users'),
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
            Get.toNamed('/user-profile/${user.id}');
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
                Container(
                  height: 36,
                  margin: const EdgeInsets.only(left: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                'Unfollow ${user.fullName ?? 'User'}?',
                              ),
                              content: Text(
                                'You will no longer see their posts in your feed.',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink.shade400,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Unfollow'),
                                ),
                              ],
                            ),
                      );

                      if (result == true) {
                        await _profileController.unfollowUser(user.id);
                        _loadFollowing();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: const Text(
                      'Unfollow',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
}
