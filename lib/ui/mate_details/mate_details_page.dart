import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:sint/sint.dart';
import 'footer/mate_detail_footer.dart';
import 'header/mate_details_header.dart';
import 'mate_details_body.dart';
import 'mate_details_controller.dart';

class MateDetailsPage extends StatelessWidget {
  const MateDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateDetailsController>(
      id: AppPageIdConstants.mate,
      init: MateDetailsController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: AppTheme.appBoxDecoration,
          child: Obx(()=> controller.isLoading.value ? const AppCircularProgressIndicator()
              : controller.blockedProfile ? const SizedBox.shrink() : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MateDetailHeader(),
                  const Padding(
                    padding: EdgeInsets.all(AppTheme.padding20),
                    child: MateDetailsBody(),
                  ),
                  Obx(()=> controller.isLoadingDetails.value ? const Center(child: LinearProgressIndicator())
                      : const MateShowcase(),),
                ],
              ),
          ),),
        ),
      ),
    );
  }
}
