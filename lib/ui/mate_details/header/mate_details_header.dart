import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/animated_follow_button.dart';
import 'package:neom_commons/ui/widgets/images/diagonally_cut_colored_image.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/common_translation_constants.dart';
import 'package:neom_commons/utils/constants/translations/message_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/menu_three_dots.dart';
import 'package:neom_core/domain/use_cases/report_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/reference_type.dart';
import 'package:neom_core/utils/enums/report_type.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/mate_translation_constants.dart';
import '../mate_details_controller.dart';

class MateDetailHeader extends StatelessWidget {
  const MateDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      builder: (controller) => Stack(
      children: <Widget>[
        FutureBuilder(
          future: CoreUtilities().isAvailableMediaUrl(controller.mate.value.coverImgUrl.isNotEmpty ?
            controller.mate.value.coverImgUrl : controller.mate.value.photoUrl.isNotEmpty
            ? controller.mate.value.photoUrl : AppProperties.getAppLogoUrl()),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
                return DiagonallyCutColoredImage(
                  Image(
                      image: NetworkImage(
                          (snapshot.data == true) ?
                          (controller.mate.value.coverImgUrl.isNotEmpty ?
                      controller.mate.value.coverImgUrl : controller.mate.value.photoUrl.isNotEmpty
                          ? controller.mate.value.photoUrl : AppProperties.getAppLogoUrl()) : AppProperties.getAppLogoUrl(),),
                      width: MediaQuery.of(context).size.width,
                      height: 250.0,
                      fit: BoxFit.cover,
                      errorBuilder:  (context, object, error) => Image.network(AppProperties.getAppLogoUrl())
                  ),
                  color: AppColor.cutColoredImage,);
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          heightFactor: 1.25,
          child: Column(
            children: <Widget>[
              Hero(
                tag: controller.mate.value.name,
                child: FutureBuilder(
                  future: CoreUtilities().isAvailableMediaUrl(controller.mate.value.photoUrl.isNotEmpty
                      ? controller.mate.value.photoUrl : AppProperties.getAppLogoUrl(),),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage((snapshot.data == true) ?
                        (controller.mate.value.photoUrl.isNotEmpty ? controller.mate.value.photoUrl : AppProperties.getAppLogoUrl())
                            : AppProperties.getAppLogoUrl(),),
                        radius: 60.0,
                        onBackgroundImageError: (object, error) => CachedNetworkImageProvider(controller.mate.value.photoUrl.isNotEmpty ? controller.mate.value.photoUrl
                            : AppProperties.getAppLogoUrl(),),
                      );
                    } else {
                      return const CircleAvatar(
                        radius: 60.0,
                        child: Center(child: CircularProgressIndicator()),
                      );

                    }
                  },
                ),
              ),
              AppTheme.heightSpace30,
              AppConfig.instance.appInUse != AppInUse.e || controller.mateBlogEntries.isEmpty
                  ? const SizedBox.shrink() : _AnimatedBlogButton(
                text: MateTranslationConstants.checkMyBlog.tr,
                onTap: () {
                  Sint.toNamed(AppRouteConstants.mateBlog, arguments: [controller.mate.value]);
                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: controller.mateBlogEntries.isEmpty ? 40.0 : 20.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Obx(() => AnimatedFollowButton(
                      isFollowing: controller.following.value,
                      followText: AppTranslationConstants.follow.tr.toUpperCase(),
                      followingText: AppTranslationConstants.following.tr.toUpperCase(),
                      unfollowText: AppTranslationConstants.unfollow.tr.toUpperCase(),
                      onPressed: () {
                        AuthGuard.protect(context, () {
                          controller.following.value ? controller.unfollow() : controller.follow();
                        });
                      },
                    )),
                    AnimatedMessageButton(
                      text: AppTranslationConstants.message.tr.toUpperCase(),
                      onPressed: () {
                        AuthGuard.protect(context, () {
                          controller.sendMessage();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 25, right: 10, left: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BackButton(color: Colors.white),
              IconButton(
                  onPressed: () => showModalBottomSheet(
                      backgroundColor: AppTheme.canvasColor75(context),
                      context: context,
                      builder: (context) {
                        return _buildDotsMenu(context, controller.mate.value, controller.userServiceImpl.user.userRole);
                      }
                  ),
                  icon: const Icon(FontAwesomeIcons.ellipsisVertical, size: 20)
              ),
            ]
        ),),
      ],
    ));
  }
}

/// Animated blog button with shimmer effect and modern styling
class _AnimatedBlogButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _AnimatedBlogButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_AnimatedBlogButton> createState() => _AnimatedBlogButtonState();
}

