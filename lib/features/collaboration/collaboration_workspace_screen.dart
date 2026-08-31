import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../jobs/job_service.dart';
import 'job_chat_screen.dart';

class CollaborationWorkspaceScreen extends StatefulWidget {
  final String currentUserId;
  const CollaborationWorkspaceScreen({super.key, required this.currentUserId});

  @override
  State<CollaborationWorkspaceScreen> createState() => _CollaborationWorkspaceScreenState();
}

class _CollaborationWorkspaceScreenState extends State<CollaborationWorkspaceScreen> {
  final _jobService = JobService();
  List<Map<String, dynamic>> _activeProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final jobs = await _jobService.fetchJobs();
    if (!mounted) return;

    final active = jobs.where((job) {
      final creatorId = (job['creator'] is Map) ? job['creator']['_id']?.toString() : job['creator']?.toString();
      final assignedTo = job['assignedTo'];
      final assignedToId = (assignedTo is Map) ? assignedTo['_id']?.toString() : assignedTo?.toString();
      
      final isCreator = creatorId == widget.currentUserId;
      final isAssignee = assignedToId == widget.currentUserId;
      final hasAssignee = assignedToId != null;

      // Include if it's assigned to someone and I'm the creator, OR I'm the assignee
      return hasAssignee && (isCreator || isAssignee);
    }).toList();

    setState(() {
      _activeProjects = active;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_activeProjects.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No project selected',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 6),
                      Text(
                        'Please select or post a project from the Workspace Hub to '
                        'open the Collaboration Workspace.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _activeProjects.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = _activeProjects[index];
                    final title = job['title'] ?? 'Untitled Project';
                    final jobId = job['_id']?.toString() ?? '';
                    

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobChatScreen(
                                jobId: jobId,
                                jobTitle: title,
                                currentUserId: widget.currentUserId,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text('Creator: ${(job['creator'] is Map) ? job['creator']['name'] ?? 'Unknown' : 'Unknown'}', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text('Assignee: ${(job['assignedTo'] is Map) ? job['assignedTo']['name'] ?? 'Unknown' : 'Unknown'}', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
