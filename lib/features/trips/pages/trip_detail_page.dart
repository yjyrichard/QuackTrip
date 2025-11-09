import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trip.dart';
import '../../../core/models/attraction.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/itinerary.dart';
import '../../../core/services/travel_database_service.dart';

/// 旅行详情页面 - 展示日程、景点、花费
class TripDetailPage extends StatefulWidget {
  final Trip trip;

  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> with SingleTickerProviderStateMixin {
  final TravelDatabaseService _dbService = TravelDatabaseService.instance;
  late TabController _tabController;

  List<Attraction> _attractions = [];
  List<Expense> _expenses = [];
  List<Itinerary> _itineraries = [];
  bool _isLoading = true;
  double _totalExpense = 0;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载所有数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final attractions = await _dbService.getAttractionsByTripId(widget.trip.id!);
      final expenses = await _dbService.getExpensesByTripId(widget.trip.id!);
      final itineraries = await _dbService.getItinerariesByTripId(widget.trip.id!);
      final total = await _dbService.getTotalExpensesByTripId(widget.trip.id!);

      if (mounted) {
        setState(() {
          _attractions = attractions;
          _expenses = expenses;
          _itineraries = itineraries;
          _totalExpense = total;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 计算旅行天数
  int _calculateDays() {
    try {
      final start = DateTime.parse(widget.trip.startDate);
      final end = DateTime.parse(widget.trip.endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (widget.trip.status) {
      case 'planned':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _calculateDays();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部大图+标题
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.trip.destination,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 80,
                    color: colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // 概览信息卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOverviewCard(days, colorScheme),
                  const SizedBox(height: 16),
                  _buildTabBar(),
                ],
              ),
            ),
          ),

          // Tab内容
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildItinerariesTab(),
                      _buildAttractionsTab(),
                      _buildExpensesTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  /// 概览卡片
  Widget _buildOverviewCard(int days, ColorScheme colorScheme) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.trip.status == 'planned'
                    ? '计划中'
                    : widget.trip.status == 'ongoing'
                        ? '进行中'
                        : '已完成',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 描述
            if (widget.trip.description != null && widget.trip.description!.isNotEmpty) ...[
              Text(
                widget.trip.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 统计信息
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today,
                    label: '天数',
                    value: '$days天',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.attractions,
                    label: '景点',
                    value: '${_attractions.length}个',
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.account_balance_wallet,
                    label: '预算',
                    value: '¥${widget.trip.budget.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 已花费
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.paid,
                    label: '已花费',
                    value: '¥${_totalExpense.toStringAsFixed(0)}',
                    color: _totalExpense > widget.trip.budget ? Colors.red : Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.schedule,
                    label: '行程',
                    value: '${_itineraries.length}项',
                    color: Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.receipt,
                    label: '花费记录',
                    value: '${_expenses.length}笔',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),

            // 预算使用进度条
            const SizedBox(height: 16),
            _buildBudgetProgress(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  /// 统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 预算使用进度条
  Widget _buildBudgetProgress() {
    final percentage = widget.trip.budget > 0 ? (_totalExpense / widget.trip.budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = _totalExpense > widget.trip.budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '预算使用情况',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              isOverBudget ? Colors.red : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  /// Tab Bar
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '行程表'),
          Tab(text: '景点'),
          Tab(text: '花费'),
        ],
      ),
    );
  }

  /// 行程表Tab
  Widget _buildItinerariesTab() {
    if (_itineraries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_note,
        title: '还没有行程安排',
        subtitle: '通过AI助手生成旅行计划！嘎~',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itineraries.length,
      itemBuilder: (context, index) {
        final itinerary = _itineraries[index];
        return _buildItineraryCard(itinerary, index);
      },
    );
  }

  /// 景点Tab
  Widget _buildAttractionsTab() {
    if (_attractions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.attractions,
        title: '还没有景点',
        subtitle: '点击景点管理页面添加！',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attractions.length,
      itemBuilder: (context, index) {
        final attraction = _attractions[index];
        return _buildAttractionCard(attraction, index);
      },
    );
  }

  /// 花费Tab
  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: '还没有花费记录',
        subtitle: '开始记录你的旅行花费吧！',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return _buildExpenseCard(expense, index);
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 行程卡片
  Widget _buildItineraryCard(Itinerary itinerary, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            'D${itinerary.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          itinerary.activity,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${itinerary.time} · ${itinerary.location}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          color: Colors.red,
          onPressed: () => _deleteItinerary(itinerary),
          tooltip: '删除',
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }

  /// 景点卡片
  Widget _buildAttractionCard(Attraction attraction, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          attraction.visited ? Icons.check_circle : Icons.location_on,
          color: attraction.visited ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          attraction.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(attraction.location),
        trailing: attraction.price != null
            ? Text(
                '¥${attraction.price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              )
            : null,
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }

  /// 花费卡片
  Widget _buildExpenseCard(Expense expense, int index) {
    final dateStr = DateFormat('MM-dd').format(DateTime.parse(expense.date));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(
            _getCategoryIcon(expense.category),
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${expense.description ?? ''} · $dateStr'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¥${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => _deleteExpense(expense),
              tooltip: '删除',
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }

  /// 获取花费分类图标
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case '交通':
      case 'transport':
        return Icons.directions_car;
      case '餐饮':
      case 'food':
        return Icons.restaurant;
      case '住宿':
      case 'accommodation':
        return Icons.hotel;
      case '门票':
      case 'ticket':
        return Icons.confirmation_number;
      case '购物':
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.payment;
    }
  }

  /// 浮动按钮 - 根据Tab切换功能
  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    String label;
    IconData icon;
    VoidCallback onPressed;

    switch (_currentTabIndex) {
      case 0: // 行程表
        label = '添加行程';
        icon = Icons.add_circle_outline;
        onPressed = _showAddItineraryDialog;
        break;
      case 1: // 景点
        label = '添加景点';
        icon = Icons.add_location;
        onPressed = _showAddAttractionDialog;
        break;
      case 2: // 花费
        label = '添加花费';
        icon = Icons.add_card;
        onPressed = _showAddExpenseDialog;
        break;
      default:
        label = '添加';
        icon = Icons.add;
        onPressed = () {};
    }

    return FloatingActionButton.extended(
      heroTag: 'trip_detail_fab',
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      backgroundColor: colorScheme.primary,
    );
  }

  /// 显示添加行程对话框
  Future<void> _showAddItineraryDialog() async {
    final activityController = TextEditingController();
    final locationController = TextEditingController();
    final timeController = TextEditingController();
    final descController = TextEditingController();
    int selectedDay = 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('添加行程'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 选择天数
                    DropdownButtonFormField<int>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        labelText: '第几天 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: List.generate(_calculateDays(), (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text('第${index + 1}天'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedDay = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 时间
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: '时间 *',
                        hintText: '例如：09:00-12:00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 活动内容
                    TextField(
                      controller: activityController,
                      decoration: const InputDecoration(
                        labelText: '活动内容 *',
                        hintText: '例如：参观广州塔',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 地点
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: '地点 *',
                        hintText: '例如：海珠区艺洲路',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '详细描述或注意事项',
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
                  if (activityController.text.trim().isEmpty ||
                      locationController.text.trim().isEmpty ||
                      timeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写所有必填项')),
                    );
                    return;
                  }

                  final newItinerary = Itinerary(
                    tripId: widget.trip.id!,
                    day: selectedDay,
                    time: timeController.text.trim(),
                    activity: activityController.text.trim(),
                    location: locationController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );

                  Navigator.pop(context);
                  await _createItinerary(newItinerary);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 创建行程
  Future<void> _createItinerary(Itinerary itinerary) async {
    try {
      await _dbService.createItinerary(itinerary);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 行程添加成功！嘎~'),
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

  /// 显示添加景点对话框
  Future<void> _showAddAttractionDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加景点'),
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
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),

                // 地址
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: '地址 *',
                    hintText: '例如：海珠区艺洲路',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 16),

                // 门票价格
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '门票价格 (元)',
                    hintText: '150',
                    border: OutlineInputBorder(),
                    prefixText: '¥ ',
                    prefixIcon: Icon(Icons.attach_money),
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
              if (nameController.text.trim().isEmpty ||
                  locationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写景点名称和地址')),
                );
                return;
              }

              final newAttraction = Attraction(
                tripId: widget.trip.id!,
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                price: priceController.text.trim().isEmpty
                    ? null
                    : double.tryParse(priceController.text.trim()),
                category: 'scenic',
                visited: false,
              );

              Navigator.pop(context);
              await _createAttraction(newAttraction);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 创建景点
  Future<void> _createAttraction(Attraction attraction) async {
    try {
      await _dbService.createAttraction(attraction);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 景点添加成功！嘎~'),
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

  /// 显示添加花费对话框
  Future<void> _showAddExpenseDialog() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = '餐饮';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('添加花费'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 分类选择
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: '分类 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: '交通', child: Text('🚗 交通')),
                        DropdownMenuItem(value: '餐饮', child: Text('🍜 餐饮')),
                        DropdownMenuItem(value: '住宿', child: Text('🏨 住宿')),
                        DropdownMenuItem(value: '门票', child: Text('🎫 门票')),
                        DropdownMenuItem(value: '购物', child: Text('🛍️ 购物')),
                        DropdownMenuItem(value: '其他', child: Text('💰 其他')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 金额
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '金额 (元) *',
                        hintText: '100',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 日期选择
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.parse(widget.trip.startDate),
                          lastDate: DateTime.parse(widget.trip.endDate),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '例如：午餐费用',
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
                  if (amountController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写金额')),
                    );
                    return;
                  }

                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的金额')),
                    );
                    return;
                  }

                  final newExpense = Expense(
                    tripId: widget.trip.id!,
                    category: selectedCategory,
                    amount: amount,
                    date: selectedDate.toIso8601String(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );

                  Navigator.pop(context);
                  await _createExpense(newExpense);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 创建花费
  Future<void> _createExpense(Expense expense) async {
    try {
      await _dbService.createExpense(expense);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 花费记录添加成功！嘎~'),
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

  /// 删除行程
  Future<void> _deleteItinerary(Itinerary itinerary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除行程「${itinerary.activity}」吗？'),
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
      await _dbService.deleteItinerary(itinerary.id!);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 行程已删除'),
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

  /// 删除花费
  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除花费记录「${expense.category} ¥${expense.amount.toStringAsFixed(0)}」吗？'),
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
      await _dbService.deleteExpense(expense.id!);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 花费记录已删除'),
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
}
