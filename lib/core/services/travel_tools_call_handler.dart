import 'package:flutter/foundation.dart';
import './travel_tools_service.dart';

/// 旅游工具调用处理器
///
/// 处理LLM的Function Calling请求，执行对应的工具方法
class TravelToolsCallHandler {
  final TravelToolsService _toolsService = TravelToolsService();

  /// 处理工具调用
  ///
  /// [toolName] 工具名称（如：get_weather）
  /// [args] 工具参数
  /// 返回工具执行结果
  Future<String> handleToolCall(String toolName, Map<String, dynamic> args) async {
    debugPrint('🔧 调用工具: $toolName，参数: $args');

    try {
      switch (toolName) {
        case 'get_weather':
          return await _handleGetWeather(args);
        case 'get_air_quality':
          return await _handleGetAirQuality(args);
        case 'compare_weather':
          return await _handleCompareWeather(args);
        case 'get_current_time':
          return _handleGetCurrentTime(args);
        case 'search_place':
          return await _handleSearchPlace(args);
        case 'get_route_plan':
          return await _handleRoutePlan(args);
        default:
          return '❌ 未知的工具: $toolName';
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 工具调用失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return '❌ 工具调用失败：$e';
    }
  }

  /// 处理天气查询
  Future<String> _handleGetWeather(Map<String, dynamic> args) async {
    final city = args['city'] as String?;
    if (city == null || city.isEmpty) {
      return '❌ 缺少参数: city';
    }

    debugPrint('🌤️ 查询天气: $city');
    final result = await _toolsService.getWeather(city);
    debugPrint('✅ 天气查询成功');
    return result;
  }

  /// 处理空气质量查询
  Future<String> _handleGetAirQuality(Map<String, dynamic> args) async {
    final city = args['city'] as String?;
    if (city == null || city.isEmpty) {
      return '❌ 缺少参数: city';
    }

    debugPrint('🌫️ 查询空气质量: $city');
    final result = await _toolsService.getAirQuality(city);
    debugPrint('✅ 空气质量查询成功');
    return result;
  }

  /// 处理多城市天气对比
  Future<String> _handleCompareWeather(Map<String, dynamic> args) async {
    final citiesRaw = args['cities'];
    if (citiesRaw == null) {
      return '❌ 缺少参数: cities';
    }

    List<String> cities;
    if (citiesRaw is List) {
      cities = citiesRaw.map((e) => e.toString()).toList();
    } else {
      return '❌ cities 参数格式错误，应该是数组';
    }

    if (cities.isEmpty) {
      return '❌ cities 不能为空';
    }

    if (cities.length > 5) {
      return '❌ 最多支持对比5个城市';
    }

    debugPrint('🌍 对比城市天气: ${cities.join(", ")}');
    final result = await _toolsService.compareWeather(cities);
    debugPrint('✅ 天气对比成功');
    return result;
  }

  /// 处理获取当前时间
  String _handleGetCurrentTime(Map<String, dynamic> args) {
    debugPrint('🕐 获取当前时间');
    final result = _toolsService.getCurrentTime();
    debugPrint('✅ 时间获取成功');
    return result;
  }

  /// 处理地点搜索
  Future<String> _handleSearchPlace(Map<String, dynamic> args) async {
    final keyword = args['keyword'] as String?;
    if (keyword == null || keyword.isEmpty) {
      return '❌ 缺少参数: keyword';
    }

    final city = args['city'] as String?;

    debugPrint('🔍 搜索地点: $keyword (城市: ${city ?? "全国"})');
    final result = await _toolsService.searchPlace(keyword, city: city);
    debugPrint('✅ 地点搜索成功');
    return result;
  }

  /// 处理路线规划
  Future<String> _handleRoutePlan(Map<String, dynamic> args) async {
    final origin = args['origin'] as String?;
    final destination = args['destination'] as String?;

    if (origin == null || origin.isEmpty) {
      return '❌ 缺少参数: origin（起点）';
    }

    if (destination == null || destination.isEmpty) {
      return '❌ 缺少参数: destination（终点）';
    }

    final city = args['city'] as String?;
    final mode = (args['mode'] as String?) ?? 'transit';

    debugPrint('🗺️ 路线规划: $origin -> $destination (方式: $mode, 城市: ${city ?? "未指定"})');
    final result = await _toolsService.getRoutePlan(
      origin: origin,
      destination: destination,
      city: city,
      mode: mode,
    );
    debugPrint('✅ 路线规划成功');
    return result;
  }
}
