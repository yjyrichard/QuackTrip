import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import './travel_database_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 认证服务（本地账户系统）
class AuthService extends ChangeNotifier {
  static const String _currentUserKey = 'current_user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  UserAccount? _currentUser;
  bool _isLoggedIn = false;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  final TravelDatabaseService _db = TravelDatabaseService.instance;

  /// 初始化认证状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (_isLoggedIn) {
      final userId = prefs.getInt(_currentUserKey);
      if (userId != null) {
        // 从数据库加载用户信息
        final db = await _db.database;
        final maps = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (maps.isNotEmpty) {
          _currentUser = UserAccount.fromMap(maps.first);
        } else {
          // 用户不存在，清除登录状态
          await logout();
        }
      }
    }
    notifyListeners();
  }

  /// 密码加密（简单示例，实际应用应使用更安全的方法）
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 注册新用户
  Future<bool> register({
    required String username,
    required String password,
    String? email,
    String? nickname,
  }) async {
    try {
      // 检查用户名是否已存在
      final existingUser = await _db.getUserByUsername(username);
      if (existingUser != null) {
        return false; // 用户名已存在
      }

      // 创建新用户
      final hashedPassword = _hashPassword(password);
      final newUser = UserAccount(
        username: username,
        password: hashedPassword,
        email: email,
        nickname: nickname ?? username,
      );

      final createdUser = await _db.createUser(newUser);

      // 自动登录
      await _saveLoginState(createdUser);

      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  /// 登录
  Future<bool> login(String username, String password) async {
    try {
      final user = await _db.getUserByUsername(username);
      if (user == null) {
        return false; // 用户不存在
      }

      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return false; // 密码错误
      }

      // 更新最后登录时间
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _db.updateUser(updatedUser);

      // 保存登录状态
      await _saveLoginState(updatedUser);

      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// 保存登录状态
  Future<void> _saveLoginState(UserAccount user) async {
    _currentUser = user;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_currentUserKey, user.id!);

    notifyListeners();
  }

  /// 登出
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_currentUserKey);

    notifyListeners();
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({
    String? nickname,
    String? email,
    String? avatar,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        nickname: nickname ?? _currentUser!.nickname,
        email: email ?? _currentUser!.email,
        avatar: avatar ?? _currentUser!.avatar,
      );

      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Update user error: $e');
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;

    try {
      final hashedOldPassword = _hashPassword(oldPassword);
      if (_currentUser!.password != hashedOldPassword) {
        return false; // 旧密码错误
      }

      final hashedNewPassword = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(password: hashedNewPassword);

      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;

      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }
}
