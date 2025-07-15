import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/diagonally_cut_colored_image.dart';
import 'package:neom_commons/utils/app_alerts.dart';
import 'package:neom_commons/utils/app_utilities.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/utils/constants/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/data/implementations/report_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/menu_three_dots.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/reference_type.dart';
import 'package:neom_core/utils/enums/report_type.dart';
import 'package:neom_core/utils/enums/user_role.dart';
import 'package:neom_core/utils/enums/verification_level.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../mate_details_controller.dart';

class MateDetailHeader extends StatelessWidget {
  const MateDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      builder: (_) => Stack(
      children: <Widget>[
        FutureBuilder(
          future: CoreUtilities().isAvailableMediaUrl(_.mate.value.coverImgUrl.isNotEmpty ?
            _.mate.value.coverImgUrl : _.mate.value.photoUrl.isNotEmpty
            ? _.mate.value.photoUrl : AppProperties.getAppLogoUrl()),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
                return DiagonallyCutColoredImage(
                  Image(
                      image: NetworkImage(
                          (snapshot.data == true) ?
                          (_.mate.value.coverImgUrl.isNotEmpty ?
                      _.mate.value.coverImgUrl : _.mate.value.photoUrl.isNotEmpty
                          ? _.mate.value.photoUrl : AppProperties.getAppLogoUrl()) : AppProperties.getAppLogoUrl(),),
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
                tag: _.mate.value.name,
                child: FutureBuilder(
                  future: CoreUtilities().isAvailableMediaUrl(_.mate.value.photoUrl.isNotEmpty
                      ? _.mate.value.photoUrl : AppProperties.getAppLogoUrl(),),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return CircleAvatar(
                        backgroundImage: NetworkImage((snapshot.data == true) ?
                        (_.mate.value.photoUrl.isNotEmpty ? _.mate.value.photoUrl : AppProperties.getAppLogoUrl())
                            : AppProperties.getAppLogoUrl(),),
                        radius: 60.0,
                        onBackgroundImageError: (object, error) => CachedNetworkImageProvider(_.mate.value.photoUrl.isNotEmpty ? _.mate.value.photoUrl
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
              AppConfig.instance.appInUse != AppInUse.e || _.mateBlogEntries.isEmpty
                  ? const SizedBox.shrink() : TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    padding: EdgeInsets.zero
                ),
                child: AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    FlickerAnimatedText(AppTranslationConstants.checkMyBlog.tr,
                        textStyle: const TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.underline
                        )
                    ),
                  ],
                  onTap: () {
                    Get.toNamed(AppRouteConstants.mateBlog, arguments: [_.mate]);
                  },
                ),
                onPressed: () => {

                },
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: _.mateBlogEntries.isEmpty ? 40.0 : 20.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: AppTheme.appBoxDecorationBlueGrey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: Obx(()=> MaterialButton(
                          minWidth: 140.0,
                          color: Colors.transparent,
                          child: Text((_.following.value ? AppTranslationConstants.unfollow
                              : AppTranslationConstants.follow).tr.toUpperCase()),
                          onPressed: () {
                            _.following.value ? _.unfollow() : _.follow();
                          },
                        ),),
                      ),
                    ),
                    DecoratedBox(
                      decoration: AppTheme.appBoxDecorationBlueGrey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.0),
                        child: MaterialButton(
                          minWidth: 140.0,
                          color: Colors.transparent,
                          child: Text(AppTranslationConstants.message.tr.toUpperCase()),
                          onPressed: () {
                            _.sendMessage();
                          },
                        ),
                      ),
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
                        return _buildDotsMenu(context, _.mate.value, _.userController.user.userRole);
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

Widget _buildDotsMenu(BuildContext context, AppProfile itemmate, UserRole userRole) {

  List<Menu3DotsModel> listMore = [];
  listMore.add(Menu3DotsModel(AppTranslationConstants.reportProfile.tr, AppTranslationConstants.reportPostMsg,
      Icons.info, AppTranslationConstants.reportProfile));
  listMore.add(Menu3DotsModel(AppTranslationConstants.blockProfile.tr, AppTranslationConstants.blockProfileMsg,
      Icons.block, AppTranslationConstants.blockProfile));
  if(userRole != UserRole.subscriber) {
    listMore.add(Menu3DotsModel(AppTranslationConstants.updateVerificationLevel.tr, AppTranslationConstants.updateVerificationLevelMsg,
        Icons.verified, AppTranslationConstants.updateVerificationLevel));
    listMore.add(Menu3DotsModel(AppTranslationConstants.removeProfile.tr, AppTranslationConstants.removeProfileMsg,
        Icons.delete, AppTranslationConstants.removeProfile));
    if(userRole == UserRole.superAdmin) {
      listMore.add(Menu3DotsModel(AppTranslationConstants.updateUserRole.tr, AppTranslationConstants.updateUserRoleMsg,
          Icons.verified_user_rounded, AppTranslationConstants.updateUserRole));
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
              onTap: () async {
                switch (listMore[index].action) {
                  case AppTranslationConstants.reportProfile:
                    showReportProfileAlert(context, itemmate);
                    break;
                  case AppTranslationConstants.blockProfile:
                    showBlockProfileAlert(context);
                    break;
                  case AppTranslationConstants.removeProfile:
                    showRemoveProfileAlert(context);
                    break;
                  case AppTranslationConstants.updateVerificationLevel:
                    showUpdateVerificationLevelAlert(context);
                    break;
                  case AppTranslationConstants.updateUserRole:
                    showUpdateUserRoleAlert(context);
                    break;
                }
                //Get.back();
              },
            );
          })
  );
}

