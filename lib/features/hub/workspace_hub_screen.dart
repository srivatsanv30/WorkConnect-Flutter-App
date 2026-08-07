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
  final List<String> _skillFilters = const [
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
                      const Text(
                        'Workspace Hub',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back, ${widget.userName}. AI has found new '
                        'opportunities matching your profile.',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onPostProject,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Post New Project'),
            ),
            const SizedBox(height: 20),
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
                  iconBg: const Color(0xFFEDEBFB),
                  value: '0',
                  label: 'REPUTATION XP',
                  sublabel: 'New Creator',
                ),
                StatCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF00A9E0),
                  iconBg: const Color(0xFFE3F6FD),
                  value: '${_jobs.length}',
                  label: 'ACTIVE PROJECTS',
                  sublabel: '${_jobs.length} active workspaces',
                ),
                const StatCard(
                  icon: Icons.check_circle_outline,
                  iconColor: Color(0xFF1DBF73),
                  iconBg: Color(0xFFE4F9EE),
                  value: '0',
                  label: 'TASKS COMPLETED',
                  sublabel: 'Milestones completed',
                ),
                const StatCard(
                  icon: Icons.people_outline,
                  iconColor: Color(0xFFE0A800),
                  iconBg: Color(0xFFFFF6E0),
                  value: '0',
                  label: 'COLLABORATORS',
                  sublabel: 'Active partners',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(Icons.hub_outlined, size: 18, color: AppTheme.primary),
                SizedBox(width: 6),
                Text('Smart Match Recommendations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _skillFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _skillFilters[index];
                  final selected = filter == _selectedFilter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.cardBorder),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
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
                      style: TextStyle(color: Colors.black45),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF3F6FD),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Text('Posted by $creatorName', style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}