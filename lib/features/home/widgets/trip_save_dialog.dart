import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/trip_json_parser.dart';
import '../../../core/services/trip_generator_service.dart';
import '../../trips/pages/trip_detail_page.dart';

/// 旅行计划预览和保存确认对话框
///
/// 显示AI生成的旅行计划摘要，让用户确认是否保存到数据库
class TripSaveDialog extends StatefulWidget {
  final TripGeneratorService generatorService;
  final VoidCallback? onSaved;

  const TripSaveDialog({
    super.key,
    required this.generatorService,
    this.onSaved,
  });

  @override
  State<TripSaveDialog> createState() => _TripSaveDialogState();

  /// 显示对话框
  static Future<bool?> show(
    BuildContext context,
    TripGeneratorService generatorService, {
    VoidCallback? onSaved,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TripSaveDialog(
        generatorService: generatorService,
        onSaved: onSaved,
      ),
    );
  }
}

class _TripSaveDialogState extends State<TripSaveDialog> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.generatorService.currentResult;

    if (result == null || !result.success) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('解析失败'),
          ],
        ),
        content: Text(result?.error ?? '未知错误'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    final trip = result.trip!;
    final summary = result.getSummary();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.map, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('保存旅行计划')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 摘要信息卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🗺️ ${trip.destination}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 16),

            // 详细信息
            _buildInfoRow(
              context,
              Icons.calendar_today,
              '日期',
              '${trip.startDate} 至 ${trip.endDate}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.location_on,
              '景点',
              '${result.attractions?.length ?? 0} 个',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.schedule,
              '行程',
              '${result.itineraries?.length ?? 0} 项活动',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.attach_money,
              '预算',
              '¥${trip.budget.toStringAsFixed(0)}',
            ),

            if (trip.description != null && trip.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '📝 描述',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trip.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 16),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '点击"保存"将此计划保存到你的旅行列表中',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () {
            widget.generatorService.clearResult();
            Navigator.of(context).pop(false);
          },
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveTripPlan,
          icon: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? '保存中...' : '保存'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _saveTripPlan() async {
    setState(() => _isSaving = true);

    try {
      final tripId = await widget.generatorService.saveTripPlan();

      if (!mounted) return;

      if (tripId != null) {
        // 保存成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('旅行计划保存成功！嘎~ 🦆'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onSaved?.call();

        Navigator.of(context).pop(true);

        // 延迟一下再跳转，让SnackBar显示出来
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // 创建包含ID的trip对象
        final result = widget.generatorService.currentResult;
        final savedTrip = result?.trip?.copyWith(id: tripId);

        if (savedTrip != null) {
          // 跳转到旅行详情页面
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TripDetailPage(trip: savedTrip),
            ),
          );
        }
      } else {
        // 保存失败
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('保存失败，请重试'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      debugPrint('❌ 保存旅行计划出错: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存出错：$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSaving = false);
    }
  }
}
