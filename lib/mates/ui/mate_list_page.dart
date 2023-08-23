import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/implementations/mate_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

class MateListPage extends StatelessWidget {
  const MateListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MateController>(
      id: AppPageIdConstants.mates,
      init: MateController(),
      builder: (_) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBarChild(title: AppTranslationConstants.itemmateSearch.tr)),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: _.mates.isEmpty ?
          const Center(child: CircularProgressIndicator(),)
            : ListView.builder(
          itemCount: _.mates.length,
          itemBuilder: (context, index) {
            AppProfile mate = _.mates.values.elementAt(index);
            return GestureDetector(
              child: ListTile(
                onTap: () => _.getMateDetails(mate),
                leading: Hero(
                  tag: mate.photoUrl,
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(mate.photoUrl),
                  ),
                ),
                title: Text(mate.name),
                subtitle: Row(
                  children: [
                    Text(mate.favoriteItems!.length.toString()),
                    Icon(AppFlavour.getAppItemIcon(),
                      color: Colors.blueGrey, size: 20,),
                    Text(mate.mainFeature.tr.capitalize!),
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
