import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../secrets/api_keys.dart';

/// 旅游工具服务 - 集成第三方API
/// 包含：天气查询、地图搜索、翻译等功能
class TravelToolsService {
  // ========== 和风天气 ==========
  static const String qweatherKey = ApiKeys.qweather;
  // 自定义域名用于所有API查询
  static const String qweatherDomain = ApiKeys.qweatherCustomDomain;

  /// 获取城市天气信息
  /// [city] 城市名称，例如：广州、北京
  /// 返回格式化的天气信息字符串
  Future<String> getWeather(String city) async {
    try {
      // 检查API key是否配置
      if (qweatherKey.isEmpty || qweatherKey == 'YOUR_QWEATHER_KEY_HERE') {
        return '❌ 天气API Key未配置\n请在 lib/secrets/api_keys.dart 中配置和风天气的API Key\n申请地址：https://dev.qweather.com/';
      }

      // 1. 先通过城市名获取Location ID
      final locationUrl = '$qweatherDomain/geo/v2/city/lookup'
          '?location=${Uri.encodeComponent(city)}'
          '&key=$qweatherKey';

      print('🔍 正在查询城市: $city');
      print('🌐 城市查询URL: $locationUrl');

      final locRes = await http.get(Uri.parse(locationUrl));

      print('📍 城市查询响应码: ${locRes.statusCode}');
      print('📄 响应体长度: ${locRes.body.length}');
      print('📄 响应内容: ${locRes.body}');

      if (locRes.body.isEmpty) {
        return '❌ 城市查询API返回空响应';
      }

      final locData = jsonDecode(locRes.body);

      if (locData['code'] == '401') {
        return '❌ API Key无效或已过期\n错误代码：${locData['code']}\n请检查和风天气API Key是否正确\n申请地址：https://dev.qweather.com/';
      }

      if (locData['code'] == '402') {
        return '❌ API Key已达到访问限制\n免费版每天限制1000次请求\n请稍后再试或升级套餐';
      }

      if (locData['code'] != '200' || locData['location'] == null || (locData['location'] as List).isEmpty) {
        return '❌ 未找到城市「$city」\n错误代码：${locData['code']}\n请检查城市名称是否正确\n或尝试使用中文全称，如"广州"、"北京"';
      }

      final location = locData['location'][0];
      final locationId = location['id'];
      final locationName = location['name'];
      final adm1 = location['adm1']; // 省份
      final adm2 = location['adm2']; // 地级市

      print('✅ 找到城市: $locationName ($adm2, $adm1), ID: $locationId');

      // 2. 获取实时天气
      final weatherUrl = '$qweatherDomain/v7/weather/now'
          '?location=$locationId'
          '&key=$qweatherKey';

      print('🌤️ 正在获取天气...');
      final weatherRes = await http.get(Uri.parse(weatherUrl));
      final weatherData = jsonDecode(weatherRes.body);

      print('🌡️ 天气查询响应: ${weatherRes.statusCode}');
      print('📄 响应内容: ${weatherRes.body}');

      if (weatherData['code'] == '401') {
        return '❌ API Key无效或已过期\n请检查和风天气API Key';
      }

      if (weatherData['code'] != '200') {
        return '❌ 获取天气失败\n错误代码：${weatherData['code']}\n原因：${weatherData['message'] ?? '未知错误'}';
      }

      final now = weatherData['now'];
      final updateTime = weatherData['updateTime'];

      // 3. 获取未来3天天气预报
      final forecastUrl = '$qweatherDomain/v7/weather/3d'
          '?location=$locationId'
          '&key=$qweatherKey';

      final forecastRes = await http.get(Uri.parse(forecastUrl));
      final forecastData = jsonDecode(forecastRes.body);

      // 4. 格式化输出
      final result = StringBuffer();
      result.writeln('📍 $locationName（$adm2，$adm1）');
      result.writeln('🕐 更新时间：${_formatDateTime(updateTime)}');
      result.writeln('');
      result.writeln('【当前天气】');
      result.writeln('🌡️ 温度：${now['temp']}°C');
      result.writeln('🌤️ 天气：${now['text']}');
      result.writeln('🤔 体感：${now['feelsLike']}°C');
      result.writeln('💨 风向：${now['windDir']} ${now['windScale']}级 (${now['windSpeed']}km/h)');
      result.writeln('💧 湿度：${now['humidity']}%');
      result.writeln('👁️ 能见度：${now['vis']}km');
      result.writeln('🌊 气压：${now['pressure']}hPa');

      // 5. 添加未来天气预报
      if (forecastData['code'] == '200' && forecastData['daily'] != null) {
        result.writeln('');
        result.writeln('【未来3天预报】');
        final daily = forecastData['daily'] as List;
        for (int i = 0; i < daily.length && i < 3; i++) {
          final day = daily[i];
          final date = _formatDate(day['fxDate']);
          result.writeln('$date：${day['textDay']} ${day['tempMin']}~${day['tempMax']}°C');
        }
      }

      result.writeln('');
      result.writeln('💡 建议：${_getWeatherAdvice(now['text'], int.parse(now['temp']))}');

      print('✅ 天气查询成功');
      return result.toString();
    } catch (e, stackTrace) {
      print('❌ 天气查询异常: $e');
      print('📚 堆栈跟踪: $stackTrace');
      return '❌ 获取天气失败：$e\n\n可能原因：\n1. 网络连接问题\n2. API Key配置错误\n3. 服务器暂时不可用\n\n请检查：\n• 网络连接是否正常\n• API Key是否正确配置在 lib/secrets/api_keys.dart\n• 尝试稍后重试';
    }
  }

