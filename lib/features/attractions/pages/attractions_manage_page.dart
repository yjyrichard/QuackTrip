import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/attraction.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/travel_database_service.dart';

/// 景点管理页面 - 完整展示 SQLite CRUD 操作
class AttractionsManagePage extends StatefulWidget {
  const AttractionsManagePage({super.key});

  @override
  State<AttractionsManagePage> createState() => _AttractionsManagePageState();
}

class _AttractionsManagePageState extends State<AttractionsManagePage> {
  final TravelDatabaseService _dbService = TravelDatabaseService.instance;
  List<Attraction> _attractions = [];
  Trip? _demoTrip;
  bool _isLoading = true;

  // 景点分类
  final List<Map<String, dynamic>> _categories = [
    {'value': 'scenic', 'label': '风景名胜', 'icon': Icons.landscape},
    {'value': 'museum', 'label': '博物馆', 'icon': Icons.museum},
    {'value': 'restaurant', 'label': '餐厅美食', 'icon': Icons.restaurant},
    {'value': 'shopping', 'label': '购物中心', 'icon': Icons.shopping_bag},
    {'value': 'entertainment', 'label': '娱乐休闲', 'icon': Icons.sports_esports},
    {'value': 'other', 'label': '其他', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// 初始化页面数据
  Future<void> _initializePage() async {
    setState(() => _isLoading = true);

    try {
      // 1. 检查是否有演示用的旅行计划
      final trips = await _dbService.getAllTrips();
      if (trips.isEmpty) {
        // 创建一个演示用的旅行计划
        _demoTrip = await _dbService.createTrip(Trip(
          destination: '广州市',
          startDate: DateTime.now().toIso8601String(),
          endDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          budget: 3000,
          status: 'planned',
          description: 'QuackTrip 演示旅行 - 用于展示景点CRUD功能',
        ));
      } else {
        _demoTrip = trips.first;
      }

      // 2. 加载景点列表
      await _loadAttractions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 加载景点列表 (READ 操作)
  Future<void> _loadAttractions() async {
    if (_demoTrip == null) return;

    final attractions = await _dbService.getAttractionsByTripId(_demoTrip!.id!);
    if (mounted) {
      setState(() => _attractions = attractions);
    }
  }

  /// 显示添加/编辑景点对话框
  Future<void> _showAttractionDialog({Attraction? attraction}) async {
    final isEditing = attraction != null;

    // 表单控制器
    final nameController = TextEditingController(text: attraction?.name ?? '');
    final locationController = TextEditingController(text: attraction?.location ?? '');
    final descController = TextEditingController(text: attraction?.description ?? '');
    final priceController = TextEditingController(text: attraction?.price?.toString() ?? '');
    final notesController = TextEditingController(text: attraction?.notes ?? '');

    String selectedCategory = attraction?.category ?? 'scenic';
    double currentRating = attraction?.rating ?? 3.0;
    bool isVisited = attraction?.visited ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑景点' : '添加景点'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 景点名称
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '景点名称 *',
                        hintText: '例如：广州塔',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 位置
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: '位置 *',
                        hintText: '例如：海珠区阅江西路222号',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分类选择
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '景点分类 *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['value'],
                          child: Row(
                            children: [
                              Icon(cat['icon'], size: 20),
                              const SizedBox(width: 8),
                              Text(cat['label']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '景点描述',
                        hintText: '介绍一下这个景点...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 门票价格
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '门票价格 (元)',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 评分
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('评分: ${currentRating.toStringAsFixed(1)} ⭐'),
                        Slider(
                          value: currentRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: currentRating.toStringAsFixed(1),
                          onChanged: (value) {
                            setDialogState(() => currentRating = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 是否已访问
                    CheckboxListTile(
                      title: const Text('已访问'),
                      value: isVisited,
                      onChanged: (value) {
                        setDialogState(() => isVisited = value ?? false);
                      },
                    ),
                    const SizedBox(height: 8),

                    // 备注
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '其他信息...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  // 验证必填项
                  if (nameController.text.trim().isEmpty ||
                      locationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写景点名称和位置')),
                    );
                    return;
                  }

                  final newAttraction = Attraction(
                    id: attraction?.id,
                    tripId: _demoTrip!.id!,
                    name: nameController.text.trim(),
                    location: locationController.text.trim(),
                    category: selectedCategory,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    price: priceController.text.trim().isEmpty
                        ? null
                        : double.tryParse(priceController.text.trim()),
                    rating: currentRating,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    visited: isVisited,
                  );

                  Navigator.pop(context);

                  if (isEditing) {
                    await _updateAttraction(newAttraction);
                  } else {
                    await _createAttraction(newAttraction);
                  }
                },
                child: Text(isEditing ? '保存' : '添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 创建景点 (CREATE 操作)
  Future<void> _createAttraction(Attraction attraction) async {
    try {
      await _dbService.createAttraction(attraction);
      await _loadAttractions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 景点添加成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  /// 更新景点 (UPDATE 操作)
  Future<void> _updateAttraction(Attraction attraction) async {
    try {
      await _dbService.updateAttraction(attraction);
      await _loadAttractions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 景点更新成功！'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  /// 删除景点 (DELETE 操作)
  Future<void> _deleteAttraction(Attraction attraction) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除景点「${attraction.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _dbService.deleteAttraction(attraction.id!);
      await _loadAttractions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 景点已删除'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => _categories.last,
    );
    return cat['icon'];
  }

  /// 获取分类标签
  String _getCategoryLabel(String category) {
    final cat = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => _categories.last,
    );
    return cat['label'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('景点管理 - CRUD演示'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttractions,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attractions.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildAttractionsList(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'attractions_manage_fab',
        onPressed: () => _showAttractionDialog(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('添加景点'),
        backgroundColor: colorScheme.primary,
      ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attractions,
            size: 100,
            color: colorScheme.primary.withOpacity(0.3),
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            '还没有景点哦',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加第一个景点吧！嘎~ 🦆',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  /// 景点列表
  Widget _buildAttractionsList() {
    return RefreshIndicator(
      onRefresh: _loadAttractions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attractions.length,
        itemBuilder: (context, index) {
          final attraction = _attractions[index];
          return _buildAttractionCard(attraction, index);
        },
      ),
    );
  }

  /// 景点卡片
  Widget _buildAttractionCard(Attraction attraction, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAttractionDialog(attraction: attraction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：标题 + 操作按钮
              Row(
                children: [
                  // 分类图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(attraction.category),
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 景点名称
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attraction.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryLabel(attraction.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 编辑按钮
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: colorScheme.primary,
                        onPressed: () => _showAttractionDialog(attraction: attraction),
                        tooltip: '编辑',
                      ),
                      // 删除按钮
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => _deleteAttraction(attraction),
                        tooltip: '删除',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // 位置
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      attraction.location,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              // 描述
              if (attraction.description != null && attraction.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  attraction.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // 底部信息栏
              Row(
                children: [
                  // 评分
                  if (attraction.rating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            attraction.rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // 价格
                  if (attraction.price != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '¥${attraction.price!.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // 已访问标签
                  if (attraction.visited)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '已访问',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
  }
}
