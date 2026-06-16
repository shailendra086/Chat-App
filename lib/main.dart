import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/routes/app_pages.dart';
import 'package:chat_app/services/notification_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


void main ()async{

   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform);
   
   // Initialize push settings & listeners on app startup
   await NotificationService().initialize();

   runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Chat App",
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      debugShowCheckedModeBanner: false,
    );
  }
}