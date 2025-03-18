import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Post {
  final int id;
  final DateTime createdAt;
  final List<String> images;
  final String caption;
  final String? location;
  final String userId;
  final Map<String, dynamic>? user;

  Post({
    required this.id,
    required this.createdAt,
    required this.images,
    required this.caption,
    this.location,
    required this.userId,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      images: List<String>.from(json['images']),
      caption: json['caption'],
      location: json['location'],
      userId: json['user_id'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'images': images,
      'caption': caption,
      'location': location,
      'user_id': userId,
      'user': user,
    };
  }
}

class PostsController extends GetxController {
  final RxList<Post> explorePosts = <Post>[].obs;
  final RxList<Post> userPosts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPostingLoading = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isUpdating = false.obs;
  final RxInt explorePage = 1.obs;
  final RxInt userPostsPage = 1.obs;
  final RxInt totalExplorePosts = 0.obs;
  final RxInt totalUserPosts = 0.obs;
  final int limit = 20;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchExplorePosts(reset: true);
  }

  Future<void> fetchExplorePosts({
    bool reset = false,
    bool loadMore = false,
  }) async {
    try {
      if (reset) {
        explorePosts.clear();
        explorePage.value = 1;
      } else if (loadMore) {
        explorePage.value++;
      }

      if (isLoading.value) return;
      isLoading.value = true;

      final response = await _supabase.functions.invoke(
        "get-explore-posts?page=${explorePage.value}&limit=$limit",
        method: HttpMethod.get,
      );

      if (response.status == 200) {
        final data = response.data;
        final postsData = data['posts'] as List<dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>;

        final posts =
            postsData.map((postJson) => Post.fromJson(postJson)).toList();

        if (reset) {
          explorePosts.assignAll(posts);
        } else {
          explorePosts.addAll(posts);
        }

        totalExplorePosts.value = pagination['total'];
      } else {
        Get.snackbar(
          'Error',
          response.data['error'] ?? 'Failed to fetch posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch posts: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserPosts({
    String? userId,
    bool reset = false,
    bool loadMore = false,
  }) async {
    try {
      if (reset) {
        userPosts.clear();
        userPostsPage.value = 1;
      } else if (loadMore) {
        userPostsPage.value++;
      }

      if (isLoading.value) return;
      isLoading.value = true;

      final baseUrl =
          userId != null ? 'get-user-posts/$userId' : 'get-user-posts';
      final response = await _supabase.functions.invoke(
        "$baseUrl?page=${userPostsPage.value}&limit=$limit",
        method: HttpMethod.get,
      );

      if (response.status == 200) {
        final data = response.data;
        final postsData = data['posts'] as List<dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>;

        final posts =
            postsData.map((postJson) => Post.fromJson(postJson)).toList();

        if (reset) {
          userPosts.assignAll(posts);
        } else {
          userPosts.addAll(posts);
        }

        totalUserPosts.value = pagination['total'];
      } else {
        Get.snackbar(
          'Error',
          response.data['error'] ?? 'Failed to fetch user posts',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch user posts: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Post?> createPost({
    required List<String> images,
    required String caption,
    String? location,
  }) async {
    try {
      if (isPostingLoading.value) return null;
      isPostingLoading.value = true;

      final response = await _supabase.functions.invoke(
        'create-post',
        method: HttpMethod.post,
        body: {'images': images, 'caption': caption, 'location': location},
      );

      if (response.status == 201) {
        final data = response.data;
        final post = Post.fromJson(data['post']);

        fetchUserPosts(reset: true);

        Get.snackbar(
          'Success',
          'Post created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return post;
      } else {
        Get.snackbar(
          'Error',
          response.data['error'] ?? 'Failed to create post',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create post: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isPostingLoading.value = false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      if (isDeleting.value) return false;
      isDeleting.value = true;

      final response = await _supabase.functions.invoke(
        'delete-post/$postId',
        method: HttpMethod.delete,
      );

      if (response.status == 200) {
        explorePosts.removeWhere((post) => post.id == postId);
        userPosts.removeWhere((post) => post.id == postId);

        Get.snackbar(
          'Success',
          'Post deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        Get.snackbar(
          'Error',
          response.data['error'] ?? 'Failed to delete post',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete post: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  Future<Post?> updatePost({
    required String postId,
    List<String>? images,
    String? caption,
    String? location,
  }) async {
    try {
      if (isUpdating.value) return null;
      isUpdating.value = true;

      final Map<String, dynamic> updateData = {};
      if (images != null) updateData['images'] = images;
      if (caption != null) updateData['caption'] = caption;
      if (location != null) updateData['location'] = location;

      if (updateData.isEmpty) {
        Get.snackbar(
          'Error',
          'No update data provided',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      final response = await _supabase.functions.invoke(
        'update-post/$postId',
        method: HttpMethod.patch,
        body: updateData,
      );

      if (response.status == 200) {
        final data = response.data;
        final updatedPost = Post.fromJson(data['post']);

        final exploreIndex = explorePosts.indexWhere(
          (post) => post.id == postId,
        );
        if (exploreIndex != -1) {
          explorePosts[exploreIndex] = updatedPost;
        }

        final userIndex = userPosts.indexWhere((post) => post.id == postId);
        if (userIndex != -1) {
          userPosts[userIndex] = updatedPost;
        }

        Get.snackbar(
          'Success',
          'Post updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return updatedPost;
      } else {
        Get.snackbar(
          'Error',
          response.data['error'] ?? 'Failed to update post',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update post: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isUpdating.value = false;
    }
  }

  bool get hasMoreExplorePosts => explorePosts.length < totalExplorePosts.value;

  bool get hasMoreUserPosts => userPosts.length < totalUserPosts.value;
}
