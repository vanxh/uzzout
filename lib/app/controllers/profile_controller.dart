import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;
  final AuthController _authController = Get.find<AuthController>();

  final Rx<UserProfile?> currentUserProfile = Rx<UserProfile?>(null);
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  final Rx<UserProfile?> viewedProfile = Rx<UserProfile?>(null);

  final RxBool isFollowLoading = false.obs;
  final RxBool isProfileEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUserProfile();
  }

  Future<void> fetchCurrentUserProfile() async {
    if (_authController.user.value == null) return;

    try {
      isLoading.value = true;

      final response = await _supabase.functions.invoke(
        'get-user-profile',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        throw 'Failed to fetch profile: ${response.data['error'] ?? 'Unknown error'}';
      }

      final data = response.data;
      if (data['profile'] != null) {
        currentUserProfile.value = UserProfile.fromJson(data['profile']);
      } else {
        throw 'No profile data returned';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (currentUserProfile.value == null) return;

    try {
      isProfileEditing.value = true;

      final updateData = {
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
      };

      final response = await _supabase.functions.invoke(
        'update-user-profile',
        method: HttpMethod.put,
        body: updateData,
      );

      if (response.status != 200) {
        throw 'Failed to update profile: ${response.data['error'] ?? 'Unknown error'}';
      }

      await fetchCurrentUserProfile();
    } catch (e) {
      errorMessage.value = 'Failed to update profile: ${e.toString()}';
    } finally {
      isProfileEditing.value = false;
    }
  }

  Future<void> fetchUserProfile(String userId) async {
    try {
      isLoading.value = true;

      final response = await _supabase.functions.invoke(
        'get-user-profile/$userId',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        throw 'Failed to fetch user profile: ${response.data['error'] ?? 'Unknown error'}';
      }

      final data = response.data;
      if (data['profile'] != null) {
        viewedProfile.value = UserProfile.fromJson(data['profile']);
      } else {
        throw 'No profile data returned';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> followUser(String userId) async {
    if (currentUserProfile.value == null) return;
    if (userId == currentUserProfile.value!.id) return;

    try {
      isFollowLoading.value = true;

      final existingFollow = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', currentUserProfile.value!.id)
          .eq('following_id', userId);

      if (existingFollow.isNotEmpty) {
        return;
      }

      await _supabase.from('followers').insert({
        'follower_id': currentUserProfile.value!.id,
        'following_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _supabase.rpc(
        'increment_followers_count',
        params: {'user_id': userId},
      );

      await _supabase.rpc(
        'increment_following_count',
        params: {'user_id': currentUserProfile.value!.id},
      );

      await fetchCurrentUserProfile();
      if (viewedProfile.value?.id == userId) {
        await fetchUserProfile(userId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to follow user: ${e.toString()}';
    } finally {
      isFollowLoading.value = false;
    }
  }

  Future<void> unfollowUser(String userId) async {
    if (currentUserProfile.value == null) return;

    try {
      isFollowLoading.value = true;

      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', currentUserProfile.value!.id)
          .eq('following_id', userId);

      await _supabase.rpc(
        'decrement_followers_count',
        params: {'user_id': userId},
      );

      await _supabase.rpc(
        'decrement_following_count',
        params: {'user_id': currentUserProfile.value!.id},
      );

      await fetchCurrentUserProfile();
      if (viewedProfile.value?.id == userId) {
        await fetchUserProfile(userId);
      }
    } catch (e) {
      errorMessage.value = 'Failed to unfollow user: ${e.toString()}';
    } finally {
      isFollowLoading.value = false;
    }
  }

  Future<bool> isFollowing(String userId) async {
    if (currentUserProfile.value == null) return false;

    try {
      final result = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', currentUserProfile.value!.id)
          .eq('following_id', userId);

      return result.isNotEmpty;
    } catch (e) {
      errorMessage.value = 'Failed to check follow status: ${e.toString()}';
      return false;
    }
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select('follower_id')
          .eq('following_id', userId);

      if (response.isEmpty) {
        return [];
      }

      final followerIds =
          response.map((item) => item['follower_id'].toString()).toList();

      final followerProfiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followerIds);

      return followerProfiles
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch followers: ${e.toString()}';
      return [];
    }
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', userId);

      if (response.isEmpty) {
        return [];
      }

      final followingIds =
          response.map((item) => item['following_id'].toString()).toList();

      final followingProfiles = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', followingIds);

      return followingProfiles
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch following: ${e.toString()}';
      return [];
    }
  }
}
