import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/nevigate.dart';
import 'services/notification_service.dart';
import 'services/fcm.dart';
import 'styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp();

  // 2. 로컬 노티피케이션 엔진 초기화
  await NotificationService().init();

  // 3. 실시간 FCM 수신 리스너 가동
  await FCMService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SALMON',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFAFAFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          primary: AppColors.brand,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