  /// 获取多城市天气对比
  Future<String> compareWeather(List<String> cities) async {
    if (cities.isEmpty) return '请提供至少一个城市名称';
    if (cities.length > 5) return '最多支持对比5个城市';

    final results = <String, Map<String, dynamic>>{};

    for (final city in cities) {
      try {
        // 获取城市ID
        final locationUrl = '$qweatherDomain/geo/v2/city/lookup'
            '?location=${Uri.encodeComponent(city)}'
            '&key=$qweatherKey';

        final locRes = await http.get(Uri.parse(locationUrl));
        final locData = jsonDecode(locRes.body);

        if (locData['code'] != '200' || locData['location'] == null) continue;

        final locationId = locData['location'][0]['id'];
        final locationName = locData['location'][0]['name'];

        // 获取天气
        final weatherUrl = '$qweatherDomain/v7/weather/now'
            '?location=$locationId'
            '&key=$qweatherKey';

        final weatherRes = await http.get(Uri.parse(weatherUrl));
        final weatherData = jsonDecode(weatherRes.body);

        if (weatherData['code'] == '200') {
          results[locationName] = weatherData['now'];
        }
      } catch (e) {
        continue;
      }
    }

    if (results.isEmpty) return '未能获取任何城市的天气信息';

    final result = StringBuffer('🌍 多城市天气对比\n\n');

    for (final entry in results.entries) {
      final cityName = entry.key;
      final weather = entry.value;
      result.writeln('📍 $cityName：${weather['text']} ${weather['temp']}°C（体感${weather['feelsLike']}°C）');
    }

    return result.toString();
  }

