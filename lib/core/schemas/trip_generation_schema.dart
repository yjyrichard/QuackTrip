/// 旅行计划生成 JSON Schema
///
/// 此文件定义了AI助手生成旅行计划时应该遵循的JSON格式
///
/// 使用场景：
/// 1. 用户向AI助手提出旅行需求（如："帮我规划一个3天的广州旅游"）
/// 2. AI助手根据此Schema生成结构化的JSON响应
/// 3. TripJsonParser解析JSON并保存到SQLite数据库

class TripGenerationSchema {
  /// JSON Schema 示例（AI助手参考）
  static const String schemaExample = '''
{
  "tripPlan": {
    "basicInfo": {
      "name": "广州3日游",
      "destination": "广州",
      "startDate": "2025-12-01",
      "endDate": "2025-12-03",
      "budget": 3000.0,
      "description": "探索羊城的历史文化和美食"
    },
    "attractions": [
      {
        "name": "广州塔",
        "address": "广州市海珠区阅江西路222号",
        "category": "scenic",
        "ticketPrice": 150.0,
        "estimatedDuration": 180,
        "description": "广州新地标，可登塔俯瞰珠江夜景",
        "notes": "建议傍晚前往，拍摄日落和夜景"
      },
      {
        "name": "沙面",
        "address": "广州市荔湾区沙面大街",
        "category": "scenic",
        "ticketPrice": 0,
        "estimatedDuration": 120,
        "description": "欧陆风情的历史街区",
        "notes": "免费开放，适合拍照"
      },
      {
        "name": "陶陶居",
        "address": "广州市荔湾区第十甫路20号",
        "category": "restaurant",
        "ticketPrice": 80.0,
        "estimatedDuration": 90,
        "description": "百年老字号茶楼，体验正宗早茶",
        "notes": "建议早上8-10点前往，人气很旺需要排队"
      }
    ],
    "itineraries": [
      {
        "dayNumber": 1,
        "date": "2025-12-01",
        "activities": [
          {
            "attractionName": "陶陶居",
            "startTime": "09:00",
            "endTime": "10:30",
            "activity": "品尝正宗广式早茶",
            "location": "广州市荔湾区第十甫路20号",
            "notes": "虾饺、叉烧包、凤爪必点"
          },
          {
            "attractionName": "沙面",
            "startTime": "11:00",
            "endTime": "13:00",
            "activity": "漫步欧陆风情街区",
            "location": "广州市荔湾区沙面大街",
            "notes": "拍照打卡，欣赏建筑"
          },
          {
            "attractionName": "广州塔",
            "startTime": "18:00",
            "endTime": "21:00",
            "activity": "登塔观光，欣赏珠江夜景",
            "location": "广州市海珠区阅江西路222号",
            "notes": "观景+晚餐，提前订票"
          }
        ]
      },
      {
        "dayNumber": 2,
        "date": "2025-12-02",
        "activities": [
          {
            "attractionName": "北京路步行街",
            "startTime": "10:00",
            "endTime": "12:00",
            "activity": "购物和品尝小吃",
            "location": "广州市越秀区北京路",
            "notes": "广州著名商业街"
          }
        ]
      }
    ],
    "expenses": [
      {
        "category": "transportation",
        "amount": 500.0,
        "description": "往返机票/高铁 + 市内交通",
        "date": "2025-12-01"
      },
      {
        "category": "accommodation",
        "amount": 600.0,
        "description": "酒店住宿（2晚）",
        "date": "2025-12-01"
      },
      {
        "category": "food",
        "amount": 600.0,
        "description": "餐饮费用（早茶、正餐、小吃）",
        "date": "2025-12-01"
      },
      {
        "category": "tickets",
        "amount": 300.0,
        "description": "景点门票",
        "date": "2025-12-01"
      },
      {
        "category": "shopping",
        "amount": 500.0,
        "description": "购物和特产",
        "date": "2025-12-02"
      },
      {
        "category": "other",
        "amount": 500.0,
        "description": "预留备用金",
        "date": "2025-12-01"
      }
    ]
  }
}
''';

