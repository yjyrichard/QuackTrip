import 'package:flutter/material.dart';
import '../../../core/services/travel_tools_service.dart';

/// 工具测试页面 - 用于测试旅游工具API
class ToolsTestPage extends StatefulWidget {
  const ToolsTestPage({super.key});

  @override
  State<ToolsTestPage> createState() => _ToolsTestPageState();
}

class _ToolsTestPageState extends State<ToolsTestPage> {
  final TravelToolsService _toolsService = TravelToolsService();
  final TextEditingController _cityController = TextEditingController(text: '广州');
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  /// 查询天气
  Future<void> _queryWeather() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入城市名称')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '正在查询中...';
    });

    try {
      final result = await _toolsService.getWeather(_cityController.text.trim());
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = '查询失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 查询空气质量
  Future<void> _queryAirQuality() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入城市名称')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '正在查询中...';
    });

    try {
      final result = await _toolsService.getAirQuality(_cityController.text.trim());
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = '查询失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 对比多城市天气
  Future<void> _compareWeather() async {
    setState(() {
      _isLoading = true;
      _result = '正在查询中...';
    });

    try {
      final cities = ['北京', '上海', '广州', '深圳'];
      final result = await _toolsService.compareWeather(cities);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = '查询失败：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取当前时间
  void _getCurrentTime() {
    setState(() {
      _result = _toolsService.getCurrentTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('旅游工具测试'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Text(
              '🦆 去哪鸭工具箱',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '测试和风天气API和其他旅游工具',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 城市输入框
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: '城市名称',
                hintText: '例如：广州、北京、上海',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _cityController.clear(),
                ),
              ),
              onSubmitted: (_) => _queryWeather(),
            ),
            const SizedBox(height: 16),

            // 工具按钮组
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _queryWeather,
                  icon: const Icon(Icons.wb_sunny),
                  label: const Text('查询天气'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _queryAirQuality,
                  icon: const Icon(Icons.air),
                  label: const Text('空气质量'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _compareWeather,
                  icon: const Icon(Icons.compare),
                  label: const Text('多城市对比'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.tertiaryContainer,
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _getCurrentTime,
                  icon: const Icon(Icons.access_time),
                  label: const Text('当前时间'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 结果显示区域
            Card(
              elevation: 2,
              child: Container(
                constraints: const BoxConstraints(minHeight: 200),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.article, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '查询结果',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_result.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '请选择一个工具进行测试',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SelectableText(
                        _result,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 说明文字
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '使用说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 查询天气：获取指定城市的实时天气和3天预报\n'
                    '• 空气质量：查询城市空气质量指数(AQI)\n'
                    '• 多城市对比：对比北京、上海、广州、深圳天气\n'
                    '• 当前时间：获取本地时间信息',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
