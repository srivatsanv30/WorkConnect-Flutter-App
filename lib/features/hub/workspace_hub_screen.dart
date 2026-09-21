import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../shared/stat_card.dart';
import '../jobs/job_service.dart';
import '../jobs/job_detail_screen.dart';

class WorkspaceHubScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final VoidCallback onPostProject;

  const WorkspaceHubScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.onPostProject,
  });

  @override
  State<WorkspaceHubScreen> createState() => _WorkspaceHubScreenState();
}

class _WorkspaceHubScreenState extends State<WorkspaceHubScreen> {
  final List<String> _skillFilters = [
    'All', 'React', 'Flutter', 'Node.js', 'Python', 'Firebase'
  ];
  String _selectedFilter = 'All';

  final _jobService = JobService();
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final jobs = await _jobService.fetchJobs();
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All') return _jobs;
    return _jobs.where((job) {
      final skills = (job['skillsRequired'] as List?) ?? [];
      return skills.any((s) => s.toString().toLowerCase() == _selectedFilter.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hub',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Welcome back, ${widget.userName}. AI has found new '
                        'opportunities matching your profile.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onPostProject,
              child: const Text('Post New Project'),
            ),
            SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                StatCard(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppTheme.primary,
                  iconBg: AppTheme.primary.withValues(alpha: 0.15),
                  value: '0',
                  label: 'REPUTATION XP',
                  sublabel: 'New Creator',
                ),
                StatCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF00A9E0),
                  iconBg: const Color(0xFF00A9E0).withValues(alpha: 0.15),
                  value: '${_jobs.length}',
                  label: 'ACTIVE PROJECTS',
                  sublabel: '${_jobs.length} active workspaces',
                ),
                StatCard(
                  icon: Icons.check_circle_outline,
                  iconColor: Color(0xFF1DBF73),
                  iconBg: const Color(0xFF1DBF73).withValues(alpha: 0.15),
                  value: '0',
                  label: 'TASKS COMPLETED',
                  sublabel: 'Milestones completed',
                ),
                StatCard(
                  icon: Icons.people_outline,
                  iconColor: const Color(0xFFE0A800),
                  iconBg: const Color(0xFFE0A800).withValues(alpha: 0.15),
                  value: '${_jobs.where((job) => job['assignedTo'] != null).map((job) => (job['assignedTo'] is Map) ? job['assignedTo']['_id']?.toString() : job['assignedTo']?.toString()).where((id) => id != null).toSet().length}',
                  label: 'COLLABORATORS',
                  sublabel: 'Active partners',
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.hub_outlined, size: 18, color: AppTheme.primary),
                SizedBox(width: 6),
                Text('Smart Match Recommendations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _skillFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _skillFilters[index];
                  final selected = filter == _selectedFilter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    backgroundColor: Theme.of(context).cardColor,
                    side: const BorderSide(color: AppTheme.cardBorder),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredJobs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No projects match this skill filter.\nPost a new job or clear filters!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
              )
            else
              ..._filteredJobs.map((job) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => JobDetailScreen(job: job, currentUserId: widget.userId)),
);
        },
        child: _JobCard(job: job),
      ),
    )),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final title = job['title'] ?? 'Untitled Project';
    final description = job['description'] ?? '';
    final skills = ((job['skillsRequired'] as List?) ?? []).cast<String>();
    final priority = job['priority'] ?? 'Medium';
    final creatorName = (job['creator'] is Map) ? job['creator']['name'] ?? 'Unknown' : 'Unknown';
    final createdAtRaw = job['createdAt'];
    
    String createdDateText = '';
    if (createdAtRaw != null) {
      final date = DateTime.tryParse(createdAtRaw.toString());
      if (date != null) {
        createdDateText = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
            ),
            SizedBox(height: 10),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .map((s) => Chip(
                          label: Text(s, style: TextStyle(fontSize: 11)),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                SizedBox(width: 4),
                Text('Posted by $creatorName', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                if (createdDateText.isNotEmpty) ...[
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  SizedBox(width: 4),
                  Text('Created: $createdDateText', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}