import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import 'job_service.dart';
import '../collaboration/job_chat_screen.dart';
import '../auth/user_model.dart';
import '../auth/auth_service.dart';
import '../profile/public_profile_screen.dart';
import '../tracking/progress_tracker_screen.dart';
import '../tracking/tracking_service.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final String currentUserId;

  const JobDetailScreen({
    super.key,
    required this.job,
    required this.currentUserId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobService = JobService();
  final _trackingService = TrackingService();
  final _authService = AuthService();

  String _resolvedUserId = '';
  bool _isApplying = false;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _isAssigning = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _resolvedUserId = widget.currentUserId;
    if (_resolvedUserId.isEmpty) {
      _authService.getCurrentUserId().then((id) {
        if (id != null && mounted) {
          setState(() => _resolvedUserId = id);
        }
      });
    }
  }

  String get _effectiveUserId =>
      _resolvedUserId.isNotEmpty ? _resolvedUserId : widget.currentUserId;

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
      if (result.success && result.job != null) {
        widget.job.addAll(result.job!);
      }
    });
  }

  Future<void> _refreshJobDetails() async {
    final jobId = widget.job['_id'];
    if (jobId == null) return;
    
    final result = await _jobService.fetchJobById(jobId.toString());
    if (mounted && result.success && result.job != null) {
      setState(() {
        widget.job.clear();
        widget.job.addAll(result.job!);
      });
    }
  }

  void _showUploadProgressDialog(String jobId) {
    final descController = TextEditingController();
    File? selectedImage;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Progress Update',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you completed, changes made, or current status...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () => setSheetState(() => selectedImage = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setSheetState(() => selectedImage = File(picked.path));
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add Progress Screenshot / Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final desc = descController.text.trim();
                            if (desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a description of your progress.')),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            String? base64Image;
                            if (selectedImage != null) {
                              final bytes = await selectedImage!.readAsBytes();
                              base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                            }
                            final result = await _trackingService.submitProgress(
                              jobId,
                              desc,
                              imageUrl: base64Image,
                            );
                            if (!mounted) return;
                            if (result.success && result.job != null) {
                              setState(() => widget.job.addAll(result.job!));
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Progress update submitted successfully!')),
                                );
                              }
                            } else {
                              setSheetState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.errorMessage ?? 'Failed to submit')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Progress Update', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressTimeline(String status, bool isCreator, bool isAssignee, bool hasAssignee) {
    final statusIndex = ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'].indexOf(status);
    final activeColor = AppTheme.primary;
    final inactiveColor = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            isAssignee ? 'Submit for Review' : 'Update Project Status',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isCreator) ...[
                ChoiceChip(
                  label: const Text('In Progress'),
                  selected: status == 'In Progress',
                  onSelected: _isUpdatingStatus ? null : (_) => _updateStatus('In Progress'),
                ),
                const SizedBox(width: 8),
              ],
              ChoiceChip(
                label: const Text('Submit for Review', style: TextStyle(color: Colors.white)),
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
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.primary : Colors.grey)),
      ],
    );
  }

  Future<void> _approveProgressUpdate(String jobId, String updateId) async {
    final result = await _trackingService.approveProgress(jobId, updateId);
    if (!mounted) return;
    if (result.success && result.job != null) {
      setState(() {
        widget.job.addAll(result.job!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress update approved and milestone completed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to approve progress')),
      );
    }
  }

  Widget _buildSubmittedProgressSection(
    List<dynamic> updates, {
    required bool isCreator,
    required String jobId,
  }) {
    if (updates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${updates.length} submitted',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: updates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final u = updates[updates.length - 1 - index]; // Newest first
            final updateId = u['_id']?.toString() ?? '';
            final isApproved = u['approved'] == true;
            final desc = u['description'] ?? '';
            final imageUrl = u['imageUrl'];
            final submittedAt = u['submittedAt'] != null
                ? DateTime.tryParse(u['submittedAt'].toString())
                : null;
            final dateStr = submittedAt != null
                ? '${submittedAt.day}/${submittedAt.month}/${submittedAt.year} at ${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')}'
                : 'Recently';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isApproved ? const Color(0xFF1DBF73).withValues(alpha: 0.3) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isApproved ? Icons.check_circle : Icons.check_circle_outline,
                            size: 16,
                            color: const Color(0xFF1DBF73),
                          ),
                          const SizedBox(width: 6),
                          const Text('Progress Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      if (isApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F9EE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1DBF73).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, size: 12, color: Color(0xFF1DBF73)),
                              SizedBox(width: 4),
                              Text(
                                'Approved',
                                style: TextStyle(
                                  color: Color(0xFF1DBF73),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 12, color: Colors.amber.shade800),
                              const SizedBox(width: 4),
                              Text(
                                'Pending Review',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(fontSize: 14, height: 1.35)),
                  if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildProgressImage(imageUrl.toString()),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (isCreator && !isApproved)
                        ElevatedButton.icon(
                          onPressed: () => _approveProgressUpdate(jobId, updateId),
                          icon: const Icon(Icons.check, size: 15),
                          label: const Text(
                            'Approve & Complete Milestone',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DBF73),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildProgressImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  void _showFeedbackDialog(String jobId, String action) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(action == 'request_changes' ? 'Request Changes' : 'Approve Work'),
        content: TextField(
          controller: feedbackController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Add feedback or comments...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(String jobId) {
    int selectedRating = 5;
    final ratingLabels = ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
    final reviewController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Complete & Rate Project', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate your collaborator:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) => IconButton(
                          icon: Icon(
                            i < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () => setDialogState(() => selectedRating = i + 1),
                        )),
                      ),
                      Text(
                        '${ratingLabels[selectedRating - 1]} ($selectedRating / 5)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Review & Feedback:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share feedback about the collaborator\'s work, communication, and delivery...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DBF73),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await _jobService.completeReview(jobId, selectedRating, reviewController.text.trim());
                if (!mounted) return;
                if (result.success && result.job != null) {
                  setState(() {
                    widget.job.addAll(result.job!);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project completed and review submitted!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.errorMessage ?? 'Failed to complete')),
                  );
                }
              },
              child: const Text('Complete & Submit', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('Delete Job?'),
        content: const Text('This action will permanently delete this job and its associated data. Are you sure you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _jobService.deleteJob(widget.job['_id']);
              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted successfully')));
                Navigator.pop(context);
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
        title: const Text('Hide Job?'),
        content: const Text('This job will be hidden from your view.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _jobService.hideJob(widget.job['_id']);
              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job hidden successfully')));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'Failed to hide job')));
              }
            },
            child: const Text('Hide Job'),
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
    final assigneeName = (assignedTo is Map) ? assignedTo['name'] ?? 'Collaborator' : 'Collaborator';

    final isCreator = creatorId == _effectiveUserId;
    final isAssignee = assignedToId == _effectiveUserId;
    final hasAssignee = assignedToId != null && assignedToId.isNotEmpty;
    final applicants = ((job['applicants'] as List?) ?? []);
    final progressUpdates = (job['progressUpdates'] as List?) ?? [];

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
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _showDeleteDialog,
            )
          else
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined, color: Colors.white),
              onPressed: _showHideDialog,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refreshJobDetails,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Hero Header
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
                  if (hasAssignee) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.handshake_outlined, size: 18, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text('Assigned to $assigneeName', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
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
                  // Progress timeline for creator or assignee
                  if (hasAssignee && (isCreator || isAssignee)) ...[
                    _buildProgressTimeline(status, isCreator, isAssignee, hasAssignee),
                    const SizedBox(height: 32),
                  ],

                  // Assignee action buttons: Message Creator and Upload Progress
                  if (isAssignee) ...[
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
                                    currentUserId: _effectiveUserId,
                                    recipientName: creatorName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text('Message $creatorName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showUploadProgressDialog(jobId),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: Text('Upload Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Creator action buttons: Chat with Assignee and Track Progress
                  if (isCreator && hasAssignee) ...[
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
                                    currentUserId: _effectiveUserId,
                                    recipientName: assigneeName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: Text('Chat with $assigneeName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProgressTrackerScreen(job: job, isCreator: isCreator),
                                ),
                              ).then((updatedJob) {
                                if (updatedJob != null && updatedJob is Map<String, dynamic> && mounted) {
                                  setState(() => widget.job.addAll(updatedJob));
                                } else if (mounted) {
                                  setState(() {});
                                }
                              });
                            },
                            icon: const Icon(Icons.track_changes, size: 18),
                            label: const Text('Track Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submitted Progress Evidence (shown for both creator and assignee)
                  if (hasAssignee && (isCreator || isAssignee))
                    _buildSubmittedProgressSection(
                      progressUpdates,
                      isCreator: isCreator,
                      jobId: jobId,
                    ),

                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.6, fontSize: 15)),
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
                                  child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text('Wants to collaborate on this project', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
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

                  // Creator-only: Review Work and Mark Complete controls
                  if (isCreator && hasAssignee && (status == 'Review' || status == 'In Progress')) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: status == 'Review'
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : AppTheme.primary.withValues(alpha: 0.1))
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.1) : const Color(0xFFF0FDF4)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: status == 'Review'
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : AppTheme.primary.withValues(alpha: 0.3))
                                : (Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.3) : const Color(0xFF86EFAC))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                status == 'Review' ? Icons.rate_review : Icons.verified_outlined,
                                color: status == 'Review'
                                    ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppTheme.primary)
                                    : const Color(0xFF16A34A),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status == 'Review' ? 'Review Submitted Work' : 'Complete Project',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: status == 'Review'
                                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primary)
                                      : (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            status == 'Review'
                                ? 'The collaborator has submitted work for your review. You can request changes or approve and complete the project.'
                                : 'Ready to wrap up? Complete the project and rate your collaborator to reward XP and boost their trust score.',
                            style: TextStyle(
                              color: status == 'Review'
                                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : AppTheme.primary.withValues(alpha: 0.8))
                                  : (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900.withValues(alpha: 0.8)),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (status == 'Review') ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showFeedbackDialog(jobId, 'request_changes'),
                                    icon: const Icon(Icons.replay, size: 18),
                                    label: const Text('Request Changes'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange.shade700,
                                      side: BorderSide(color: Colors.orange.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCompleteDialog(jobId),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Complete & Rate'),
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
                    const SizedBox(height: 24),
                  ],

                  // Completed status info
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
                            children: const [
                              Icon(Icons.check_circle, color: Color(0xFF1DBF73), size: 22),
                              SizedBox(width: 8),
                              Text('Project Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1DBF73))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (job['rating'] != null)
                            Row(
                              children: [
                                ...List.generate(5, (i) => Icon(
                                  i < (job['rating'] as num).toInt() ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                )),
                                const SizedBox(width: 8),
                                Text('${job['rating']}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          if (job['reviewText'] != null && (job['reviewText'] as String).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('"${job['reviewText']}"', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontStyle: FontStyle.italic, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Applicant view (not creator, not assigned): apply button
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
      ),
    );
  }
}