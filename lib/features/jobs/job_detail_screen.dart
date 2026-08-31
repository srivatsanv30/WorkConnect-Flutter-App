import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'job_service.dart';
import '../collaboration/job_chat_screen.dart';
import '../auth/user_model.dart';
import '../profile/public_profile_screen.dart';
import '../tracking/progress_tracker_screen.dart';
import '../tracking/tracking_service.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final String currentUserId;

  const JobDetailScreen({super.key, required this.job, required this.currentUserId});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobService = JobService();
  bool _isApplying = false;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _isAssigning = false;
  final _trackingService = TrackingService();
  bool _isUpdatingStatus = false;

  Future<void> _updateStatus(String newStatus) async {
    final jobId = widget.job['_id'];
    if (jobId == null) return;
    setState(() => _isUpdatingStatus = true);
    final result = await _trackingService.updateStatus(jobId, newStatus);
    if (!mounted) return;
    setState(() => _isUpdatingStatus = false);
    if (result.success && result.job != null) {
      setState(() {
        widget.job.addAll(result.job!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to update status')),
      );
    }
  }

  Future<void> _handleApply() async {
    final jobId = widget.job['_id'];
    if (jobId == null) return;

    setState(() {
      _isApplying = true;
      _statusMessage = null;
    });

    final result = await _jobService.applyToJob(jobId);

    if (!mounted) return;
    setState(() {
      _isApplying = false;
      _statusIsError = !result.success;
      _statusMessage = result.success
          ? 'Applied successfully! The project creator will review your application.'
          : (result.errorMessage ?? 'Failed to apply');
    });
  }

  Widget _buildProgressTimeline(String status, bool isCreator, bool isAssignee, bool hasAssignee) {
    final statusIndex = ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'].indexOf(status);
    final activeColor = AppTheme.primary;
    final inactiveColor = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(Icons.check_circle, 'Assigned', statusIndex >= 1),
              Expanded(child: Container(height: 2, color: statusIndex >= 2 ? activeColor : inactiveColor)),
              _buildStep(Icons.play_circle_fill, 'In Progress', statusIndex >= 2),
              Expanded(child: Container(height: 2, color: statusIndex >= 3 ? activeColor : inactiveColor)),
              _buildStep(Icons.rate_review, 'Review', statusIndex >= 3),
              Expanded(child: Container(height: 2, color: statusIndex >= 4 ? activeColor : inactiveColor)),
              _buildStep(Icons.done_all, 'Completed', statusIndex >= 4),
            ],
          ),
        ),
        if (hasAssignee && (isCreator || isAssignee) && status != 'Completed') ...[
          SizedBox(height: 16),
          Text('Update Project Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text('In Progress'),
                selected: status == 'In Progress',
                onSelected: _isUpdatingStatus ? null : (_) => _updateStatus('In Progress'),
              ),
              SizedBox(width: 8),
              ChoiceChip(
                label: Text('Submit for Review'),
                selected: status == 'Review',
                onSelected: _isUpdatingStatus ? null : (_) => _updateStatus('Review'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Icon(icon, color: isActive ? AppTheme.primary : Colors.grey.shade300, size: 28),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primary : Colors.grey)),
      ],
    );
  }

  void _showFeedbackDialog(String jobId, String action) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'request_changes' ? 'Request Changes' : 'Approve Work'),
        content: TextField(
          controller: feedbackController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add feedback or comments...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _jobService.reviewFeedback(jobId, action, feedbackController.text.trim());
              if (!mounted) return;
              if (result.success && result.job != null) {
                setState(() {
                  widget.job.addAll(result.job!);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(action == 'request_changes' ? 'Changes requested' : 'Work approved')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.errorMessage ?? 'Failed')),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(String jobId) {
    int selectedRating = 5;
    final reviewController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Mark Project as Completed'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate the collaborator:', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = i + 1),
                  )),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write a review for the collaborator...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DBF73)),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await _jobService.completeReview(jobId, selectedRating, reviewController.text.trim());
                if (!mounted) return;
                if (result.success && result.job != null) {
                  setState(() {
                    widget.job.addAll(result.job!);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project marked as completed!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.errorMessage ?? 'Failed to complete')),
                  );
                }
              },
              child: Text('Complete & Rate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Job?'),
        content: Text('This action will permanently delete this job and its associated data. Are you sure you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _jobService.deleteJob(widget.job['_id']);
              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted successfully')));
                Navigator.pop(context); // Go back to jobs list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'Failed to delete job')));
              }
            },
            child: Text('Delete Job', style: TextStyle(color: Theme.of(context).cardColor)),
          ),
        ],
      ),
    );
  }

  void _showHideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hide Job?'),
        content: Text('This job will be hidden from your view.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _jobService.hideJob(widget.job['_id']);
              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job hidden successfully')));
                Navigator.pop(context); // Go back to jobs list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'Failed to hide job')));
              }
            },
            child: Text('Hide Job'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final title = job['title'] ?? 'Untitled Project';
    final description = job['description'] ?? '';
    final skills = ((job['skillsRequired'] as List?) ?? []).cast<String>();
    final priority = job['priority'] ?? 'Medium';
    final status = job['status'] ?? 'Pending';
    final creatorName = (job['creator'] is Map) ? job['creator']['name'] ?? 'Unknown' : 'Unknown';
    final deadlineRaw = job['deadline'];
    final jobId = job['_id']?.toString() ?? '';
    final creatorId = (job['creator'] is Map) ? job['creator']['_id']?.toString() : job['creator']?.toString();
    final assignedTo = job['assignedTo'];
    final assignedToId = (assignedTo is Map) ? assignedTo['_id']?.toString() : assignedTo?.toString();
    final isCreator = creatorId == widget.currentUserId;
    final isAssignee = assignedToId == widget.currentUserId;
    final hasAssignee = assignedToId != null;
    final applicants = ((job['applicants'] as List?) ?? []);
    
    String deadlineText = 'No deadline set';
    if (deadlineRaw != null) {
      final date = DateTime.tryParse(deadlineRaw.toString());
      if (date != null) {
        deadlineText = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Project Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (isCreator)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).cardColor),
              onPressed: _showDeleteDialog,
            )
          else
            IconButton(
              icon: Icon(Icons.visibility_off_outlined, color: Theme.of(context).cardColor),
              onPressed: _showHideDialog,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Hero Header
            Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + kToolbarHeight + 16, 24, 32),
              decoration: BoxDecoration(
                gradient: AppTheme.logoGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).cardColor, height: 1.2)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.white70),
                      SizedBox(width: 6),
                      Text('Posted by $creatorName', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.white70),
                      SizedBox(width: 6),
                      Text('Deadline: $deadlineText', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAssignee && (isCreator || isAssignee)) ...[
                    _buildProgressTimeline(status, isCreator, isAssignee, hasAssignee),
                    SizedBox(height: 32),
                  ],

                  Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 12),
                  Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.6, fontSize: 15)),
                  SizedBox(height: 32),
                  
                  if (skills.isNotEmpty) ...[
                    Text('Required Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                labelStyle: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 32),
                  ],

                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _statusIsError ? const Color(0xFFFFEBEE) : const Color(0xFFE4F9EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusIsError ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusIsError ? Icons.error_outline : Icons.check_circle_outline,
                            color: _statusIsError ? Colors.red.shade700 : const Color(0xFF1DBF73),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _statusIsError ? Colors.red.shade900 : Colors.green.shade900,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Creator view: show applicants to assign
                  if (isCreator && !hasAssignee && applicants.isNotEmpty) ...[
                    Text('Applicants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 16),
                    ...applicants.map((applicant) {
                      final name = (applicant is Map) ? applicant['name'] ?? 'Unknown' : 'Unknown';
                      final id = (applicant is Map) ? applicant['_id']?.toString() : applicant?.toString();
                      final email = (applicant is Map) ? applicant['email'] ?? '' : '';
                      final applicantSkills = (applicant is Map && applicant['skills'] != null) 
                          ? (applicant['skills'] as List).map((e) => e.toString()).toList() 
                          : <String>[];
                      final initials = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                  foregroundColor: AppTheme.primary,
                                  child: Text(initials, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(height: 4),
                                      Text('Wants to collaborate on this project', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final appUser = AppUser(
                                        id: id ?? '',
                                        name: name,
                                        email: email,
                                        skills: applicantSkills,
                                        bio: '',
                                        availability: 'available',
                                      );
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(user: appUser)));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isAssigning
                                        ? null
                                        : () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            setState(() => _isAssigning = true);
                                            final result = await _jobService.assignApplicant(jobId, id ?? '');
                                            if (!mounted) return;
                                            setState(() => _isAssigning = false);
                                            if (result.success) {
                                              setState(() {
                                                widget.job['assignedTo'] = applicant;
                                                widget.job['status'] = 'Accepted';
                                              });
                                            } else {
                                              messenger.showSnackBar(
                                                SnackBar(content: Text(result.errorMessage ?? 'Failed to assign')),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 16),
                  ],

                  // Creator or assignee, once assigned: show chat entry
                  if (hasAssignee && (isCreator || isAssignee)) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
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
                            icon: Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text('Chat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProgressTrackerScreen(job: job),
                                ),
                              ).then((_) {
                                // Refresh job status/details when returning from progress tracker
                                // Just a refresh block if needed
                              });
                            },
                            icon: Icon(Icons.track_changes, size: 18),
                            label: Text('Track Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                  ],

                  // Creator-only: Review Work and Mark Complete controls
                  if (isCreator && hasAssignee && status == 'Review') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.rate_review, color: Colors.orange, size: 22),
                              SizedBox(width: 8),
                              Text('Review Submitted Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text('The collaborator has submitted work for your review. You can request changes or approve and complete the project.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showFeedbackDialog(jobId, 'request_changes'),
                                  icon: Icon(Icons.replay, size: 18),
                                  label: Text('Request Changes'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange.shade700,
                                    side: BorderSide(color: Colors.orange.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCompleteDialog(jobId),
                                  icon: Icon(Icons.check_circle_outline, size: 18),
                                  label: Text('Mark Completed'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1DBF73),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Creator-only: completed status info
                  if (status == 'Completed') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F9EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF1DBF73), size: 22),
                              SizedBox(width: 8),
                              Text('Project Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1DBF73))),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (job['rating'] != null)
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(
                                  i < (job['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                )),
                                SizedBox(width: 8),
                                Text('${job['rating']}/5', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          if (job['reviewText'] != null && (job['reviewText'] as String).isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text('"${job['reviewText']}"', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontStyle: FontStyle.italic, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Applicant view (not creator, not yet assigned): apply button
                  if (!isCreator && !hasAssignee)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isApplying ? null : _handleApply,
                        icon: _isApplying
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).cardColor),
                              )
                            : Icon(Icons.send_outlined, size: 20),
                        label: Text(_isApplying ? 'Sending Application...' : 'Apply for this Project', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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