  /// 获取空气质量
  Future<String> getAirQuality(String city) async {
    try {
      // 1. 获取城市ID
      final locationUrl = '$qweatherDomain/geo/v2/city/lookup'
          '?location=${Uri.encodeComponent(city)}'
          '&key=$qweatherKey';

      final locRes = await http.get(Uri.parse(locationUrl));
      final locData = jsonDecode(locRes.body);

      if (locData['code'] != '200' || locData['location'] == null) {
        return '❌ 未找到城市「$city」';
      }

      final locationId = locData['location'][0]['id'];
      final locationName = locData['location'][0]['name'];

      // 2. 获取空气质量
      final airUrl = '$qweatherDomain/v7/air/now'
          '?location=$locationId'
          '&key=$qweatherKey';

      final airRes = await http.get(Uri.parse(airUrl));
      final airData = jsonDecode(airRes.body);

      if (airData['code'] != '200') {
        return '❌ 获取空气质量失败';
      }

      final now = airData['now'];

      final result = StringBuffer();
      result.writeln('📍 $locationName 空气质量');
      result.writeln('');
      result.writeln('🌫️ AQI：${now['aqi']} (${now['category']})');
      result.writeln('💨 PM2.5：${now['pm2p5']}');
      result.writeln('💨 PM10：${now['pm10']}');
      result.writeln('⚠️ NO2：${now['no2']}');
      result.writeln('⚠️ SO2：${now['so2']}');
      result.writeln('⚠️ CO：${now['co']}');
      result.writeln('⚠️ O3：${now['o3']}');

      return result.toString();
    } catch (e) {
      return '❌ 获取空气质量失败：$e';
    }
  }

  // ========== 高德地图 ==========
  static const String amapKey = ApiKeys.amap;

  /// 搜索地点（POI搜索）
  /// [keyword] 搜索关键词，如：广州塔、星巴克
  /// [city] 城市名称，如：广州（可选，不填则全国搜索）
  /// [type] POI类型，如：景点、餐饮、酒店等（可选）
  Future<String> searchPlace(String keyword, {String? city, String? type}) async {
    try {
      // 检查API key是否配置
      if (amapKey.isEmpty || amapKey == 'YOUR_AMAP_KEY') {
        return '❌ 高德地图API Key未配置\n请在 lib/secrets/api_keys.dart 中配置高德地图的API Key\n申请地址：https://lbs.amap.com/';
      }

      // 构建请求URL
      String url = 'https://restapi.amap.com/v3/place/text'
          '?keywords=${Uri.encodeComponent(keyword)}'
          '&key=$amapKey'
          '&output=json';

      if (city != null && city.isNotEmpty) {
        url += '&city=${Uri.encodeComponent(city)}';
      }

      if (type != null && type.isNotEmpty) {
        url += '&types=$type';
      }

      debugPrint('🔍 搜索地点: $keyword (城市: ${city ?? "全国"})');
      debugPrint('🌐 请求URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return '❌ 请求失败，状态码：${response.statusCode}';
      }

      final data = jsonDecode(response.body);

      if (data['status'] == '0') {
        return '❌ 搜索失败：${data['info']}\nAPI Key可能无效或已过期';
      }

      final pois = data['pois'] as List?;
      if (pois == null || pois.isEmpty) {
        return '📍 未找到「$keyword」相关的地点信息\n建议：\n• 尝试使用更具体的关键词\n• 指定城市名称\n• 检查关键词拼写';
      }

      // 格式化输出前5个结果
      final result = StringBuffer();
      result.writeln('🔍 搜索结果：$keyword');
      if (city != null) result.writeln('📍 城市：$city');
      result.writeln('');

      final displayCount = pois.length > 5 ? 5 : pois.length;
      for (int i = 0; i < displayCount; i++) {
        final poi = pois[i];
        final name = poi['name'];
        final address = poi['address'] ?? poi['pname'] ?? '';
        final type = poi['type'] ?? '';
        final location = poi['location'] ?? '';
        final tel = poi['tel'] ?? '';

        result.writeln('【${i + 1}】$name');
        if (type.isNotEmpty) result.writeln('   类型：$type');
        if (address.isNotEmpty) result.writeln('   地址：$address');
        if (tel.isNotEmpty) result.writeln('   电话：$tel');
        if (location.isNotEmpty) result.writeln('   坐标：$location');
        result.writeln('');
      }

      if (pois.length > displayCount) {
        result.writeln('... 还有 ${pois.length - displayCount} 个结果未显示');
      }

      result.writeln('💡 提示：点击地点可查看详细信息或导航');

      return result.toString();
    } catch (e) {
      debugPrint('❌ 搜索地点失败: $e');
      return '❌ 搜索地点失败：$e';
    }
  }

