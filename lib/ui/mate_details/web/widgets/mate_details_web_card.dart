import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/animated_follow_button.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/genres_grid_view.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/read_more_container.dart';
import 'package:neom_commons/ui/widgets/web/web_theme_constants.dart';
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
import '../../mate_details_controller.dart';

class MateDetailsWebCard extends StatelessWidget {
  final MateDetailsController controller;

  const MateDetailsWebCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: WebThemeConstants.glassCard,
      child: Obx(() {
        final mate = controller.mate.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HandledCachedNetworkImage(
                  mate.coverImgUrl.isNotEmpty
                      ? mate.coverImgUrl
                      : mate.photoUrl.isNotEmpty
                          ? mate.photoUrl
                          : AppProperties.getNoImageUrl(),
                  width: 280,
                  height: 160,
                  fit: BoxFit.cover,
                  enableFullScreen: false,
                ),
              ),
              const SizedBox(height: 16),

              // Avatar
              platformCircleAvatar(
                imageUrl: mate.photoUrl.isNotEmpty
                    ? mate.photoUrl
                    : AppProperties.getAppLogoUrl(),
                radius: 40,
              ),
              const SizedBox(height: 12),

              // Follow / Message buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => AnimatedFollowButton(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedMessageButton(
                        text: AppTranslationConstants.message.tr.toUpperCase(),
                        onPressed: () {
                          AuthGuard.protect(context, () {
                            controller.sendMessage();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Name + verification
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      TextUtilities.capitalizeFirstLetter(mate.name),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (mate.verificationLevel != VerificationLevel.none) ...[
                    AppTheme.widthSpace5,
                    AppFlavour.getVerificationIcon(mate.verificationLevel, size: 18),
                  ],
                ],
              ),

              // Slug
              if (mate.slug.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '@${mate.slug}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

              // Location
              if (controller.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          ' - ${controller.distance} ${CoreConstants.km}',
                          style: TextStyle(fontSize: 13, color: AppColor.white80),
                        ),
                    ],
                  ),
                ),

              // Bio
              if (mate.aboutMe.isNotEmpty)
                ReadMoreContainer(
                  text: TextUtilities.capitalizeFirstLetter(mate.aboutMe),
                  color: Colors.white70,
                )
              else
                Text(
                  CommonTranslationConstants.noProfileDesc.tr,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),

              // Main feature
              if (mate.mainFeature.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                    alignment: Alignment.center,
                    fontSize: 12,
                  ),
                ),

              // Blog button (bottom)
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
        );
      }),
    );
  }
}
