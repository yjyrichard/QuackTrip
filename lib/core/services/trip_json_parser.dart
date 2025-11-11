import 'dart:convert';
import '../models/trip.dart';
import '../models/attraction.dart';
import '../models/itinerary.dart';
import '../models/expense.dart';
import '../schemas/trip_generation_schema.dart';

/// AI生成旅行计划的JSON解析器
///
/// 功能：
/// 1. 从AI返回的文本中提取JSON（支持markdown代码块）
/// 2. 解析JSON为Trip、Attraction、Itinerary、Expense模型
/// 3. 验证数据完整性
class TripJsonParser {
  /// 解析结果
  ParseResult? _lastResult;

  /// 获取最后一次解析结果
  ParseResult? get lastResult => _lastResult;

  /// 从AI返回的文本中解析旅行计划
  ///
  /// [aiResponse] AI返回的完整文本，可能包含markdown代码块
  /// [tripId] 关联的旅行ID（如果是保存到已存在的旅行）
  ///
  /// 返回 ParseResult，包含解析状态和数据
  ParseResult parse(String aiResponse, {int? tripId}) {
    try {
      // 1. 提取JSON内容
      final jsonText = _extractJson(aiResponse);
      if (jsonText.isEmpty) {
        _lastResult = ParseResult.error('未找到有效的JSON数据');
        return _lastResult!;
      }

      // 2. 解析JSON
      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      // 3. 验证数据
      final errors = TripGenerationSchema.validate(json);
      if (errors.isNotEmpty) {
        _lastResult = ParseResult.error('JSON数据不完整：${errors.join(', ')}');
        return _lastResult!;
      }

      // 4. 解析为模型对象
      final tripPlan = json['tripPlan'] as Map<String, dynamic>;
      final trip = _parseTrip(tripPlan, tripId: tripId);
      final attractions = _parseAttractions(tripPlan, tripId: tripId ?? 0);
      final itineraries = _parseItineraries(tripPlan, tripId: tripId ?? 0, attractions: attractions);
      final expenses = _parseExpenses(tripPlan, tripId: tripId ?? 0);

      _lastResult = ParseResult.success(
        trip: trip,
        attractions: attractions,
        itineraries: itineraries,
        expenses: expenses,
      );

      return _lastResult!;
    } catch (e, stackTrace) {
      print('❌ 解析旅行计划失败: $e');
      print('堆栈跟踪: $stackTrace');
      _lastResult = ParseResult.error('解析失败：$e');
      return _lastResult!;
    }
  }

  /// 从文本中提取JSON（支持markdown代码块）
  String _extractJson(String text) {
    // 尝试提取 ```json ... ``` 中的内容
    final jsonBlockRegex = RegExp(r'```json\s*\n([\s\S]*?)\n```', multiLine: true);
    final match = jsonBlockRegex.firstMatch(text);

    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }

    // 尝试提取 ``` ... ``` 中的内容
    final codeBlockRegex = RegExp(r'```\s*\n([\s\S]*?)\n```', multiLine: true);
    final match2 = codeBlockRegex.firstMatch(text);

    if (match2 != null) {
      final content = match2.group(1)?.trim() ?? '';
      // 检查是否是JSON格式
      if (content.startsWith('{') && content.endsWith('}')) {
        return content;
      }
    }

    // 如果没有代码块，尝试直接提取 { ... } 中的内容
    final jsonRegex = RegExp(r'\{[\s\S]*\}');
    final match3 = jsonRegex.firstMatch(text);
    if (match3 != null) {
      return match3.group(0) ?? '';
    }

