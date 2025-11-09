import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/travel_database_service.dart';
import '../../../icons/lucide_adapter.dart';
import 'trip_detail_page.dart';

/// 旅行列表页面 - 展示所有旅行计划
class TripsListPage extends StatefulWidget {
  const TripsListPage({super.key});

  @override
  State<TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<TripsListPage> with SingleTickerProviderStateMixin {
  final TravelDatabaseService _dbService = TravelDatabaseService.instance;
  List<Trip> _allTrips = [];
  List<Trip> _filteredTrips = [];
  bool _isLoading = true;
  String _selectedStatus = 'all'; // all, planned, ongoing, completed
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final statuses = ['all', 'planned', 'ongoing', 'completed'];
      setState(() {
        _selectedStatus = statuses[_tabController.index];
        _filterTrips();
      });
    }
  }

  /// 加载旅行列表
  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final trips = await _dbService.getAllTrips();
      if (mounted) {
        setState(() {
          _allTrips = trips;
          _filterTrips();
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

  /// 筛选旅行
  void _filterTrips() {
    if (_selectedStatus == 'all') {
      _filteredTrips = _allTrips;
    } else {
      _filteredTrips = _allTrips.where((trip) => trip.status == _selectedStatus).toList();
    }
  }

  /// 显示添加旅行对话框
  Future<void> _showAddTripDialog() async {
    final destinationController = TextEditingController();
    final budgetController = TextEditingController();
    final descController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 3));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('创建新旅行'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 目的地
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: '目的地 *',
                        hintText: '例如：广州、北京、上海',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 开始日期
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('开始日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => startDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // 结束日期
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('结束日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: startDate.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => endDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 预算
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '预算 (元) *',
                        hintText: '3000',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '旅行计划简介...',
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
                  if (destinationController.text.trim().isEmpty ||
                      budgetController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写目的地和预算')),
                    );
                    return;
                  }

                  final newTrip = Trip(
                    destination: destinationController.text.trim(),
                    startDate: startDate.toIso8601String(),
                    endDate: endDate.toIso8601String(),
                    budget: double.parse(budgetController.text.trim()),
                    status: 'planned',
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );

                  Navigator.pop(context);
                  await _createTrip(newTrip);
                },
                child: const Text('创建'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 创建旅行
  Future<void> _createTrip(Trip trip) async {
    try {
      await _dbService.createTrip(trip);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 旅行创建成功！嘎~'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  /// 删除旅行
  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除旅行「${trip.destination}」吗？\n相关的景点、花费和行程也会被删除。'),
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
      await _dbService.deleteTrip(trip.id!);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 旅行已删除'),
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

  /// 显示编辑旅行对话框
  Future<void> _showEditTripDialog(Trip trip) async {
    final destinationController = TextEditingController(text: trip.destination);
    final budgetController = TextEditingController(text: trip.budget.toString());
    final descController = TextEditingController(text: trip.description ?? '');

    DateTime startDate = DateTime.parse(trip.startDate);
    DateTime endDate = DateTime.parse(trip.endDate);
    String selectedStatus = trip.status;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('编辑旅行'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 目的地
                    TextField(
                      controller: destinationController,
                      decoration: const InputDecoration(
                        labelText: '目的地 *',
                        hintText: '例如：广州、北京、上海',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 开始日期
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('开始日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setDialogState(() => startDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // 结束日期
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('结束日期'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(endDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: startDate.add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => endDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 预算
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '预算 (元) *',
                        hintText: '3000',
                        border: OutlineInputBorder(),
                        prefixText: '¥ ',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 状态
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: '状态 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'planned', child: Text('计划中')),
                        DropdownMenuItem(value: 'ongoing', child: Text('进行中')),
                        DropdownMenuItem(value: 'completed', child: Text('已完成')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 描述
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '旅行计划简介...',
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
                  if (destinationController.text.trim().isEmpty ||
                      budgetController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写目的地和预算')),
                    );
                    return;
                  }

                  final updatedTrip = Trip(
                    id: trip.id,
                    destination: destinationController.text.trim(),
                    startDate: startDate.toIso8601String(),
                    endDate: endDate.toIso8601String(),
                    budget: double.parse(budgetController.text.trim()),
                    status: selectedStatus,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );

                  Navigator.pop(context);
                  await _updateTrip(updatedTrip);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 更新旅行
  Future<void> _updateTrip(Trip trip) async {
    try {
      await _dbService.updateTrip(trip);
      await _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 旅行更新成功！嘎~'),
            backgroundColor: Colors.green,
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

  /// 获取状态标签
  Widget _buildStatusChip(String status) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'planned':
        icon = Icons.schedule;
        color = Colors.blue;
        label = '计划中';
        break;
      case 'ongoing':
        icon = Icons.flight_takeoff;
        color = Colors.green;
        label = '进行中';
        break;
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.grey;
        label = '已完成';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 计算旅行天数
  int _calculateDays(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的旅行'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.6),
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '计划中'),
            Tab(text: '进行中'),
            Tab(text: '已完成'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTrips.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildTripsList(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'trips_list_fab',
        onPressed: _showAddTripDialog,
        icon: const Icon(Icons.add),
        label: const Text('新建旅行'),
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
            Lucide.Calendar,
            size: 100,
            color: colorScheme.primary.withOpacity(0.3),
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            _selectedStatus == 'all' ? '还没有旅行计划' : '该状态下没有旅行',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建你的第一个旅行吧！嘎~ 🦆',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  /// 旅行列表
  Widget _buildTripsList() {
    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTrips.length,
        itemBuilder: (context, index) {
          final trip = _filteredTrips[index];
          return _buildTripCard(trip, index);
        },
      ),
    );
  }

  /// 旅行卡片
  Widget _buildTripCard(Trip trip, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _calculateDays(trip.startDate, trip.endDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TripDetailPage(trip: trip),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：状态 + 操作按钮
              Row(
                children: [
                  _buildStatusChip(trip.status),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditTripDialog(trip),
                    tooltip: '编辑',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTrip(trip),
                    tooltip: '删除',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 目的地
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.destination,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              // 描述
              if (trip.description != null && trip.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  trip.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 底部信息
              Row(
                children: [
                  // 日期
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: '$days天',
                      sublabel: '${DateFormat('MM/dd').format(DateTime.parse(trip.startDate))} - ${DateFormat('MM/dd').format(DateTime.parse(trip.endDate))}',
                      color: colorScheme.primary,
                    ),
                  ),

                  // 预算
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.account_balance_wallet,
                      label: '¥${trip.budget.toStringAsFixed(0)}',
                      sublabel: '预算',
                      color: Colors.green,
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

  /// 信息项组件
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
