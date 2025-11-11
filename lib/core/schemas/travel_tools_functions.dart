/// 旅游工具Function Calling定义
///
/// 为LLM提供可调用的工具列表（Function Calling）
class TravelToolsFunctions {
  /// 获取所有可用的工具定义
  static List<Map<String, dynamic>> getAllTools() {
    return [
      getWeatherTool(),
      getAirQualityTool(),
      compareWeatherTool(),
      getCurrentTimeTool(),
      searchPlaceTool(),
      getRoutePlanTool(),
    ];
  }

  /// 天气查询工具
  static Map<String, dynamic> getWeatherTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'get_weather',
        'description': '获取指定城市的实时天气信息和未来3天天气预报。包含温度、天气状况、风向风速、湿度、体感温度等详细信息。',
        'parameters': {
          'type': 'object',
          'properties': {
            'city': {
              'type': 'string',
              'description': '城市名称，如：广州、北京、上海、深圳等。可以是中文或拼音。',
            },
          },
          'required': ['city'],
        },
      },
    };
  }

  /// 空气质量查询工具
  static Map<String, dynamic> getAirQualityTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'get_air_quality',
        'description': '获取指定城市的空气质量信息，包含AQI指数、PM2.5、PM10、SO2、NO2、CO、O3等数据。',
        'parameters': {
          'type': 'object',
          'properties': {
            'city': {
              'type': 'string',
              'description': '城市名称，如：广州、北京、上海等',
            },
          },
          'required': ['city'],
        },
      },
    };
  }

  /// 多城市天气对比工具
  static Map<String, dynamic> compareWeatherTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'compare_weather',
        'description': '对比多个城市的天气情况，最多支持5个城市。用于帮助用户选择旅行目的地或了解多地天气差异。',
        'parameters': {
          'type': 'object',
          'properties': {
            'cities': {
              'type': 'array',
              'description': '要对比的城市列表，如：["北京", "上海", "广州"]',
              'items': {
                'type': 'string',
              },
              'minItems': 2,
              'maxItems': 5,
            },
          },
          'required': ['cities'],
        },
      },
    };
  }

  /// 获取当前时间工具
  static Map<String, dynamic> getCurrentTimeTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'get_current_time',
        'description': '获取当前日期和时间，包含年月日、时分秒、星期几等信息。',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      },
    };
  }

  /// 地点搜索工具（高德地图POI搜索）
  static Map<String, dynamic> searchPlaceTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'search_place',
        'description': '搜索地点信息（景点、餐厅、酒店等），支持按城市筛选。返回地点名称、地址、电话、坐标等信息。',
        'parameters': {
          'type': 'object',
          'properties': {
            'keyword': {
              'type': 'string',
              'description': '搜索关键词，如：广州塔、星巴克、希尔顿酒店',
            },
            'city': {
              'type': 'string',
              'description': '城市名称（可选），如：广州、北京。不填则全国搜索。',
            },
          },
          'required': ['keyword'],
        },
      },
    };
  }

  /// 路线规划工具（高德地图路径规划）
  static Map<String, dynamic> getRoutePlanTool() {
    return {
      'type': 'function',
      'function': {
        'name': 'get_route_plan',
        'description': '规划从起点到终点的出行路线，支持公交/地铁、驾车、步行、骑行等多种出行方式。返回详细的路线方案，包括乘坐的公交/地铁线路、站点、用时、距离等信息。',
        'parameters': {
          'type': 'object',
          'properties': {
            'origin': {
              'type': 'string',
              'description': '起点名称或地址，如：广州塔、天河客运站、广州东站',
            },
            'destination': {
              'type': 'string',
              'description': '终点名称或地址，如：广州南站、白云机场、北京路步行街',
            },
            'city': {
              'type': 'string',
              'description': '城市名称（可选），如：广州、北京。有助于提高地点识别准确度。',
            },
            'mode': {
              'type': 'string',
              'description': '出行方式：transit（公交/地铁，默认）、driving（驾车）、walking（步行）、bicycling（骑行）',
              'enum': ['transit', 'driving', 'walking', 'bicycling'],
            },
          },
          'required': ['origin', 'destination'],
        },
      },
    };
  }

  /// 为AI助手生成工具使用说明（添加到System Prompt）
  static String getToolsInstructionForPrompt() {
    return '''

【可用工具】

你可以调用以下工具来帮助用户：

1. **get_weather(city)** - 查询城市天气
   - 获取实时天气和未来3天预报
   - 例如：用户问"今天广州多少度？"，你应该调用 get_weather(city="广州")

2. **get_air_quality(city)** - 查询空气质量
   - 获取AQI和污染物数据
   - 例如：用户问"北京空气质量怎么样？"

3. **compare_weather(cities)** - 对比多城市天气
   - 最多对比5个城市
   - 例如：用户问"广州和深圳哪个温度高？"

4. **get_current_time()** - 获取当前时间
   - 获取当前日期时间和星期

5. **search_place(keyword, city?)** - 搜索地点（景点、餐厅、酒店等）
   - 支持按城市筛选
   - 例如：用户问"广州有哪些好玩的地方？"，调用 search_place(keyword="景点", city="广州")
   - 例如：用户问"附近的星巴克在哪？"，调用 search_place(keyword="星巴克")

6. **get_route_plan(origin, destination, city?, mode?)** - 路线规划
   - 规划从起点到终点的出行路线
   - 支持公交/地铁（transit）、驾车（driving）、步行（walking）、骑行（bicycling）
   - 例如：用户问"我想从广州塔到广州南站"，调用 get_route_plan(origin="广州塔", destination="广州南站", city="广州", mode="transit")
   - 例如：用户问"从天河客运站怎么去白云机场？"，调用 get_route_plan(origin="天河客运站", destination="白云机场", city="广州")
   - 返回详细的乘车方案，包括地铁/公交线路、站点、用时、票价等

【使用规则】

- 当用户询问天气、温度、气温、下雨等问题时，主动调用 get_weather
- 当用户询问空气质量、PM2.5、AQI等问题时，调用 get_air_quality
- 当用户对比多个城市时，调用 compare_weather
- 当用户询问景点、餐厅、酒店、地点等问题时，调用 search_place
- 当用户询问路线、怎么去、如何到达某地等问题时，主动调用 get_route_plan
- 工具返回的结果会自动添加到你的上下文中，你只需要基于结果友好地回答用户
- 如果工具调用失败，友好地告诉用户原因并提供替代建议

记住：**主动使用工具**来提供准确的实时信息，而不是告诉用户"我无法获取实时数据"！对于路线规划，要给出具体的乘车方案（如"乘坐地铁3号线到XXX站，转X号线..."），而不是简单说"可以坐地铁"！
''';
  }
}
