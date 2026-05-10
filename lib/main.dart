import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guidex/app_routes.dart';
import 'package:guidex/screens/splash_screen.dart';
import 'package:guidex/onboardingscreen.dart';
import 'package:guidex/login_page.dart';
import 'package:guidex/signup_page.dart';
import 'package:guidex/user_category_page.dart';
import 'package:guidex/screens/analysis_test_page.dart';
import 'package:guidex/screens/analysis_results_page.dart';
import 'package:guidex/screens/final_report_page.dart';
import 'package:guidex/models/recommendation.dart';
import 'package:guidex/models/recommendation_result.dart';

import 'package:guidex/services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start warming up API cache in background
  ApiService().warmup();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint('Firebase initialization failed or timed out: $e');
    // Continue to onboarding even if Firebase initialization fails.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nextep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.signup: (context) => const SignUpPage(),
        AppRoutes.userCategory: (context) => const UserCategoryPage(),
        AppRoutes.analysisTest: (context) => const AnalysisTestPage(),
        AppRoutes.analysisResults: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return AnalysisResultsPage(
            name: args?['name'] as String?,
            cutoff: (args?['cutoff'] as num?)?.toDouble(),
            category: args?['category'] as String?,
            selectedCourses: (args?['selectedCourses'] as List?)
                ?.map((e) => e.toString())
                .toList(),
            interest: args?['interest'] as String?,
            district: args?['district'] as String?,
            preferredCollegeIds: (args?['preferredCollegeIds'] as List?)
                ?.map((e) => e.toString())
                .toList(),
            preferredColleges: (args?['preferredColleges'] as List?)
                ?.map((e) => e.toString())
                .toList(),
            prefetchedResult:
                args?['prefetchedResult'] as RecommendationResult?,
            prefetchedRecommendations:
                (args?['prefetchedRecommendations'] as List?)
                    ?.whereType<Recommendation>()
                    .toList(),
            prefetchError: args?['prefetchError'] as String?,
          );
        },
        AppRoutes.finalReport: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return FinalReportPage(
            studentName: args?['studentName'] as String? ?? 'Student',
            category: args?['category'] as String? ?? 'OC',
            studentCutoff: (args?['studentCutoff'] as num?)?.toDouble() ?? 0,
            preferredCourse: args?['preferredCourse'] as String? ?? '',
            district: args?['district'] as String?,
            hostelRequired: args?['hostelRequired'] as bool? ?? false,
            preferredCollegeIds: (args?['preferredCollegeIds'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            preferredCollegeNames: (args?['preferredCollegeNames'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            allRecommendations: args?['allRecommendations'] as List<Recommendation>?,
            safeColleges: args?['safeColleges'] as List<Recommendation>?,
            preferredRecommendations: args?['preferredRecommendations'] as List<Recommendation>?,
          );
        },
      },
    );
  }
}
