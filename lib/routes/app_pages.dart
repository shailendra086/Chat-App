import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/views/auth/forgot_password_view.dart';
import 'package:chat_app/views/auth/login_view.dart';
import 'package:chat_app/views/auth/register_view.dart';
import 'package:chat_app/views/profile_view.dart';
import 'package:chat_app/views/splash_view.dart';
import 'package:get/get.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),

    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
    ),

    // GetPage(
    //   name: AppRoutes.changePassword,
    //   page: () => const ChangePasswordView(),
    // ),
    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(HomeController());
    //   }),
    // ),
    // GetPage(
    //   name: AppRoutes.main,
    //   page: () => const MainView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(MainController());
    //   }),
    // ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    // GetPage(
    //   name: AppRoutes.chat,
    //   page: () => const ChatView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(ChatController());
    //   }),
    // ),

    // GetPage(
    //   name: AppRoutes.userList,
    //   page: () => const UserListView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(UserListController());
    //   }),
    // ),

    // GetPage(
    //   name: AppRoutes.friends,
    //   page: () => const FriendsView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendsController());
    //   }),
    // ),

    // GetPage(
    //   name: AppRoutes.friendRequest,
    //   page: () => const FriendRequestView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(FriendRequestController());
    //   }),
    // ),

    // GetPage(
    //   name: AppRoutes.notifications,
    //   page: () => const NotificationView(),
    //   binding: BindingsBuilder(() {
    //     Get.put(NotificationController());
    //   }),
    // ),
  ];
}