    return '';
  }

  /// 解析Trip模型
  Trip _parseTrip(Map<String, dynamic> tripPlan, {int? tripId}) {
    final basicInfo = tripPlan['basicInfo'] as Map<String, dynamic>;

    return Trip(
      id: tripId,
      destination: basicInfo['destination'] as String,
      startDate: basicInfo['startDate'] as String,
      endDate: basicInfo['endDate'] as String,
      budget: (basicInfo['budget'] as num).toDouble(),
      status: 'planned',
      description: basicInfo['description'] as String?,
    );
  }

  /// 解析Attraction列表
  List<Attraction> _parseAttractions(Map<String, dynamic> tripPlan, {required int tripId}) {
    final attractionsList = tripPlan['attractions'] as List<dynamic>? ?? [];
    final attractions = <Attraction>[];

    for (final item in attractionsList) {
      final attr = item as Map<String, dynamic>;
      attractions.add(Attraction(
        tripId: tripId,
        name: attr['name'] as String,
        location: attr['address'] as String, // JSON用的是address，模型用的是location
        category: attr['category'] as String,
        description: attr['description'] as String?,
        price: attr['ticketPrice'] != null ? (attr['ticketPrice'] as num).toDouble() : null,
        notes: attr['notes'] as String?,
        visited: false,
      ));
    }

    return attractions;
  }

  /// 解析Itinerary列表
  List<Itinerary> _parseItineraries(
    Map<String, dynamic> tripPlan, {
    required int tripId,
    required List<Attraction> attractions,
  }) {
    final itinerariesList = tripPlan['itineraries'] as List<dynamic>? ?? [];
    final itineraries = <Itinerary>[];

    // 创建景点名称到索引的映射（用于关联）
    final attractionNameMap = <String, int>{};
    for (int i = 0; i < attractions.length; i++) {
      attractionNameMap[attractions[i].name] = i;
    }

    for (final dayData in itinerariesList) {
      final day = dayData as Map<String, dynamic>;
      final dayNumber = day['dayNumber'] as int;
      final activities = day['activities'] as List<dynamic>? ?? [];

      for (final actData in activities) {
        final activity = actData as Map<String, dynamic>;
        final attractionName = activity['attractionName'] as String?;

        // 尝试找到对应的景点索引
        int? attractionIndex;
        if (attractionName != null && attractionNameMap.containsKey(attractionName)) {
          attractionIndex = attractionNameMap[attractionName];
        }

        final startTime = activity['startTime'] as String;
        final endTime = activity['endTime'] as String?;
        final timeStr = endTime != null ? '$startTime-$endTime' : startTime;

        itineraries.add(Itinerary(
          tripId: tripId,
          day: dayNumber,
          time: timeStr,
          activity: activity['activity'] as String,
          location: activity['location'] as String,
          description: activity['notes'] as String?,
          attractionId: attractionIndex, // 暂时保存索引，稍后会替换为真实ID
          completed: false,
        ));
      }
    }

    return itineraries;
  }

  /// 解析Expense列表
  List<Expense> _parseExpenses(Map<String, dynamic> tripPlan, {required int tripId}) {
    final expensesList = tripPlan['expenses'] as List<dynamic>? ?? [];
    final expenses = <Expense>[];

    for (final item in expensesList) {
      final exp = item as Map<String, dynamic>;
      expenses.add(Expense(
        tripId: tripId,
        category: exp['category'] as String,
        amount: (exp['amount'] as num).toDouble(),
        date: exp['date'] as String,
        description: exp['description'] as String?,
        currency: 'CNY',
      ));
    }

    return expenses;
  }

  /// 更新行程的景点关联ID
  ///
  /// 在保存景点后，需要用真实的景点ID替换临时的索引
  static List<Itinerary> updateAttractionIds(
    List<Itinerary> itineraries,
    List<int> attractionIds,
  ) {
    return itineraries.map((itinerary) {
      if (itinerary.attractionId != null && itinerary.attractionId! < attractionIds.length) {
        return itinerary.copyWith(
          attractionId: attractionIds[itinerary.attractionId!],
        );
      }
      return itinerary;
    }).toList();
  }
}

/// 解析结果
class ParseResult {
  final bool success;
  final String? error;
  final Trip? trip;
  final List<Attraction>? attractions;
  final List<Itinerary>? itineraries;
  final List<Expense>? expenses;

  ParseResult._({
    required this.success,
    this.error,
    this.trip,
    this.attractions,
    this.itineraries,
    this.expenses,
  });

  /// 成功的解析结果
  factory ParseResult.success({
    required Trip trip,
    required List<Attraction> attractions,
    required List<Itinerary> itineraries,
    required List<Expense> expenses,
  }) {
    return ParseResult._(
      success: true,
      trip: trip,
      attractions: attractions,
      itineraries: itineraries,
      expenses: expenses,
    );
  }

  /// 失败的解析结果
  factory ParseResult.error(String message) {
    return ParseResult._(
      success: false,
      error: message,
    );
  }

  /// 获取摘要信息
  String getSummary() {
    if (!success) return '解析失败：$error';

    final tripName = trip?.destination ?? '未知';
    final days = _calculateDays(trip?.startDate ?? '', trip?.endDate ?? '');
    final attractionCount = attractions?.length ?? 0;
    final itineraryCount = itineraries?.length ?? 0;
    final totalExpense = expenses?.fold(0.0, (sum, e) => sum + e.amount) ?? 0.0;

    return '''
📍 目的地：$tripName
📅 天数：$days天
🏞️ 景点：$attractionCount个
📋 行程：$itineraryCount项
💰 预算：¥${trip?.budget.toStringAsFixed(0)}
💸 已规划：¥${totalExpense.toStringAsFixed(0)}
''';
  }

  int _calculateDays(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 0;
    }
  }
}
