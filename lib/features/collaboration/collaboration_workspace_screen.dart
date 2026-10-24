import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../jobs/job_service.dart';
import 'job_chat_screen.dart';

class CollaborationWorkspaceScreen extends StatefulWidget {
  final String currentUserId;
  const CollaborationWorkspaceScreen({super.key, required this.currentUserId});

  @override
  State<CollaborationWorkspaceScreen> createState() =>
      _CollaborationWorkspaceScreenState();
}

class _CollaborationWorkspaceScreenState
    extends State<CollaborationWorkspaceScreen> {
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
      final creatorId = (job['creator'] is Map)
          ? job['creator']['_id']?.toString()
          : job['creator']?.toString();
      final assignedTo = job['assignedTo'];
      final assignedToId = (assignedTo is Map)
          ? assignedTo['_id']?.toString()
          : assignedTo?.toString();

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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 6),
                      Text(
                        'Please select or post a project from the Workspace Hub to '
                        'open the Collaboration Workspace.',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.54)),
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

                    final creator = job['creator'];
                    final creatorName = (creator is Map) ? creator['name'] ?? 'Unknown' : 'Unknown';
                    final creatorId = (creator is Map) ? creator['_id']?.toString() : creator?.toString();

                    final assignee = job['assignedTo'];
                    final assigneeName = (assignee is Map) ? assignee['name'] ?? 'Unknown' : 'Unknown';

                    final isCreator = creatorId == widget.currentUserId;
                    final recipientName = isCreator ? assigneeName : creatorName;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobChatScreen(
                                jobId: jobId,
                                jobTitle: title,
                                currentUserId: widget.currentUserId,
                                recipientName: recipientName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Creator: $creatorName',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Assignee: $assigneeName',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                              ),
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
