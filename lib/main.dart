import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:TBConsult/core/di/injection_container.dart' as di;
import 'features/splash/presentation/pages/splash_screen.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const TBConsultApp());
}

class TBConsultApp extends StatelessWidget {
  const TBConsultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TBConsult',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      home: const SplashScreen(), // Update starting route
    );
  }
}