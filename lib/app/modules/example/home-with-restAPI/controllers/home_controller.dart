import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:getx_standard/app/modules/example/home-with-restAPI/model/recipes_model.dart';
import 'package:getx_standard/app/service/helper/network_connectivity.dart';

import '../../../../components/global-widgets/custom_snackbar.dart';
import '../../../../components/navbar/navbar_controller.dart';
import '../../../../data/local/hive/my_hive.dart';
import '../../../../service/REST/api_urls.dart';
import '../../../../service/REST/dio_client.dart';
import '../../../../service/handler/exception_handler.dart';

class HomeController extends GetxController with ExceptionHandler {
  final navController = Get.put(NavbarController());
  final scrollController = ScrollController();

  RxDouble bottomPadding = 18.sp.obs;

  RxString title = "".obs;
  RxString body = "".obs;

  final recipes = RxList<Results>();

  scrollPositionTracker() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >
          scrollController.position.minScrollExtent + 5) {
        bottomPadding.value = 18.sp;
        // position in Top
      }
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent) {
        bottomPadding.value = 130.sp;
        // position in Bottom
      }
    });
  }

  /// GET ALL RECIPES LIST 'HIVE IMPLEMENTED'

  getRecipes() async {
    showLoading();
    if (await NetworkConnectivity.isNetworkAvailable()) {
      /// Fetch recipes from the API
      var response = await DioClient()
          .get(
            url: ApiUrl.allRecipes,
          )
          .catchError(handleError);

      if (response == null) return;

      recipes.assignAll((response["results"] as List)
          .map((e) => Results.fromJson(e))
          .toList());

      /// Save fetched posts to Hive for future use
      await MyHive.saveAllRecipes(recipes);
      hideLoading();
    } else {
      /// If offline, try to load from Hive
      var savedRecipes = MyHive.getAllRecipes();

      if (savedRecipes.isNotEmpty) {
        recipes.assignAll(savedRecipes);
        hideLoading();
        CustomSnackBar.showCustomErrorToast(message: "No network!");
        return;
      } else {
        isError.value = true;

        hideLoading();
        showErrorDialog("Oops!", "Connection problem");
        return;
      }
    }
  }

  @override
  void onReady() async {
    await getRecipes();
    // scrollController.addListener(() {
    //   if (scrollController.position.atEdge) {
    //     bool isTop = scrollController.position.pixels == 0;
    //     if (isTop) {
    //       bottomPadding.value = 18.sp;
    //       print('At the top');
    //     } else {
    //       bottomPadding.value = 50.sp;
    //       print('At the bottom');
    //     }
    //   }
    // });
    super.onReady();
  }

  @override
  void onInit() {
    super.onInit();

    scrollPositionTracker();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
