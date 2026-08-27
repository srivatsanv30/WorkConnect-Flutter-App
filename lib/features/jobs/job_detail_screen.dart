import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'job_service.dart';
import '../collaboration/job_chat_screen.dart';
import '../auth/user_model.dart';
import '../profile/public_profile_screen.dart';

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

  Widget _buildProgressTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep(Icons.check_circle, 'Assigned', true),
              Expanded(child: Container(height: 2, color: AppTheme.primary)),
              _buildStep(Icons.play_circle_fill, 'In Progress', true),
              Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
              _buildStep(Icons.rate_review, 'Review', false),
              Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
              _buildStep(Icons.done_all, 'Completed', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Icon(icon, color: isActive ? AppTheme.primary : Colors.grey.shade300, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primary : Colors.grey)),
      ],
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
        title: const Text('Project Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text('Posted by $creatorName', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text('Deadline: $deadlineText', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
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
                    _buildProgressTimeline(),
                    const SizedBox(height: 32),
                  ],

                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 32),
                  
                  if (skills.isNotEmpty) ...[
                    const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills
                          .map((s) => Chip(
                                label: Text(s),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
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
                          const SizedBox(width: 12),
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
                    const SizedBox(height: 24),
                  ],

                  // Creator view: show applicants to assign
                  if (isCreator && !hasAssignee && applicants.isNotEmpty) ...[
                    const Text('Applicants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                                  child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      const Text('Wants to collaborate on this project', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                    child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                    child: const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Creator or assignee, once assigned: show chat entry
                  if (hasAssignee && (isCreator || isAssignee)) ...[
                    SizedBox(
                      width: double.infinity,
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
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text('Open Project Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Applicant view (not creator, not yet assigned): apply button
                  if (!isCreator && !hasAssignee)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isApplying ? null : _handleApply,
                        icon: _isApplying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_outlined, size: 20),
                        label: Text(_isApplying ? 'Sending Application...' : 'Apply for this Project', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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