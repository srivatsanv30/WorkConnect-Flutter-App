import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'tracking_service.dart';

class ProgressTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const ProgressTrackerScreen({super.key, required this.job});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  static const _statuses = ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'];

  late Map<String, dynamic> _job;
  final _trackingService = TrackingService();
  final _milestoneController = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    super.dispose();
  }

  List<dynamic> get _milestones => (_job['milestones'] as List?) ?? [];

  double get _progress {
    if (_milestones.isEmpty) return 0;
    final done = _milestones.where((m) => m['done'] == true).length;
    return done / _milestones.length;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isBusy = true);
    final result = await _trackingService.updateStatus(_job['_id'], status);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (result.success) {
      setState(() => _job = result.job!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _addMilestone() async {
    final title = _milestoneController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isBusy = true);
    final result = await _trackingService.addMilestone(_job['_id'], title);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (result.success) {
      setState(() {
        _job = result.job!;
        _milestoneController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _toggleMilestone(String milestoneId) async {
    final result = await _trackingService.toggleMilestone(_job['_id'], milestoneId);
    if (!mounted) return;
    if (result.success) {
      setState(() => _job = result.job!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _job['status'] ?? 'Pending';
    final currentIndex = _statuses.indexOf(currentStatus);

    return Scaffold(
      appBar: AppBar(title: Text(_job['title'] ?? 'Progress', overflow: TextOverflow.ellipsis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  final isSelected = status == currentStatus;
                  final isPast = index < currentIndex;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: _isBusy ? null : (_) => _updateStatus(status),
                    selectedColor: AppTheme.primary,
                    backgroundColor: isPast ? const Color(0xFFE4F9EE) : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text(
                  '${(_progress * 100).round()}% complete',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF2F2F7),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            SizedBox(height: 16),
            if (_milestones.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No milestones yet — add one below.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
              )
            else
              ..._milestones.map((m) => Card(
                    child: CheckboxListTile(
                      value: m['done'] == true,
                      onChanged: (_) => _toggleMilestone(m['_id']),
                      title: Text(
                        m['title'] ?? '',
                        style: TextStyle(
                          decoration: m['done'] == true ? TextDecoration.lineThrough : null,
                          color: m['done'] == true ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45) : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      activeColor: AppTheme.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _milestoneController,
                    decoration: const InputDecoration(
                      hintText: 'Add a milestone...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addMilestone(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isBusy ? null : _addMilestone,
                  child: Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}