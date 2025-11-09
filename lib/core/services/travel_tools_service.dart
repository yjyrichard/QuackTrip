import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../secrets/api_keys.dart';

/// 旅游工具服务 - 集成第三方API
/// 包含：天气查询、地图搜索、翻译等功能
class TravelToolsService {
  // ========== 和风天气 ==========
  static const String qweatherKey = ApiKeys.qweather;

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
      final locationUrl = 'https://geoapi.qweather.com/v2/city/lookup'
          '?location=${Uri.encodeComponent(city)}'
          '&key=$qweatherKey';

      print('🔍 正在查询城市: $city');
      print('🌐 请求URL: $locationUrl');

      final locRes = await http.get(Uri.parse(locationUrl));
      final locData = jsonDecode(locRes.body);

      print('📍 城市查询响应: ${locRes.statusCode}');
      print('📄 响应内容: ${locRes.body}');

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
      final weatherUrl = 'https://devapi.qweather.com/v7/weather/now'
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
      final forecastUrl = 'https://devapi.qweather.com/v7/weather/3d'
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
        final locationUrl = 'https://geoapi.qweather.com/v2/city/lookup'
            '?location=${Uri.encodeComponent(city)}'
            '&key=$qweatherKey';

        final locRes = await http.get(Uri.parse(locationUrl));
        final locData = jsonDecode(locRes.body);

        if (locData['code'] != '200' || locData['location'] == null) continue;

        final locationId = locData['location'][0]['id'];
        final locationName = locData['location'][0]['name'];

        // 获取天气
        final weatherUrl = 'https://devapi.qweather.com/v7/weather/now'
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
      final locationUrl = 'https://geoapi.qweather.com/v2/city/lookup'
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
      final airUrl = 'https://devapi.qweather.com/v7/air/now'
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
}
