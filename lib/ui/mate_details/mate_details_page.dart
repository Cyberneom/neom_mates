import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'footer/mate_detail_footer.dart';
import 'header/mate_details_header.dart';
import 'mate_details_body.dart';
import 'mate_details_controller.dart';

class MateDetailsPage extends StatelessWidget {
  const MateDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: AppTheme.appBoxDecoration,
          child: Obx(()=> _.isLoading.value ? const AppCircularProgressIndicator()
              : _.blockedProfile ? const SizedBox.shrink() : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MateDetailHeader(),
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.padding20),
                    child: MateDetailsBody(),
                  ),
                  Obx(()=> _.isLoadingDetails.value ? const Center(child: LinearProgressIndicator())
                      : const MateShowcase(),),
                ],
              ),
          ),),
        ),
      ),
    );
  }
}
