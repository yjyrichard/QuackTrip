import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import 'login_page.dart';
import '../../home/pages/home_page.dart';
import '../../../desktop/desktop_home_page.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb, debugPrint;

/// 启动页面 - 检查登录状态并导航到相应页面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在 build 完成后再执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // 初始化认证服务
      final authService = context.read<AuthService>();
      await authService.init();

      // 等待一小段时间显示启动画面
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 根据登录状态导航
      if (authService.isLoggedIn) {
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      // 如果出错，默认跳转到登录页
      debugPrint('Auth init error: $e');
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => isDesktop ? const DesktopHomePage() : const HomePage(),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 100,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '去哪鸭',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'QuackTrip',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