  /// System Prompt for AI Assistant（添加到旅游规划师助手的提示词）
  static const String systemPrompt = '''
当用户请求规划旅行时，你需要生成一个符合以下JSON格式的旅行计划：

**响应格式要求：**

1. **必须**用 JSON 代码块包裹，使用 ```json 和 ``` 标记
2. JSON结构必须严格遵循以下Schema
3. 所有金额使用浮点数（如 150.0）
4. 所有日期使用 YYYY-MM-DD 格式
5. 所有时间使用 HH:MM 格式（24小时制）
6. category字段只能是以下值之一：
   - 景点类别: scenic, museum, restaurant, shopping, entertainment, other
   - 花费类别: transportation, accommodation, food, tickets, shopping, other

**JSON Schema:**

```json
{
  "tripPlan": {
    "basicInfo": {
      "name": "旅行名称",
      "destination": "目的地城市",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "budget": 总预算金额（浮点数）,
      "description": "旅行描述"
    },
    "attractions": [
      {
        "name": "景点名称",
        "address": "详细地址",
        "category": "景点类别",
        "ticketPrice": 门票价格,
        "estimatedDuration": 预计游览时长（分钟）,
        "description": "景点介绍",
        "notes": "游览建议"
      }
    ],
    "itineraries": [
      {
        "dayNumber": 天数（1、2、3...）,
        "date": "YYYY-MM-DD",
        "activities": [
          {
            "attractionName": "景点名称（对应attractions中的name）",
            "startTime": "HH:MM",
            "endTime": "HH:MM",
            "activity": "活动描述",
            "location": "地点",
            "notes": "备注"
          }
        ]
      }
    ],
    "expenses": [
      {
        "category": "花费类别",
        "amount": 金额,
        "description": "描述",
        "date": "YYYY-MM-DD"
      }
    ]
  }
}
```

**重要提示：**
1. 确保 itineraries 中的 attractionName 与 attractions 中的 name 匹配
2. 确保 expenses 中所有金额相加 ≤ budget
3. 确保 date 在 startDate 和 endDate 之间
4. 生成的内容要符合实际情况，景点地址、价格要准确
5. 每天安排3-5个活动，时间要合理（考虑交通、用餐、休息）
6. 在JSON前后添加一些人性化的文字说明，但JSON本身必须完整有效

**示例响应：**

好的！我为你规划了一个精彩的3天广州之旅，嘎~ 🦆

```json
{
  "tripPlan": {
    ...完整的JSON数据...
  }
}
```

这个行程包含了广州最经典的景点和美食体验，预算控制在3000元以内。建议提前预订酒店和热门景点的门票哦！嘎~ ✈️
''';

  /// 字段说明文档
  static const Map<String, String> fieldDescriptions = {
    // basicInfo
    'name': '旅行计划名称，简洁明了，如"广州3日游"',
    'destination': '主要目的地城市名称',
    'startDate': '开始日期，格式：YYYY-MM-DD',
    'endDate': '结束日期，格式：YYYY-MM-DD',
    'budget': '总预算（人民币），浮点数',
    'description': '旅行简介，1-2句话',

    // attractions
    'attractions': '景点列表，包含此次旅行涉及的所有景点',
    'attractions.name': '景点名称',
    'attractions.address': '景点详细地址',
    'attractions.category': '景点类别：scenic（风景）/museum（博物馆）/restaurant（餐厅）/shopping（购物）/entertainment（娱乐）/other（其他）',
    'attractions.ticketPrice': '门票价格（免费填0）',
    'attractions.estimatedDuration': '预计游览时长（分钟）',
    'attractions.description': '景点介绍',
    'attractions.notes': '游览建议和注意事项',

    // itineraries
    'itineraries': '每日行程安排',
    'itineraries.dayNumber': '第几天（1、2、3...）',
    'itineraries.date': '日期，格式：YYYY-MM-DD',
    'itineraries.activities': '当天的活动列表',
    'itineraries.activities.attractionName': '关联的景点名称（必须在attractions中存在）',
    'itineraries.activities.startTime': '开始时间，格式：HH:MM',
    'itineraries.activities.endTime': '结束时间，格式：HH:MM',
    'itineraries.activities.activity': '活动描述',
    'itineraries.activities.location': '活动地点',
    'itineraries.activities.notes': '备注信息',

    // expenses
    'expenses': '花费记录',
    'expenses.category': '花费类别：transportation（交通）/accommodation（住宿）/food（餐饮）/tickets（门票）/shopping（购物）/other（其他）',
    'expenses.amount': '金额（人民币）',
    'expenses.description': '花费描述',
    'expenses.date': '日期，格式：YYYY-MM-DD',
  };

  /// 验证JSON数据的完整性
  static List<String> validate(Map<String, dynamic> json) {
    final errors = <String>[];

    // 检查顶层结构
    if (!json.containsKey('tripPlan')) {
      errors.add('缺少 tripPlan 字段');
      return errors;
    }

    final tripPlan = json['tripPlan'] as Map<String, dynamic>;

    // 检查 basicInfo
    if (!tripPlan.containsKey('basicInfo')) {
      errors.add('缺少 basicInfo 字段');
    } else {
      final basicInfo = tripPlan['basicInfo'] as Map<String, dynamic>;
      if (!basicInfo.containsKey('name')) errors.add('basicInfo.name 是必填项');
      if (!basicInfo.containsKey('destination')) errors.add('basicInfo.destination 是必填项');
      if (!basicInfo.containsKey('startDate')) errors.add('basicInfo.startDate 是必填项');
      if (!basicInfo.containsKey('endDate')) errors.add('basicInfo.endDate 是必填项');
    }

    // 检查 attractions
    if (!tripPlan.containsKey('attractions') || (tripPlan['attractions'] as List).isEmpty) {
      errors.add('至少需要1个景点');
    }

    // 检查 itineraries
    if (!tripPlan.containsKey('itineraries') || (tripPlan['itineraries'] as List).isEmpty) {
      errors.add('至少需要1天的行程安排');
    }

    return errors;
  }
}
