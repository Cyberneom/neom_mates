import 'package:get/get.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/mate_details/mate_details_page.dart';
import 'ui/mate_list_page.dart';

class MatesRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.mates,
      page: () => const MateListPage(),
    ),
    GetPage(
      name: AppRouteConstants.mateDetails,
      page: () => const MateDetailsPage(),
      transition: Transition.zoom,
    ),
  ];

}
