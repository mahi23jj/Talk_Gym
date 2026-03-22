// lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talk_gym/core/Appcolor.dart';


class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get currentTheme => _isDarkMode 
      ? AppTheme.darkTheme() 
      : AppTheme.lightTheme();
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }
}

// Theme Toggle Button with Animation
class AnimatedThemeToggle extends StatelessWidget {
  const AnimatedThemeToggle({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode 
              ? AppColors.darkSurface 
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (themeProvider.isDarkMode 
                  ? AppColors.darkCardShadow 
                  : AppColors.lightCardShadow).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            themeProvider.isDarkMode 
                ? Icons.light_mode_rounded 
                : Icons.dark_mode_rounded,
            key: ValueKey(themeProvider.isDarkMode),
            color: themeProvider.isDarkMode 
                ? AppColors.darkPrimary 
                : AppColors.lightPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}