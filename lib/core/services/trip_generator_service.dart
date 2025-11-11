import 'package:flutter/foundation.dart';
import 'trip_json_parser.dart';
import 'travel_database_service.dart';
import '../models/trip.dart';
import '../models/attraction.dart';
import '../models/itinerary.dart';
import '../models/expense.dart';

/// AI旅行计划生成服务
///
/// 职责：
/// 1. 从AI返回的文本中识别并解析旅行计划JSON
/// 2. 将解析后的数据保存到SQLite数据库
/// 3. 提供旅行计划预览功能
/// 4. 处理保存失败和回滚
class TripGeneratorService extends ChangeNotifier {
  final TripJsonParser _parser = TripJsonParser();
  final TravelDatabaseService _db = TravelDatabaseService.instance;

  /// 当前解析结果
  ParseResult? _currentResult;

  /// 正在保存
  bool _isSaving = false;

  ParseResult? get currentResult => _currentResult;
  bool get isSaving => _isSaving;
  bool get hasResult => _currentResult != null && _currentResult!.success;

  /// 从AI响应中生成旅行计划（仅解析，不保存）
  ///
  /// [aiResponse] AI返回的完整文本
  /// 返回是否解析成功
  bool parseFromAiResponse(String aiResponse) {
    try {
      _currentResult = _parser.parse(aiResponse);
      notifyListeners();
      return _currentResult!.success;
    } catch (e) {
      debugPrint('❌ 解析AI响应失败: $e');
      _currentResult = ParseResult.error('解析失败：$e');
      notifyListeners();
      return false;
    }
  }

  /// 保存当前解析的旅行计划到数据库
  ///
  /// 返回保存后的旅行ID，失败返回null
  Future<int?> saveTripPlan() async {
    if (!hasResult) {
      debugPrint('❌ 没有可保存的旅行计划');
      return null;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final result = _currentResult!;

      // 1. 保存Trip
      debugPrint('📝 保存旅行计划...');
      final savedTrip = await _db.createTrip(result.trip!);
      final tripId = savedTrip.id!;
      debugPrint('✅ 旅行计划已保存，ID: $tripId');

      // 2. 保存Attractions并收集ID
      debugPrint('📝 保存 ${result.attractions!.length} 个景点...');
      final attractionIds = <int>[];
      for (final attraction in result.attractions!) {
        final savedAttraction = await _db.createAttraction(
          attraction.copyWith(tripId: tripId),
        );
        attractionIds.add(savedAttraction.id!);
      }
      debugPrint('✅ 景点已保存');

      // 3. 更新Itineraries的景点关联ID，然后保存
      debugPrint('📝 保存 ${result.itineraries!.length} 条行程...');
      final updatedItineraries = TripJsonParser.updateAttractionIds(
        result.itineraries!,
        attractionIds,
      );
      for (final itinerary in updatedItineraries) {
        await _db.createItinerary(itinerary.copyWith(tripId: tripId));
      }
      debugPrint('✅ 行程已保存');

      // 4. 保存Expenses
      debugPrint('📝 保存 ${result.expenses!.length} 条花费记录...');
      for (final expense in result.expenses!) {
        await _db.createExpense(expense.copyWith(tripId: tripId));
      }
      debugPrint('✅ 花费记录已保存');

      debugPrint('🎉 旅行计划「${savedTrip.destination}」保存成功！');

      // 清空当前结果
      _currentResult = null;
      _isSaving = false;
      notifyListeners();

      return tripId;
    } catch (e, stackTrace) {
      debugPrint('❌ 保存旅行计划失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');

      _isSaving = false;
      notifyListeners();

      return null;
    }
  }

  /// 直接从AI响应生成并保存旅行计划（一步到位）
  ///
  /// [aiResponse] AI返回的完整文本
  /// 返回保存后的旅行ID，失败返回null
  Future<int?> generateAndSave(String aiResponse) async {
    final parsed = parseFromAiResponse(aiResponse);
    if (!parsed) {
      return null;
    }
    return await saveTripPlan();
  }

  /// 检查文本中是否包含旅行计划JSON
  ///
  /// 用于快速判断AI响应是否包含可解析的旅行计划
  bool containsTripPlanJson(String text) {
    // 检查是否包含关键字段
    return text.contains('"tripPlan"') &&
           text.contains('"basicInfo"') &&
           (text.contains('```json') || text.contains('{'));
  }

  /// 获取当前结果的摘要
  String? getSummary() {
    return _currentResult?.getSummary();
  }

  /// 清空当前结果
  void clearResult() {
    _currentResult = null;
    notifyListeners();
  }

  /// 获取解析错误信息
  String? getError() {
    return _currentResult?.error;
  }
}
