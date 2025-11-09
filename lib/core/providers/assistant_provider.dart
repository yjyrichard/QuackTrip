import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../utils/sandbox_path_resolver.dart';
import '../models/assistant.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/avatar_cache.dart';
import '../../utils/app_directories.dart';

class AssistantProvider extends ChangeNotifier {
  static const String _assistantsKey = 'assistants_v1';
  static const String _currentAssistantKey = 'current_assistant_id_v1';

  final List<Assistant> _assistants = <Assistant>[];
  String? _currentAssistantId;

  List<Assistant> get assistants => List.unmodifiable(_assistants);
  String? get currentAssistantId => _currentAssistantId;
  Assistant? get currentAssistant {
    final idx = _assistants.indexWhere((a) => a.id == _currentAssistantId);
    if (idx != -1) return _assistants[idx];
    if (_assistants.isNotEmpty) return _assistants.first;
    return null;
  }

  AssistantProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assistantsKey);
    if (raw != null && raw.isNotEmpty) {
      _assistants
        ..clear()
        ..addAll(Assistant.decodeList(raw));
      // Fix any sandboxed local paths (avatars/backgrounds) imported from other platforms
      bool changed = false;
      for (int i = 0; i < _assistants.length; i++) {
        final a = _assistants[i];
        String? av = a.avatar;
        String? bg = a.background;
        if (av != null && av.isNotEmpty && (av.startsWith('/') || av.contains(':')) && !av.startsWith('http')) {
          final fixed = SandboxPathResolver.fix(av);
          if (fixed != av) {
            av = fixed; changed = true;
          }
        }
        if (bg != null && bg.isNotEmpty && (bg.startsWith('/') || bg.contains(':')) && !bg.startsWith('http')) {
          final fixedBg = SandboxPathResolver.fix(bg);
          if (fixedBg != bg) {
            bg = fixedBg; changed = true;
          }
        }
        if (changed) {
          _assistants[i] = a.copyWith(avatar: av, background: bg);
        }
      }
      if (changed) {
        try { await _persist(); } catch (_) {}
      }
    }
    // Do not create defaults here because localization is not available.
    // Defaults will be ensured later via ensureDefaults(context).
    // Restore current assistant if present
    final savedId = prefs.getString(_currentAssistantKey);
    if (savedId != null && _assistants.any((a) => a.id == savedId)) {
      _currentAssistantId = savedId;
    } else {
      _currentAssistantId = null;
    }
    notifyListeners();
  }

  Assistant _defaultAssistant(AppLocalizations l10n) => Assistant(
        id: const Uuid().v4(),
        name: '去哪鸭小助手',
        systemPrompt: '你是去哪鸭（QuackTrip）的旅游规划助手，一只热情活泼的小黄鸭！你的口头禅是"嘎~"。'
            '你擅长帮助用户规划旅行、推荐景点、估算预算、解答旅游相关问题。'
            '回答时要亲切友好，经常使用"嘎~"作为口头禅，让对话充满趣味性。',
        avatar: 'assets/QuacktripLogo.png',
        deletable: false,
        thinkingBudget: null,
        temperature: 0.8,
        topP: 1.0,
      );

  // Ensure localized default assistants exist; call this after localization is ready.
  Future<void> ensureDefaults(dynamic context) async {
    if (_assistants.isNotEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    // 1) 去哪鸭默认助手
    _assistants.add(_defaultAssistant(l10n));

    // 2) 旅游规划师助手
    _assistants.add(Assistant(
      id: const Uuid().v4(),
      name: '旅游规划师 🗺️',
      systemPrompt: '你是一位专业的旅游规划师，擅长根据用户的需求（预算、时间、偏好）设计完整的旅行计划。'
          '你会提供详细的日程安排、景点推荐、交通建议、住宿推荐等。'
          '请以JSON格式返回结构化的旅行计划，包含：目的地、日期、预算、景点列表、每日行程等信息。'
          '记得使用"嘎~"作为口头禅！',
      avatar: 'assets/QuacktripLogo.png',
      deletable: true,
      temperature: 0.7,
      topP: 0.9,
    ));

    // 3) 美食顾问助手
    _assistants.add(Assistant(
      id: const Uuid().v4(),
      name: '美食顾问 🍜',
      systemPrompt: '你是当地美食专家，熟悉各地特色美食、餐厅推荐、小吃攻略。'
          '你会根据用户的口味偏好、预算、用餐时间推荐最合适的美食选择。'
          '介绍美食时要生动形象，让人垂涎欲滴！口头禅是"嘎~"。',
      avatar: 'assets/QuacktripLogo.png',
      deletable: true,
      temperature: 0.8,
      topP: 1.0,
    ));

    // 4) 文化讲解员助手
    _assistants.add(Assistant(
      id: const Uuid().v4(),
      name: '文化讲解员 🏛️',
      systemPrompt: '你是历史文化专家，对各地的历史背景、文化传统、名胜古迹有深入了解。'
          '你会用生动有趣的方式讲解景点的历史故事、文化内涵、参观注意事项。'
          '让用户在旅行中不仅能看到美景，更能理解背后的文化价值。别忘了"嘎~"！',
      avatar: 'assets/QuacktripLogo.png',
      deletable: true,
      temperature: 0.7,
      topP: 0.95,
    ));

    // 5) 预算顾问助手
    _assistants.add(Assistant(
      id: const Uuid().v4(),
      name: '预算顾问 💰',
      systemPrompt: '你是旅游预算专家，擅长帮助用户合理规划旅游开支。'
          '你会分析交通、住宿、餐饮、门票、购物等各项费用，提供省钱攻略。'
          '帮助用户在预算内获得最佳旅游体验。记得说"嘎~"哦！',
      avatar: 'assets/QuacktripLogo.png',
      deletable: true,
      temperature: 0.6,
      topP: 0.9,
    ));

    await _persist();
    // Set current assistant if not set
    if (_currentAssistantId == null && _assistants.isNotEmpty) {
      _currentAssistantId = _assistants.first.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentAssistantKey, _currentAssistantId!);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString( _assistantsKey, Assistant.encodeList(_assistants));
  }

  Future<void> setCurrentAssistant(String id) async {
    if (_currentAssistantId == id) return;
    _currentAssistantId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentAssistantKey, id);
  }

  Assistant? getById(String id) {
    final idx = _assistants.indexWhere((a) => a.id == id);
    if (idx == -1) return null;
    return _assistants[idx];
  }

  // Lightweight accessor so callers don't depend on Assistant.presetMessages symbol
  List<Map<String, String>> getPresetMessagesForAssistant(String? assistantId) {
    Assistant? a;
    if (assistantId != null) {
      a = getById(assistantId);
    } else {
      a = currentAssistant;
    }
    if (a == null) return const <Map<String, String>>[];
    return [
      for (final m in a.presetMessages)
        {
          'role': m.role,
          'content': m.content,
        }
    ];
  }

  Future<String> addAssistant({String? name, dynamic context}) async {
    final a = Assistant(
      id: const Uuid().v4(),
      name: (name ?? (context != null
          ? AppLocalizations.of(context)!.assistantProviderNewAssistantName
          : 'New Assistant')),
      temperature: 0.6,
      topP: 1.0,
    );
    _assistants.add(a);
    await _persist();
    notifyListeners();
    return a.id;
  }

  Future<void> updateAssistant(Assistant updated) async {
    final idx = _assistants.indexWhere((a) => a.id == updated.id);
    if (idx == -1) return;

    var next = updated;

    // If avatar changed and is a local file path (from gallery/cache),
    // copy it to persistent Documents/avatars and store that path.
    try {
      final prev = _assistants[idx];
      final raw = (updated.avatar ?? '').trim();
      final prevRaw = (prev.avatar ?? '').trim();
      final changed = raw != prevRaw;
      final isLocalPath = raw.isNotEmpty && (raw.startsWith('/') || raw.contains(':')) && !raw.startsWith('http');
      // Skip if it's already under our avatars folder
      if (changed && isLocalPath && !raw.contains('/avatars/') && !raw.contains('\\avatars\\')) {
        final fixedInput = SandboxPathResolver.fix(raw);
        final src = File(fixedInput);
        if (await src.exists()) {
          final avatarsDir = await AppDirectories.getAvatarsDirectory();
          if (!await avatarsDir.exists()) {
            await avatarsDir.create(recursive: true);
          }
          String ext = '';
          final dot = fixedInput.lastIndexOf('.');
          if (dot != -1 && dot < fixedInput.length - 1) {
            ext = fixedInput.substring(dot + 1).toLowerCase();
            if (ext.length > 6) ext = 'jpg';
          } else {
            ext = 'jpg';
          }
          final filename = 'assistant_${updated.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final dest = File('${avatarsDir.path}/$filename');
          await src.copy(dest.path);

          // Optionally remove old stored avatar if it lives in our avatars folder
          if (prevRaw.isNotEmpty && (prevRaw.contains('/avatars/') || prevRaw.contains('\\avatars\\'))) {
            try {
              final old = File(prevRaw);
              if (await old.exists() && old.path != dest.path) {
                await old.delete();
              }
            } catch (_) {}
          }

          next = updated.copyWith(avatar: dest.path);
        }
      }

      // Prefetch URL avatar to allow offline display later
      if (changed && raw.startsWith('http')) {
        try { await AvatarCache.getPath(raw); } catch (_) {}
      }

      // Handle background persistence similar to avatar, but under images/
      final bgRaw = (updated.background ?? '').trim();
      final prevBgRaw = (prev.background ?? '').trim();
      final bgChanged = bgRaw != prevBgRaw;
      final bgIsLocal = bgRaw.isNotEmpty && (bgRaw.startsWith('/') || bgRaw.contains(':')) && !bgRaw.startsWith('http');
      if (bgChanged && bgIsLocal && !bgRaw.contains('/images/') && !bgRaw.contains('\\images\\')) {
        final fixedBg = SandboxPathResolver.fix(bgRaw);
        final srcBg = File(fixedBg);
        if (await srcBg.exists()) {
          final imagesDir = await AppDirectories.getImagesDirectory();
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          String ext = '';
          final dot = fixedBg.lastIndexOf('.');
          if (dot != -1 && dot < fixedBg.length - 1) {
            ext = fixedBg.substring(dot + 1).toLowerCase();
            if (ext.length > 6) ext = 'jpg';
          } else {
            ext = 'jpg';
          }
          final filename = 'background_${updated.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final destBg = File('${imagesDir.path}/$filename');
          await srcBg.copy(destBg.path);

          // Clean old stored background if it lived in images/
          if (prevBgRaw.isNotEmpty && (prevBgRaw.contains('/images/') || prevBgRaw.contains('\\images\\'))) {
            try {
              final oldBg = File(prevBgRaw);
              if (await oldBg.exists() && oldBg.path != destBg.path) {
                await oldBg.delete();
              }
            } catch (_) {}
          }

          next = next.copyWith(background: destBg.path);
        }
      } else if (bgChanged && bgRaw.isEmpty && prevBgRaw.contains('/images/')) {
        // If background cleared, optionally remove previous stored file
        try {
          final oldBg = File(prevBgRaw);
          if (await oldBg.exists()) {
            await oldBg.delete();
          }
        } catch (_) {}
      }
    } catch (_) {
      // On any failure, fall back to the provided value unchanged.
    }

    _assistants[idx] = next;
    await _persist();
    notifyListeners();
  }

  Future<bool> deleteAssistant(String id) async {
    final idx = _assistants.indexWhere((a) => a.id == id);
    if (idx == -1) return false;
    // Do not allow deleting the last remaining assistant
    if (_assistants.length <= 1) return false;
    final removingCurrent = _assistants[idx].id == _currentAssistantId;
    _assistants.removeAt(idx);
    if (removingCurrent) {
      _currentAssistantId = _assistants.isNotEmpty ? _assistants.first.id : null;
    }
    await _persist();
    final prefs = await SharedPreferences.getInstance();
    if (_currentAssistantId != null) {
      await prefs.setString(_currentAssistantKey, _currentAssistantId!);
    } else {
      await prefs.remove(_currentAssistantKey);
    }
    notifyListeners();
    return true;
  }

  Future<void> reorderAssistants(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _assistants.length) return;
    if (newIndex < 0 || newIndex >= _assistants.length) return;
    
    final assistant = _assistants.removeAt(oldIndex);
    _assistants.insert(newIndex, assistant);
    
    // Notify listeners immediately for smooth UI update
    notifyListeners();
    
    // Then persist the changes
    await _persist();
  }

  // Reorder only within a subset (e.g., assistants belonging to a tag group or ungrouped).
  // subsetIds defines the set and order boundary; other assistants remain in place.
  Future<void> reorderAssistantsWithin({
    required List<String> subsetIds,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex == newIndex) return;
    if (subsetIds.isEmpty) return;

    // Build subset indices in the master list preserving current order
    final idSet = subsetIds.toSet();
    final subsetIndices = <int>[];
    for (int i = 0; i < _assistants.length; i++) {
      if (idSet.contains(_assistants[i].id)) subsetIndices.add(i);
    }
    if (subsetIndices.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= subsetIndices.length) return;
    if (newIndex < 0 || newIndex >= subsetIndices.length) return;

    // Extract subset in current order
    final subset = subsetIndices.map((i) => _assistants[i]).toList(growable: true);
    final moved = subset.removeAt(oldIndex);
    subset.insert(newIndex, moved);

    // Merge back into master list
    final merged = <Assistant>[];
    int take = 0;
    for (int i = 0; i < _assistants.length; i++) {
      final a = _assistants[i];
      if (idSet.contains(a.id)) {
        merged.add(subset[take++]);
      } else {
        merged.add(a);
      }
    }
    _assistants
      ..clear()
      ..addAll(merged);

    notifyListeners();
    await _persist();
  }
}
