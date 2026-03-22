// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/Appcolor.dart';
import 'package:talk_gym/feature/home/data/mock_home_repository.dart';
import 'package:talk_gym/feature/home/view/talk_gym_root_view.dart';
import 'package:talk_gym/core/Theme/theme_provider.dart';

void main() {
  runApp(const TalkGymApp());
}

class TalkGymApp extends StatelessWidget {
  const TalkGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TalkGym',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home:  TalkGymRootView(repository: MockHomeRepository()),
          );
        },
      ),
    );
  }
}
