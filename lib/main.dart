import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';
import 'package:talk_gym/core/navigation/app_routes.dart';
import 'package:talk_gym/feature/auth/data/repository/auth_repository.dart';
import 'package:talk_gym/feature/auth/data/repository/mock_auth_repository.dart';
import 'package:talk_gym/feature/auth/data/service/mock_auth_api_service.dart';
import 'package:talk_gym/feature/auth/view/forgot_password_page.dart';
import 'package:talk_gym/feature/auth/view/login_page.dart';
import 'package:talk_gym/feature/auth/view/sign_up_page.dart';
import 'package:talk_gym/feature/auth/viewmodel/auth_bloc.dart';
import 'package:talk_gym/feature/question/data/repository/http_question_repository.dart';
import 'package:talk_gym/feature/question/view/question_listing_page.dart';
import 'package:talk_gym/feature/question/viewmodel/question_listing_bloc.dart';

void main() {
  runApp(const TalkGymApp());
}

class TalkGymApp extends StatelessWidget {
  const TalkGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => MockAuthRepository(apiService: MockAuthApiService()),
      child: ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return BlocProvider<AuthBloc>(
              create: (BuildContext context) =>
                  AuthBloc(repository: context.read<AuthRepository>())
                    ..add(const CheckAuthStatus()),
              child: MaterialApp(
                title: 'TalkGym',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: themeProvider.themeMode,
                initialRoute: AppRoutes.login,
                routes: <String, WidgetBuilder>{
                  AppRoutes.login: (_) => const LoginPage(),
                  AppRoutes.signUp: (_) => const SignUpPage(),
                  AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
                  AppRoutes.home: (_) => BlocProvider<QuestionListingBloc>(
                    create: (_) =>
                        QuestionListingBloc(repository: HttpQuestionRepository())
                          ..add(const QuestionListingInitialized()),
                    child: const QuestionListingPage(),
                  ),
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
