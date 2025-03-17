import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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
  final RxBool isUploadingAvatar = false.obs;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUserProfile();
  }

  Future<File?> pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedImage == null) return null;
      return File(pickedImage.path);
    } catch (e) {
      errorMessage.value = 'Error picking image: ${e.toString()}';
      return null;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    if (_authController.user.value == null) return false;

    try {
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        errorMessage.value =
            'Image size too large. Please select an image under 2MB.';
        return false;
      }

      isUploadingAvatar.value = true;

      final userId = _authController.user.value!.id;

      final fileExt = path.extension(imageFile.path);

      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
      if (!validExtensions.contains(fileExt.toLowerCase())) {
        errorMessage.value =
            'Unsupported file format. Please use JPG, PNG or GIF.';
        return false;
      }

      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}$fileExt';

      final filePath = '$userId/$fileName';

      try {
        final List<FileObject> oldAvatars = await _supabase.storage
            .from('avatars')
            .list(path: userId);

        for (var file in oldAvatars) {
          await _supabase.storage.from('avatars').remove([
            '$userId/${file.name}',
          ]);
        }
      } catch (e) {
        print('Failed to remove old avatars: $e');
      }

      await _supabase.storage.from('avatars').upload(filePath, imageFile);

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await updateProfile(avatarUrl: publicUrl);

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to upload avatar: ${e.toString()}';
      return false;
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<bool> pickAndUploadAvatar() async {
    final imageFile = await pickImage();
    if (imageFile == null) return false;

    return await uploadAvatar(imageFile);
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

      final response = await _supabase.functions.invoke(
        'follow-user',
        method: HttpMethod.post,
        body: {'user_id': userId},
      );

      if (response.status != 201) {
        throw 'Failed to follow user: ${response.data['error'] ?? 'Unknown error'}';
      }

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

      final response = await _supabase.functions.invoke(
        'unfollow-user',
        method: HttpMethod.post,
        body: {'user_id': userId},
      );

      if (response.status != 200) {
        throw 'Failed to unfollow user: ${response.data['error'] ?? 'Unknown error'}';
      }

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
      final response = await _supabase.functions.invoke(
        'get-following',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        throw 'Failed to check follow status: ${response.data['error'] ?? 'Unknown error'}';
      }

      final List<dynamic> following = response.data['following'] ?? [];

      return following.any((follow) => follow['following_id'] == userId);
    } catch (e) {
      errorMessage.value = 'Failed to check follow status: ${e.toString()}';
      return false;
    }
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-followers/$userId',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        throw 'Failed to fetch followers: ${response.data['error'] ?? 'Unknown error'}';
      }

      final List<dynamic> followersData = response.data['followers'] ?? [];

      return followersData
          .map((follower) => UserProfile.fromJson(follower['user']))
          .toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch followers: ${e.toString()}';
      return [];
    }
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-following/$userId',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        throw 'Failed to fetch following: ${response.data['error'] ?? 'Unknown error'}';
      }

      final List<dynamic> followingData = response.data['following'] ?? [];

      return followingData
          .map((following) => UserProfile.fromJson(following['user']))
          .toList();
    } catch (e) {
      errorMessage.value = 'Failed to fetch following: ${e.toString()}';
      return [];
    }
  }
}
