import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/animated_follow_button.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/text_utilities.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:sint/sint.dart';

import '../../../../utils/constants/mate_translation_constants.dart';
import '../../header/mate_details_header.dart' show buildDotsMenu;
import '../../mate_details_controller.dart';

/// Instagram-style horizontal profile header for web view of mate (profile)
/// detail. Avatar on the left, name + stats + bio + action buttons stacked
/// on the right. 3-dots menu sits in the top-right corner.
class MateDetailsWebHeader extends StatelessWidget {
  final MateDetailsController controller;

  const MateDetailsWebHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mate = controller.mate.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar (left, large like IG) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 48, top: 4),
              child: platformCircleAvatar(
                imageUrl: mate.photoUrl.isNotEmpty
                    ? mate.photoUrl
                    : AppProperties.getAppLogoUrl(),
                radius: 75,
              ),
            ),

            // ─── Info column (right, takes remaining width) ───────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: name + verification + 3-dots menu
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          TextUtilities.capitalizeFirstLetter(mate.name),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mate.verificationLevel != VerificationLevel.none) ...[
                        AppTheme.widthSpace5,
                        AppFlavour.getVerificationIcon(mate.verificationLevel, size: 18),
                      ],
                      const SizedBox(width: 16),

                      // Follow / Message / 3-dots
                      Obx(() => AnimatedFollowButton(
                        isFollowing: controller.following.value,
                        followText: AppTranslationConstants.follow.tr.toUpperCase(),
                        followingText: AppTranslationConstants.following.tr.toUpperCase(),
                        unfollowText: AppTranslationConstants.unfollow.tr.toUpperCase(),
                        onPressed: () {
                          AuthGuard.protect(context, () {
                            controller.following.value
                                ? controller.unfollow()
                                : controller.follow();
                          });
                        },
                      )),
                      const SizedBox(width: 8),
                      AnimatedMessageButton(
                        text: AppTranslationConstants.message.tr.toUpperCase(),
                        onPressed: () {
                          AuthGuard.protect(context, () {
                            controller.sendMessage();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // 3-dots menu — same modal as mobile, just triggered
                      // here so web users can also report/block.
                      IconButton(
                        tooltip: AppTranslationConstants.more.tr,
                        onPressed: () => showModalBottomSheet(
                          backgroundColor: AppTheme.canvasColor75(context),
                          context: context,
                          builder: (ctx) => buildDotsMenu(
                            ctx,
                            controller.mate.value,
                            controller.userServiceImpl.user.userRole,
                          ),
                        ),
                        icon: Icon(
                          FontAwesomeIcons.ellipsisVertical,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Row 2: stats (publicaciones / seguidores / seguidos)
                  Row(
                    children: [
                      _StatBlock(
                        count: controller.matePosts.length,
                        label: AppTranslationConstants.posts.tr,
                      ),
                      const SizedBox(width: 32),
                      _StatBlock(
                        count: mate.followers?.length ?? 0,
                        label: AppTranslationConstants.followers.tr,
                      ),
                      const SizedBox(width: 32),
                      _StatBlock(
                        count: mate.following?.length ?? 0,
                        label: AppTranslationConstants.following.tr,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Row 3: slug + location
                  if (mate.slug.isNotEmpty)
                    Text(
                      '@${mate.slug}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),

                  if (controller.address.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place, color: AppColor.white80, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            controller.address.length > CoreConstants.maxLocationNameLength
                                ? '${controller.address.substring(0, CoreConstants.maxLocationNameLength)}...'
                                : controller.address,
                            style: TextStyle(fontSize: 13, color: AppColor.white80),
                          ),
                          if (controller.distance > 0)
                            Text(
                              ' · ${controller.distance} ${CoreConstants.km}',
                              style: TextStyle(fontSize: 13, color: AppColor.white80),
                            ),
                        ],
                      ),
                    ),

                  // Row 4: bio
                  if (mate.aboutMe.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ReadMoreContainer(
                          text: TextUtilities.capitalizeFirstLetter(mate.aboutMe),
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Main feature (instrument/genre)
                  if (mate.mainFeature.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppFlavour.getInstrumentIcon(), size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            mate.mainFeature.tr.capitalize,
                            style: const TextStyle(fontSize: 13, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                  // Genres
                  if (mate.genres != null && mate.genres!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GenresGridView(
                        mate.genres!.keys.toList(),
                        AppColor.white80,
                        alignment: Alignment.centerLeft,
                        fontSize: 12,
                      ),
                    ),

                  // Bio fallback if empty
                  if (mate.aboutMe.isEmpty && mate.mainFeature.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        CommonTranslationConstants.noProfileDesc.tr,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),

                  // Blog button
                  if (AppConfig.instance.appInUse == AppInUse.e && controller.hasBlogEntries.value)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Sint.toNamed(
                            AppRouteConstants.mateBlog,
                            arguments: [mate],
                            parameters: {'ownerId': mate.id},
                          );
                        },
                        icon: const Icon(Icons.auto_stories_rounded, size: 16),
                        label: Text(MateTranslationConstants.checkMyBlog.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Compact "1.2K Publicaciones" stat block in IG style.
class _StatBlock extends StatelessWidget {
  final int count;
  final String label;

  const _StatBlock({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.toLowerCase(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
