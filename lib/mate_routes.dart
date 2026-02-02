import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/mate_details/mate_details_page.dart';
import 'ui/mate_list_page.dart';

class MateRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
      name: AppRouteConstants.mates,
      page: () => const MateListPage(),
    ),
    SintPage(
      name: AppRouteConstants.mateDetails,
      page: () => const MateDetailsPage(),
      transition: Transition.zoom,
    ),
  ];

}
