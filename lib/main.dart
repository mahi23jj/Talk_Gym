import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';
import 'package:talk_gym/feature/question/data/repository/mock_question_repository.dart';
import 'package:talk_gym/feature/question/view/question_listing_page.dart';
import 'package:talk_gym/feature/question/viewmodel/question_listing_bloc.dart';

void main() {
  runApp(const TalkGymApp());
}

class TalkGymApp extends StatelessWidget {
  const TalkGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TalkGym',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: BlocProvider(
              create: (_) => QuestionListingBloc(
                repository: MockQuestionRepository(),
              )..add(const QuestionListingInitialized()),
              child: const QuestionListingPage(),
            ),
          );
        },
      ),
    );
  }
}