void showRemoveProfileAlert(BuildContext context) {
  MateDetailsController mateDetailsController = Get.put(MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: AppTranslationConstants.removeProfile.tr,
      content: Column(
        children: [
          Text(AppTranslationConstants.removeProfileMsg.tr,
            style: const TextStyle(fontSize: 15),
          ),
          AppTheme.heightSpace10,
          Text(AppTranslationConstants.removeProfileMsg2.tr,
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
  MateDetailsController mateDetailsController = Get.put(MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: AppTranslationConstants.blockProfile.tr,
      content: Column(
        children: [
          Text(AppTranslationConstants.blockProfileMsg.tr,
            style: const TextStyle(fontSize: 15),
          ),
          AppTheme.heightSpace10,
          Text(AppTranslationConstants.blockProfileMsg2.tr,
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
  ReportController reportController = Get.put(ReportController());
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
              DropdownButton<String>(
                items: ReportType.values.map((ReportType reportType) {
                  return DropdownMenuItem<String>(
                    value: reportType.name,
                    child: Text(reportType.name.tr),
                  );
                }).toList(),
                onChanged: (String? reportType) {
                  reportController.setReportType(reportType ?? "");
                },
                value: reportController.reportType.value,
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
              reportController.setMessage(text);
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
            if(!reportController.isButtonDisabled.value) {
              await reportController.sendReport(ReferenceType.profile, itemmate.id);
              AppAlerts.showAlert(context, title: AppTranslationConstants.report.tr,
                  message: AppTranslationConstants.hasSentReport.tr);
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
  MateDetailsController mateDetailsController = Get.put(
      MateDetailsController());
  Alert(
      context: context,
      style: AlertStyle(
        backgroundColor: AppColor.main50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: AppTranslationConstants.verificationLevel.tr,
      content: Column(
        children: <Widget>[
          AppTheme.heightSpace10,
          Text(AppTranslationConstants.updateVerificationLevelMsg.tr,
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
                  title: AppTranslationConstants.updateVerificationLevel.tr,
                  message: AppTranslationConstants.updateVerificationLevelSame
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
    MateDetailsController mateDetailsController = Get.put(
        MateDetailsController());

    mateDetailsController.getUserInfo().then((value) {
      Alert(
          context: context,
          style: AlertStyle(
            backgroundColor: AppColor.main50,
            titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: AppTranslationConstants.updateUserRole.tr,
          content: Column(
            children: <Widget>[
              AppTheme.heightSpace10,
              Text(AppTranslationConstants.updateUserRoleMsg.tr,
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
