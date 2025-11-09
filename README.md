<div align="center">
  <img src="assets/QuacktripLogo.png" alt="QuackTrip Logo" width="100" />
  <h1>去哪鸭 QuackTrip 🦆</h1>

基于Flutter的智能旅游规划AI助手

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)](https://flutter.dev)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yjyrichard/QuackTrip/pulls)

[English](#english) | [简体中文](#简体中文)

</div>

---

## 简体中文

### 📖 项目简介

**去哪鸭 QuackTrip** 是一个基于Flutter开发的智能旅游规划助手，集成了AI对话、旅行管理、景点收藏、花费追踪等功能。通过AI助手帮助用户规划旅行路线、查询天气、管理行程，让旅行更加轻松愉快！

这是一个**开源项目**，欢迎所有开发者参与贡献和学习。

### ✨ 主要功能

- 🤖 **AI旅游助手** - 5个专业AI助手（旅游规划师、美食顾问、文化讲解员等）
- 🗺️ **旅行管理** - 完整的旅行计划CRUD（创建、查看、编辑、删除）
- 🏞️ **景点收藏** - 景点分类管理，标记已访问状态
- 💰 **花费追踪** - 记录旅行花费，自动统计预算使用情况
- 📋 **行程规划** - 按天排列的行程表，时间地点详细记录
- 🌤️ **天气查询** - 集成和风天气API，查询实时天气和3天预报
- 💨 **空气质量** - 查询城市AQI、PM2.5等空气质量指标
- 🎨 **小黄鸭主题** - 可爱的黄色主题，明暗模式自适应
- 📱 **跨平台** - 支持Android、iOS、Windows、macOS等

### 🛠️ 技术栈

- **框架**: Flutter 3.8+
- **语言**: Dart
- **数据库**: SQLite（旅游数据） + Hive（聊天记录）
- **状态管理**: Provider
- **UI设计**: Material Design 3
- **动画**: flutter_animate
- **第三方API**:
  - 和风天气 API
  - 高德地图 API（待集成）
  - 百度翻译 API（待集成）

### 🚀 快速开始

#### 1. 克隆项目

```bash
git clone https://github.com/yjyrichard/QuackTrip.git
cd QuackTrip
```

#### 2. 安装依赖

```bash
flutter pub get
```

#### 3. 配置API Keys ⚠️

**重要：本项目使用第三方API，需要自行申请API Key**

1. 复制示例文件：
   ```bash
   cp lib/secrets/api_keys.dart.example lib/secrets/api_keys.dart
   ```

2. 编辑 `lib/secrets/api_keys.dart`，填入你的API Keys：

```dart
class ApiKeys {
  /// 和风天气 API Key
  /// 申请地址：https://dev.qweather.com/
  static const String qweather = 'YOUR_QWEATHER_KEY';

  /// 高德地图 API Key
  /// 申请地址：https://lbs.amap.com/
  static const String amap = 'YOUR_AMAP_KEY';

  /// 百度翻译 API Key
  /// 申请地址：https://fanyi-api.baidu.com/
  static const String baiduTranslateAppId = 'YOUR_APPID';
  static const String baiduTranslateKey = 'YOUR_KEY';
}
```

**API申请指南**：

| API | 免费额度 | 申请地址 | 用途 |
|-----|----------|----------|------|
| 和风天气 | 1000次/天 | https://dev.qweather.com/ | 天气查询、空气质量 |
| 高德地图 | 30万次/天 | https://lbs.amap.com/ | 地点搜索、路线规划 |
| 百度翻译 | 5万字符/月 | https://fanyi-api.baidu.com/ | 多语言翻译 |

**注意**：
- `api_keys.dart` 已在 `.gitignore` 中忽略，不会被提交到Git
- 请勿将你的API Key泄露到公开仓库

#### 4. 运行项目

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

#### 5. 构建APK/IPA

```bash
# Android APK (Release)
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (需要macOS + Xcode)
flutter build ios --release
```

### 📂 项目结构

```
QuackTrip/
├── lib/
│   ├── core/                    # 核心功能
│   │   ├── models/              # 数据模型（Trip, Attraction, Expense等）
│   │   ├── services/            # 服务层
│   │   │   ├── travel_database_service.dart  # SQLite数据库
│   │   │   ├── auth_service.dart             # 用户认证
│   │   │   └── travel_tools_service.dart     # 旅游工具API
│   │   └── providers/           # 状态管理
│   ├── features/                # 功能模块
│   │   ├── auth/                # 认证模块（登录、注册）
│   │   ├── trips/               # 旅行管理
│   │   ├── attractions/         # 景点管理
│   │   ├── tools/               # 工具测试页面
│   │   └── settings/            # 设置页面
│   ├── secrets/                 # 密钥配置（不提交到Git）
│   │   ├── api_keys.dart        # API Keys（需自己创建）
│   │   └── api_keys.dart.example # API Keys示例
│   └── main.dart                # 应用入口
├── assets/                      # 资源文件
│   └── QuacktripLogo.png        # 应用图标
├── android/                     # Android配置
├── ios/                         # iOS配置
├── .gitignore                   # Git忽略文件
├── pubspec.yaml                 # Flutter依赖配置
└── README.md                    # 本文件
```

### 🎯 核心功能模块

#### 1. 用户认证
- 本地账户注册/登录
- SHA256密码加密
- SharedPreferences持久化

#### 2. 旅行管理
- 创建旅行计划（目的地、日期、预算）
- 旅行状态管理（计划中、进行中、已完成）
- 编辑/删除旅行

#### 3. 景点收藏
- 6种景点分类（风景名胜、博物馆、餐厅等）
- 标记已访问/未访问
- 关联到旅行计划

#### 4. 花费追踪
- 6种花费分类（交通、餐饮、住宿等）
- 自动计算总花费
- 预算使用进度条

#### 5. 行程规划
- 按天排列的行程表
- 时间、地点、活动详细记录

#### 6. AI助手
- 5个旅游主题AI助手
- 支持多模型（OpenAI、Claude、Gemini等）
- 聊天记录持久化

#### 7. 旅游工具
- 🌤️ 天气查询（和风天气API）
- 💨 空气质量查询
- 🕐 本地时间
- 🗺️ 地图搜索（待集成）
- 🌐 翻译功能（待集成）

### 📸 应用截图

> 待添加

### 🤝 贡献指南

欢迎所有形式的贡献！包括但不限于：

- 🐛 提交Bug报告
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复
- 🎨 UI/UX设计优化

**贡献流程**：

1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交Pull Request

### 📄 开源协议

本项目采用 **AGPL-3.0 License** 开源协议。

详见 [LICENSE](LICENSE) 文件。

### 📝 开发日志

- **2025-11-08**: 完成旅行管理模块、景点管理、花费追踪完整CRUD
- **2025-11-07**: 完成品牌升级、底部导航、AI助手预设
- **2025-11-06**: 完成基础设施搭建（SQLite数据库、认证系统、小黄鸭主题）

详见 [当前进度.md](当前进度.md)

### 🙏 致谢

- 感谢 [Kelivo](https://github.com/Chevey339/kelivo) 项目提供的基础架构
- 感谢和风天气提供的免费API
- 感谢所有为Flutter生态做出贡献的开发者

### 📞 联系方式

- **项目地址**: https://github.com/yjyrichard/QuackTrip
- **问题反馈**: [GitHub Issues](https://github.com/yjyrichard/QuackTrip/issues)
- **开发者**: 杨佳宇（学号：23251109209）
- **课程**: 移动应用开发（期末作业）

---

## English

### 📖 Introduction

**QuackTrip** is an intelligent travel planning assistant built with Flutter, featuring AI chat, trip management, attraction bookmarking, expense tracking, and more. With AI assistants, users can plan travel routes, check weather, and manage itineraries effortlessly!

This is an **open-source project**, welcoming all developers to contribute and learn.

### ✨ Key Features

- 🤖 **AI Travel Assistants** - 5 specialized AI assistants (travel planner, food advisor, culture guide, etc.)
- 🗺️ **Trip Management** - Complete CRUD for travel plans
- 🏞️ **Attraction Bookmarks** - Categorized attractions with visit status
- 💰 **Expense Tracking** - Record expenses with automatic budget calculation
- 📋 **Itinerary Planning** - Day-by-day schedules with detailed time and location
- 🌤️ **Weather Query** - Real-time weather and 3-day forecast (QWeather API)
- 💨 **Air Quality** - City AQI, PM2.5 indicators
- 🎨 **Duck Theme** - Cute yellow theme with dark mode support
- 📱 **Cross-platform** - Android, iOS, Windows, macOS support

### 🚀 Quick Start

#### 1. Clone Repository

```bash
git clone https://github.com/yjyrichard/QuackTrip.git
cd QuackTrip
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure API Keys ⚠️

**Important: This project uses third-party APIs. You need to apply for your own API keys.**

1. Copy example file:
   ```bash
   cp lib/secrets/api_keys.dart.example lib/secrets/api_keys.dart
   ```

2. Edit `lib/secrets/api_keys.dart` with your API keys:

```dart
class ApiKeys {
  static const String qweather = 'YOUR_QWEATHER_KEY';
  static const String amap = 'YOUR_AMAP_KEY';
  static const String baiduTranslateAppId = 'YOUR_APPID';
  static const String baiduTranslateKey = 'YOUR_KEY';
}
```

**API Application Guide**:

| API | Free Quota | Apply URL | Purpose |
|-----|------------|-----------|---------|
| QWeather | 1000 req/day | https://dev.qweather.com/ | Weather, Air Quality |
| Amap | 300K req/day | https://lbs.amap.com/ | Location Search, Routing |
| Baidu Translate | 50K chars/month | https://fanyi-api.baidu.com/ | Translation |

**Note**: `api_keys.dart` is ignored in `.gitignore` and won't be committed.

#### 4. Run Project

```bash
flutter run
```

#### 5. Build APK/IPA

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

### 🤝 Contributing

Contributions are welcome! Including:

- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🔧 Code fixes
- 🎨 UI/UX optimizations

### 📄 License

This project is licensed under the **AGPL-3.0 License**. See [LICENSE](LICENSE) file for details.

### 📞 Contact

- **Project URL**: https://github.com/yjyrichard/QuackTrip
- **Issues**: [GitHub Issues](https://github.com/yjyrichard/QuackTrip/issues)
- **Developer**: Yang Jiayu (Student ID: 23251109209)

---

<div align="center">
Made with ❤️ using Flutter 🦆
</div>