  // ========== 货币转换 ==========

  /// 货币汇率转换（待开发）
  ///
  /// [amount] 金额
  /// [from] 源货币（如：USD, CNY, EUR）
  /// [to] 目标货币
  ///
  /// TODO: 集成汇率查询API
  /// 推荐API: https://api.exchangerate-api.com/v4/latest/
  Future<String> convertCurrency(double amount, String from, String to) async {
    return '''
⚠️ 货币转换功能待开发

计划功能：
• 实时汇率查询
• 支持主流货币（USD, CNY, EUR, JPY等）
• 离线缓存汇率数据
• 汇率走势图表

推荐API：
• ExchangeRate-API: https://www.exchangerate-api.com/
• Fixer.io: https://fixer.io/

嘎~ 这个功能还在规划中！
''';
  }

  // ========== 本地工具 ==========

  /// 获取当前时间
  String getCurrentTime({String? timezone}) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final weekday = _getWeekdayName(now.weekday);

    return '📅 当前时间：$dateStr $timeStr $weekday';
  }

  // ========== 辅助方法 ==========

  /// 格式化日期时间
  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.month}-${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  /// 格式化日期
  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      final weekday = _getWeekdayName(dt.weekday);
      return '${dt.month}月${dt.day}日 $weekday';
    } catch (e) {
      return dateString;
    }
  }

  /// 获取星期名称
  String _getWeekdayName(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  /// 根据天气给出建议
  String _getWeatherAdvice(String weather, int temp) {
    if (weather.contains('雨')) {
      return '记得带伞哦！嘎~ ☔';
    } else if (weather.contains('雪')) {
      return '路滑注意安全，穿暖和点！嘎~ ⛄';
    } else if (temp > 30) {
      return '天气炎热，注意防晒和补水！嘎~ ☀️';
    } else if (temp < 10) {
      return '天气较冷，多穿点衣服！嘎~ 🧥';
    } else if (weather.contains('晴')) {
      return '天气不错，适合出游！嘎~ 🌞';
    } else if (weather.contains('阴')) {
      return '天气阴沉，可能会下雨，建议带伞！嘎~ ☁️';
    } else {
      return '祝你旅途愉快！嘎~ 🦆';
    }
  }

  /// 计算MD5（用于签名）
  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  // ========== 高德地图路径规划 ==========

  /// 路线规划 - 综合出行方案
  /// [origin] 起点名称或地址，如"广州塔"
  /// [destination] 终点名称或地址，如"广州南站"
  /// [city] 城市名称（可选），如"广州"
  /// [mode] 出行方式：driving(驾车)、transit(公交/地铁)、walking(步行)、bicycling(骑行)，默认为transit
  Future<String> getRoutePlan({
    required String origin,
    required String destination,
    String? city,
    String mode = 'transit',
  }) async {
    try {
      // 检查API key是否配置
      if (amapKey.isEmpty || amapKey == 'YOUR_AMAP_KEY_HERE') {
        return '❌ 高德地图API Key未配置\n请在 lib/secrets/api_keys.dart 中配置高德地图的API Key\n申请地址：https://lbs.amap.com/';
      }

      debugPrint('🗺️ 路线规划: $origin -> $destination (方式: $mode)');

      // 1. 获取起点和终点的坐标
      final originCoords = await _geocodePlace(origin, city);
      if (originCoords == null) {
        return '❌ 未找到起点：$origin';
      }

      final destCoords = await _geocodePlace(destination, city);
      if (destCoords == null) {
        return '❌ 未找到终点：$destination';
      }

      debugPrint('📍 起点坐标: $originCoords');
      debugPrint('📍 终点坐标: $destCoords');

      // 2. 根据出行方式调用不同的路径规划API
      switch (mode.toLowerCase()) {
        case 'driving':
          return await _getDrivingRoute(originCoords, destCoords, origin, destination);
        case 'walking':
          return await _getWalkingRoute(originCoords, destCoords, origin, destination);
        case 'bicycling':
          return await _getBicyclingRoute(originCoords, destCoords, origin, destination);
        case 'transit':
        default:
          return await _getTransitRoute(originCoords, destCoords, origin, destination, city ?? '广州');
      }
    } catch (e) {
      debugPrint('❌ 路线规划失败: $e');
      return '❌ 路线规划失败：$e';
    }
  }

  /// 地点地理编码 - 将地点名称转换为坐标
  Future<String?> _geocodePlace(String place, String? city) async {
    try {
      final cityParam = city != null ? '&city=${Uri.encodeComponent(city)}' : '';
      final url = 'https://restapi.amap.com/v3/geocode/geo'
          '?address=${Uri.encodeComponent(place)}'
          '$cityParam'
          '&key=$amapKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] == '1' && data['geocodes'] != null && data['geocodes'].isNotEmpty) {
        return data['geocodes'][0]['location'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ 地理编码失败: $e');
      return null;
    }
  }

  /// 公交/地铁路线规划
  Future<String> _getTransitRoute(String origin, String dest, String originName, String destName, String city) async {
    try {
      final url = 'https://restapi.amap.com/v3/direction/transit/integrated'
          '?origin=$origin'
          '&destination=$dest'
          '&city=${Uri.encodeComponent(city)}'
          '&output=json'
          '&key=$amapKey';

      debugPrint('🌐 公交路线URL: $url');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return '❌ API请求失败，状态码：${response.statusCode}';
      }

      final data = jsonDecode(response.body);
      if (data['status'] != '1' || data['route'] == null) {
        return '❌ 未找到公交路线';
      }

      final route = data['route'];
      final transits = route['transits'] as List?;
      if (transits == null || transits.isEmpty) {
        return '❌ 未找到公交路线';
      }

      // 格式化输出前3个路线方案
      final buffer = StringBuffer();
      buffer.writeln('🗺️ 从 $originName 到 $destName 的公交/地铁路线：\n');

      int count = 0;
      for (final transit in transits) {
        if (count >= 3) break; // 只显示前3个方案
        count++;

        final duration = (transit['duration'] as int) ~/ 60; // 转换为分钟
        final distance = ((transit['distance'] as int) / 1000).toStringAsFixed(1); // 转换为公里
        final cost = transit['cost'] ?? 0;

        buffer.writeln('【方案$count】用时约${duration}分钟，距离${distance}公里，票价¥$cost');

        final segments = transit['segments'] as List?;
        if (segments != null) {
          for (int i = 0; i < segments.length; i++) {
            final seg = segments[i];
            final walking = seg['walking'];
            final bus = seg['bus'];

            // 步行段
            if (walking != null && walking['distance'] != null) {
              final walkDist = (walking['distance'] as int);
              if (walkDist > 0) {
                buffer.writeln('  ${i + 1}. 步行 ${walkDist}米');
              }
            }

            // 公交/地铁段
            if (bus != null && bus['buslines'] != null) {
              final buslines = bus['buslines'] as List;
              for (final busline in buslines) {
                final name = busline['name'] ?? '';
                final departure = busline['departure_stop']?['name'] ?? '';
                final arrival = busline['arrival_stop']?['name'] ?? '';
                final viaNum = busline['via_num'] ?? 0;

                if (name.isNotEmpty) {
                  buffer.writeln('  ${i + 1}. 乘坐 $name');
                  buffer.writeln('     从 $departure 上车，经过${viaNum}站，到 $arrival 下车');
                }
              }
            }
          }
        }

        buffer.writeln('');
      }

      buffer.writeln('提示：具体班次时间请以实际为准。嘎~ 🦆');
      return buffer.toString();
    } catch (e) {
      debugPrint('❌ 公交路线规划失败: $e');
      return '❌ 公交路线规划失败：$e';
    }
  }

  /// 驾车路线规划
  Future<String> _getDrivingRoute(String origin, String dest, String originName, String destName) async {
    try {
      final url = 'https://restapi.amap.com/v3/direction/driving'
          '?origin=$origin'
          '&destination=$dest'
          '&output=json'
          '&key=$amapKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return '❌ API请求失败';
      }

      final data = jsonDecode(response.body);
      if (data['status'] != '1' || data['route'] == null) {
        return '❌ 未找到驾车路线';
      }

      final route = data['route'];
      final paths = route['paths'] as List?;
      if (paths == null || paths.isEmpty) {
        return '❌ 未找到驾车路线';
      }

      final path = paths[0];
      final distance = ((path['distance'] as int) / 1000).toStringAsFixed(1);
      final duration = (path['duration'] as int) ~/ 60;
      final tolls = path['tolls'] ?? 0;
      final tollDistance = ((path['toll_distance'] as int?) ?? 0) / 1000;

      final buffer = StringBuffer();
      buffer.writeln('🚗 从 $originName 到 $destName 的驾车路线：\n');
      buffer.writeln('距离：${distance}公里');
      buffer.writeln('预计用时：${duration}分钟');
      if (tolls > 0) {
        buffer.writeln('过路费：¥$tolls（收费路段${tollDistance.toStringAsFixed(1)}公里）');
      }
      buffer.writeln('\n具体导航请使用地图APP。嘎~ 🦆');

      return buffer.toString();
    } catch (e) {
      return '❌ 驾车路线规划失败：$e';
    }
  }

  /// 步行路线规划
  Future<String> _getWalkingRoute(String origin, String dest, String originName, String destName) async {
    try {
      final url = 'https://restapi.amap.com/v3/direction/walking'
          '?origin=$origin'
          '&destination=$dest'
          '&output=json'
          '&key=$amapKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return '❌ API请求失败';
      }

      final data = jsonDecode(response.body);
      if (data['status'] != '1' || data['route'] == null) {
        return '❌ 未找到步行路线';
      }

      final route = data['route'];
      final paths = route['paths'] as List?;
      if (paths == null || paths.isEmpty) {
        return '❌ 未找到步行路线';
      }

      final path = paths[0];
      final distance = ((path['distance'] as int) / 1000).toStringAsFixed(2);
      final duration = (path['duration'] as int) ~/ 60;

      return '🚶 从 $originName 到 $destName 的步行路线：\n'
          '\n距离：${distance}公里'
          '\n预计用时：${duration}分钟'
          '\n\n建议使用地图APP查看详细路线。嘎~ 🦆';
    } catch (e) {
      return '❌ 步行路线规划失败：$e';
    }
  }

  /// 骑行路线规划
  Future<String> _getBicyclingRoute(String origin, String dest, String originName, String destName) async {
    try {
      final url = 'https://restapi.amap.com/v4/direction/bicycling'
          '?origin=$origin'
          '&destination=$dest'
          '&output=json'
          '&key=$amapKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return '❌ API请求失败';
      }

      final data = jsonDecode(response.body);
      if (data['status'] != '1' || data['data'] == null) {
        return '❌ 未找到骑行路线';
      }

      final routeData = data['data'];
      final paths = routeData['paths'] as List?;
      if (paths == null || paths.isEmpty) {
        return '❌ 未找到骑行路线';
      }

      final path = paths[0];
      final distance = ((path['distance'] as int) / 1000).toStringAsFixed(2);
      final duration = (path['duration'] as int) ~/ 60;

      return '🚴 从 $originName 到 $destName 的骑行路线：\n'
          '\n距离：${distance}公里'
          '\n预计用时：${duration}分钟'
          '\n\n建议使用地图APP查看详细路线。嘎~ 🦆';
    } catch (e) {
      return '❌ 骑行路线规划失败：$e';
    }
  }
}