class _AnimatedBlogButtonState extends State<_AnimatedBlogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  stops: [
                    0.0,
                    (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                    _shimmerAnimation.value.clamp(0.0, 1.0),
                    (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                    1.0,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          2 * (0.5 - (_controller.value - 0.5).abs()),
                          0,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildDotsMenu(BuildContext context, AppProfile itemmate, UserRole userRole) {

  List<Menu3DotsModel> listMore = [];
  listMore.add(Menu3DotsModel(CommonTranslationConstants.reportProfile.tr, MessageTranslationConstants.reportPostMsg,
      Icons.info, CommonTranslationConstants.reportProfile));
  listMore.add(Menu3DotsModel(CommonTranslationConstants.blockProfile.tr, MessageTranslationConstants.blockProfileMsg,
      Icons.block, CommonTranslationConstants.blockProfile));
  if(userRole != UserRole.subscriber) {
    listMore.add(Menu3DotsModel(MateTranslationConstants.updateVerificationLevel.tr, MateTranslationConstants.updateVerificationLevelMsg,
        Icons.verified, MateTranslationConstants.updateVerificationLevel));
    listMore.add(Menu3DotsModel(CommonTranslationConstants.removeProfile.tr, MateTranslationConstants.removeProfileMsg,
        Icons.delete, CommonTranslationConstants.removeProfile));
    if(userRole == UserRole.superAdmin) {
      listMore.add(Menu3DotsModel(MateTranslationConstants.updateUserRole.tr, MateTranslationConstants.updateUserRoleMsg,
          Icons.verified_user_rounded, MateTranslationConstants.updateUserRole));
    }
  }

  return Container(
      height: userRole == UserRole.subscriber ? 160 : 300,
      decoration: BoxDecoration(
        color: AppColor.main50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: ListView.builder(
          itemCount: listMore.length,
          itemBuilder: (BuildContext context, int index){
            return ListTile(
              title: Text(listMore[index].title.tr, style: const TextStyle(fontSize: 18)),
              subtitle: Text(listMore[index].subtitle.tr),
              leading: Icon(listMore[index].icons, size: 20, color: Colors.white),
              onTap: () {
                AuthGuard.protect(context, () {
                  switch (listMore[index].action) {
                    case CommonTranslationConstants.reportProfile:
                      showReportProfileAlert(context, itemmate);
                      break;
                    case CommonTranslationConstants.blockProfile:
                      showBlockProfileAlert(context);
                      break;
                    case CommonTranslationConstants.removeProfile:
                      showRemoveProfileAlert(context);
                      break;
                    case MateTranslationConstants.updateVerificationLevel:
                      showUpdateVerificationLevelAlert(context);
                      break;
                    case MateTranslationConstants.updateUserRole:
                      showUpdateUserRoleAlert(context);
                      break;
                  }
                });
              },
            );
          })
  );
}

void showRemoveProfileAlert(BuildContext context) {
  MateDetailsController mateDetailsController = Sint.put(MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: CommonTranslationConstants.removeProfile.tr,
      content: Column(
        children: [
          Text(MateTranslationConstants.removeProfileMsg.tr,
            style: const TextStyle(fontSize: 15),
          ),
          AppTheme.heightSpace10,
          Text(MateTranslationConstants.removeProfileMsg2.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ],),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            Navigator.of(context).pop();
          },
          child: Text(AppTranslationConstants.goBack.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            await mateDetailsController.removeProfile();
          },
          child: Text(AppTranslationConstants.toRemove.tr,
            style: const TextStyle(fontSize: 15),
          ),
        )
      ]
  ).show();
}

void showBlockProfileAlert(BuildContext context) {
  MateDetailsController mateDetailsController = Sint.put(MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: CommonTranslationConstants.blockProfile.tr,
      content: Column(
        children: [
          Text(MessageTranslationConstants.blockProfileMsg.tr,
            style: const TextStyle(fontSize: 15),
          ),
          AppTheme.heightSpace10,
          Text(MessageTranslationConstants.blockProfileMsg2.tr,
            style: const TextStyle(fontSize: 15),
          ),
      ],),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            Navigator.of(context).pop();
          },
          child: Text(AppTranslationConstants.goBack.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            await mateDetailsController.blockProfile();
          },
          child: Text(AppTranslationConstants.toBlock.tr,
            style: const TextStyle(fontSize: 15),
          ),
        )
      ]
  ).show();
}

