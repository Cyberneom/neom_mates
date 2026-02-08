import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/appbar_child.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/data/implementations/mate_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:sint/sint.dart';

import '../utils/constants/mate_translation_constants.dart';

class MateListPage extends StatelessWidget {
  const MateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<MateController>(
      id: AppPageIdConstants.mates,
      init: MateController(),
      builder: (controller) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarChild(title: MateTranslationConstants.itemmateSearch.tr)),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: controller.mates.isEmpty ?
          const Center(child: CircularProgressIndicator(),)
            : ListView.builder(
          itemCount: controller.mates.length,
          itemBuilder: (context, index) {
            AppProfile mate = controller.mates.values.elementAt(index);
            return GestureDetector(
              child: ListTile(
                onTap: () => controller.getMateDetails(mate),
                leading: Hero(
                  tag: mate.photoUrl,
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(mate.photoUrl),
                  ),
                ),
                title: Text(mate.name),
                subtitle: Row(
                  children: [
                    if(mate.favoriteItems?.isNotEmpty ?? false) Text(mate.favoriteItems!.length.toString()),
                    Icon(AppFlavour.getAppItemIcon(),
                      color: Colors.blueGrey, size: 20,),
                    Text(mate.mainFeature.tr.capitalize),
                  ]),
                ),
              onLongPress: () => {},
            );
          },
        ),
      )
    ));
  }
}
