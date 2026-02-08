import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/post_tile.dart';
import 'package:neom_commons/utils/constants/app_assets.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:sint/sint.dart';

import '../../mate_details_controller.dart';

/// Instagram-style posts grid for mate (friend) profile.
/// Features:
/// - 3-column grid with 1px gaps (Instagram style)
/// - Smooth scroll physics
/// - Loading shimmer placeholder
/// - Empty state with illustration
class MatePosts extends StatelessWidget {
  const MatePosts({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      builder: (controller) {
        if (controller.isLoadingPosts.value) {
          return _buildLoadingGrid();
        } else if (controller.matePosts.isEmpty) {
          return _buildEmptyState();
        } else {
          return _buildPostsGrid(controller);
        }
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  CommonTranslationConstants.noPostsYet.tr,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Image.asset(AppAssets.noPostsMate, height: 120),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(MateDetailsController controller) {
    // Filter out caption posts
    final List<Post> displayPosts = controller.matePosts
        .where((post) => post.type != PostType.caption)
        .toList();

    if (displayPosts.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];
        final Event event = controller.eventPosts[post] ?? Event();
        return PostTile(post, event);
      },
    );
  }
}