void showReportProfileAlert(BuildContext context, AppProfile itemmate) {
  ReportService reportServiceImpl = Sint.find<ReportService>();
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: AppTranslationConstants.sendReport.tr,
      content: Column(
        children: <Widget>[
          Obx(()=>
              DropdownButton<ReportType>(
                items: ReportType.values.map((ReportType reportType) {
                  return DropdownMenuItem<ReportType>(
                    value: reportType,
                    child: Text(reportType.name.tr),
                  );
                }).toList(),
                onChanged: (ReportType? reportType) {
                  reportServiceImpl.setReportType(reportType ?? ReportType.other);
                },
                value: reportServiceImpl.reportType,
                alignment: Alignment.center,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 20,
                elevation: 16,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColor.main75,
                underline: Container(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
          ),
          TextField(
            onChanged: (text) {
              reportServiceImpl.setMessage(text);
            },
            decoration: InputDecoration(
                labelText: AppTranslationConstants.message.tr
            ),
          ),
        ],
      ),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            if(!reportServiceImpl.isButtonDisabled) {
              await reportServiceImpl.sendReport(ReferenceType.profile, itemmate.id);
              AppAlerts.showAlert(context, title: AppTranslationConstants.report.tr,
                  message: CommonTranslationConstants.hasSentReport.tr);
            }
          },
          child: Text(AppTranslationConstants.send.tr,
            style: const TextStyle(fontSize: 15),
          ),
        )
      ]
  ).show();
}

void showUpdateVerificationLevelAlert(BuildContext context) {
  MateDetailsController mateDetailsController = Sint.put(
      MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: MateTranslationConstants.verificationLevel.tr,
      content: Column(
        children: <Widget>[
          AppTheme.heightSpace10,
          Text(MateTranslationConstants.updateVerificationLevelMsg.tr,
            style: const TextStyle(fontSize: 15),
          ),
          Obx(() =>
              DropdownButton<VerificationLevel>(
                items: VerificationLevel.values.map((
                    VerificationLevel verificationLevel) {
                  return DropdownMenuItem<VerificationLevel>(
                    value: verificationLevel,
                    child: Text(verificationLevel.name.tr),
                  );
                }).toList(),
                onChanged: (VerificationLevel? selectedLevel) {
                  if (selectedLevel == null) return;
                  mateDetailsController.selectVerificationLevel(selectedLevel);
                },
                value: mateDetailsController.verificationLevel.value,
                alignment: Alignment.center,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 20,
                elevation: 16,
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColor.main75,
                underline: Container(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
          ),
        ],
      ),
      buttons: [
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppTranslationConstants.goBack.tr,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        DialogButton(
          color: AppColor.bondiBlue75,
          onPressed: () async {
            if (mateDetailsController.verificationLevel.value !=
                mateDetailsController.mate.value.verificationLevel) {
              await mateDetailsController.updateVerificationLevel();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            } else {
              AppUtilities.showSnackBar(
                  title: MateTranslationConstants.updateVerificationLevel.tr,
                  message: MateTranslationConstants.updateVerificationLevelSame
                      .tr);
            }
          },
          child: Text(AppTranslationConstants.toUpdate.tr,
            style: const TextStyle(fontSize: 15),
          ),
        )
      ]
  ).show();

}

  void showUpdateUserRoleAlert(BuildContext context) {
    MateDetailsController mateDetailsController = Sint.put(
        MateDetailsController());

    mateDetailsController.getUserInfo().then((value) {
      Alert(
          context: context,
          style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: MateTranslationConstants.updateUserRole.tr,
          content: Column(
            children: <Widget>[
              AppTheme.heightSpace10,
              Text(MateTranslationConstants.updateUserRoleMsg.tr,
                style: const TextStyle(fontSize: 15),
              ),
              Obx(() =>
                  DropdownButton<UserRole>(
                    items: UserRole.values.map((UserRole userRole) {
                      return DropdownMenuItem<UserRole>(
                        value: userRole,
                        child: Text(userRole.name.tr),
                      );
                    }).toList(),
                    onChanged: (UserRole? selectedRole) {
                      if (selectedRole == null) return;
                      mateDetailsController.selectUserRole(selectedRole);
                    },
                    value: mateDetailsController.newUserRole.value,
                    alignment: Alignment.center,
                    icon: const Icon(Icons.arrow_downward),
                    iconSize: 20,
                    elevation: 16,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: AppColor.main75,
                    underline: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                  ),
              ),
            ],
          ),
          buttons: [
            DialogButton(
              color: AppColor.bondiBlue75,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppTranslationConstants.goBack.tr,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            DialogButton(
              color: AppColor.bondiBlue75,
              onPressed: () async {
                await mateDetailsController.updateUserRole();
              },
              child: Text(AppTranslationConstants.toUpdate.tr,
                style: const TextStyle(fontSize: 15),
              ),
            )
          ]
      ).show();
    });
  }
