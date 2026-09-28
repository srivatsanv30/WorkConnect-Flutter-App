import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../ai/ai_task_breakdown_screen.dart';
import '../auth/auth_service.dart';
import '../auth/user_model.dart';
import '../collaboration/job_chat_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/job_service.dart';
import '../notification/notification_bell.dart';
import '../profile/public_profile_screen.dart';

enum DashboardMode { freelancer, client }

class HomeOverviewScreen extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<int> onNavigate;
  final String? userName;

  const HomeOverviewScreen({
    super.key,
    this.user,
    required this.onNavigate,
    this.userName,
  });

  @override
  State<HomeOverviewScreen> createState() => _HomeOverviewScreenState();
}

class _HomeOverviewScreenState extends State<HomeOverviewScreen> {
  final _jobService = JobService();
  final _searchController = TextEditingController();

  DashboardMode _mode = DashboardMode.freelancer;
  List<Map<String, dynamic>> _allJobs = [];
  Set<String> _bookmarkedJobIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _selectedPriority = 'All';
  bool _showOnlyBookmarked = false;
  String _searchQuery = '';
  String _resolvedUserId = '';
  
  List<AppUser> _userSearchResults = [];
  bool _isSearchingUsers = false;

  final List<String> _categories = [
    'All',
    'Development',
    'Design',
    'AI/ML',
    'Marketing',
    'Writing',
  ];

  final List<String> _priorities = [
    'All',
    'Urgent',
    'High',
    'Medium',
    'Low',
  ];

  String get _displayName {
    if (widget.user?.name != null && widget.user!.name.isNotEmpty) {
      return widget.user!.name;
    }
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName!;
    }
    return 'there';
  }

  String get _currentUserId =>
      _resolvedUserId.isNotEmpty ? _resolvedUserId : (widget.user?.id ?? '');

  @override
  void initState() {
    super.initState();
    _resolvedUserId = widget.user?.id ?? '';
    if (_resolvedUserId.isEmpty) {
      AuthService().getCurrentUserId().then((id) {
        if (id != null && mounted) {
          setState(() => _resolvedUserId = id);
        }
      });
    }
    _loadBookmarks();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('bookmarked_jobs') ?? [];
      if (mounted) {
        setState(() {
          _bookmarkedJobIds = savedList.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark(String jobId) async {
    final newSet = Set<String>.from(_bookmarkedJobIds);
    if (newSet.contains(jobId)) {
      newSet.remove(jobId);
    } else {
      newSet.add(jobId);
    }
    setState(() {
      _bookmarkedJobIds = newSet;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bookmarked_jobs', newSet.toList());
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newSet.contains(jobId) ? 'Job bookmarked!' : 'Removed from bookmarks',
          style: const TextStyle(fontSize: 12),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jobs = await _jobService.fetchJobs();
      if (!mounted) return;
      setState(() {
        _allJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load jobs. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _performUserSearch(String query) async {
    setState(() => _isSearchingUsers = true);
    final users = await AuthService().searchUsers(query);
    if (!mounted) return;
    if (query == _searchQuery) {
      setState(() {
        _userSearchResults = users;
        _isSearchingUsers = false;
      });
    }
  }

  // Jobs created by current user
  List<Map<String, dynamic>> get _clientJobs {
    return _allJobs.where((job) {
      final creator = job['creator'];
      if (creator == null) return false;
      if (creator is Map) return creator['_id'] == _currentUserId;
      return creator.toString() == _currentUserId;
    }).toList();
  }

  // Jobs user applied to or is assigned to
  List<Map<String, dynamic>> get _activeTrackedJobs {
    return _allJobs.where((job) {
      final assignedTo = job['assignedTo'];
      final applicants = job['applicants'] as List? ?? [];
      final isAssigned = (assignedTo is Map && assignedTo['_id'] == _currentUserId) ||
          assignedTo.toString() == _currentUserId;
      final hasApplied = applicants.any((a) {
        if (a is Map) return a['_id'] == _currentUserId;
        return a.toString() == _currentUserId;
      });
      return isAssigned || hasApplied;
    }).toList();
  }

  // Filtered jobs for Freelancer feed
  List<Map<String, dynamic>> get _filteredJobs {
    return _allJobs.where((job) {
      final jobId = (job['_id'] ?? '').toString();
      final title = (job['title'] ?? '').toString().toLowerCase();
      final description = (job['description'] ?? '').toString().toLowerCase();
      final priority = (job['priority'] ?? 'Medium').toString().toLowerCase();
      final skills = (job['skillsRequired'] as List?)
              ?.map((s) => s.toString().toLowerCase())
              .toList() ??
          [];

      // Bookmarks filter
      if (_showOnlyBookmarked && !_bookmarkedJobIds.contains(jobId)) {
        return false;
      }

      // Priority filter
      if (_selectedPriority != 'All') {
        if (priority != _selectedPriority.toLowerCase()) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = title.contains(q);
        final matchesDesc = description.contains(q);
        final matchesSkills = skills.any((s) => s.contains(q));
        if (!matchesTitle && !matchesDesc && !matchesSkills) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All') {
        final cat = _selectedCategory.toLowerCase();
        final matchesSkills = skills.any((s) => _categoryMatches(cat, s));
        final matchesText = _categoryMatches(cat, title) || _categoryMatches(cat, description);
        if (!matchesSkills && !matchesText) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Search results matching title, description, skills, or creator
  List<Map<String, dynamic>> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allJobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final description = (job['description'] ?? '').toString().toLowerCase();
      final skills = (job['skillsRequired'] as List?)
              ?.map((s) => s.toString().toLowerCase())
              .toList() ??
          [];
      final creator = job['creator'];
      final creatorName = (creator is Map ? (creator['name'] ?? '') : '').toString().toLowerCase();
      return title.contains(q) ||
          description.contains(q) ||
          skills.any((s) => s.contains(q)) ||
          creatorName.contains(q);
    }).toList();
  }

  // Recommended jobs based on user skills, priority, and availability
  List<Map<String, dynamic>> get _recommendedJobs {
    final userSkills = (widget.user?.skills ?? [])
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    // Filter candidate jobs: exclude jobs current user created
    final candidates = _allJobs.where((job) {
      final creator = job['creator'];
      final creatorId = creator is Map ? creator['_id']?.toString() : creator?.toString();
      if (_currentUserId.isNotEmpty && creatorId == _currentUserId) {
        return false;
      }
      final status = (job['status'] ?? 'Open').toString().toLowerCase();
      if (status == 'completed' || status == 'closed') {
        return false;
      }
      return true;
    }).toList();

    if (userSkills.isNotEmpty) {
      candidates.sort((a, b) {
        final aSkills = (a['skillsRequired'] as List?)
                ?.map((s) => s.toString().toLowerCase().trim())
                .toSet() ??
            {};
        final bSkills = (b['skillsRequired'] as List?)
                ?.map((s) => s.toString().toLowerCase().trim())
                .toSet() ??
            {};
        final aOverlap = aSkills.intersection(userSkills).length;
        final bOverlap = bSkills.intersection(userSkills).length;
        if (bOverlap != aOverlap) {
          return bOverlap.compareTo(aOverlap);
        }
        return _priorityWeight(b['priority']).compareTo(_priorityWeight(a['priority']));
      });
    } else {
      candidates.sort((a, b) {
        return _priorityWeight(b['priority']).compareTo(_priorityWeight(a['priority']));
      });
    }

    return candidates.take(6).toList();
  }

  int _priorityWeight(dynamic priority) {
    switch (priority?.toString().toLowerCase()) {
      case 'urgent':
        return 3;
      case 'high':
        return 2;
      case 'medium':
        return 1;
      default:
        return 0;
    }
  }

  bool _isUserCreator(Map<String, dynamic> job) {
    final creator = job['creator'];
    if (creator == null || _currentUserId.isEmpty) return false;
    if (creator is Map) return creator['_id']?.toString() == _currentUserId;
    return creator.toString() == _currentUserId;
  }

  bool _isUserAssigned(Map<String, dynamic> job) {
    final assignedTo = job['assignedTo'];
    if (assignedTo == null || _currentUserId.isEmpty) return false;
    if (assignedTo is Map) return assignedTo['_id']?.toString() == _currentUserId;
    return assignedTo.toString() == _currentUserId;
  }

  String _getCreatorName(Map<String, dynamic> job) {
    final creator = job['creator'];
    if (creator is Map && creator['name'] != null && creator['name'].toString().isNotEmpty) {
      return creator['name'].toString();
    }
    return 'Creator';
  }

  String _getAssigneeName(Map<String, dynamic> job) {
    final assignedTo = job['assignedTo'];
    if (assignedTo == null) return '';
    if (assignedTo is Map && assignedTo['name'] != null && assignedTo['name'].toString().isNotEmpty) {
      return assignedTo['name'].toString();
    }
    return '';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF1DBF73);
      case 'in progress':
        return const Color(0xFF00A9E0);
      case 'review':
        return Colors.orange;
      case 'open':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.blueGrey;
    }
  }

  bool _categoryMatches(String category, String text) {
    final lower = text.toLowerCase();
    switch (category) {
      case 'development':
        return lower.contains('dev') ||
            lower.contains('flutter') ||
            lower.contains('react') ||
            lower.contains('node') ||
            lower.contains('code') ||
            lower.contains('backend') ||
            lower.contains('frontend') ||
            lower.contains('full-stack') ||
            lower.contains('web') ||
            lower.contains('mobile') ||
            lower.contains('api');
      case 'design':
        return lower.contains('design') ||
            lower.contains('ui') ||
            lower.contains('ux') ||
            lower.contains('figma') ||
            lower.contains('logo') ||
            lower.contains('graphic');
      case 'ai/ml':
        return lower.contains('ai') ||
            lower.contains('ml') ||
            lower.contains('python') ||
            lower.contains('openai') ||
            lower.contains('gpt') ||
            lower.contains('machine learning') ||
            lower.contains('model');
      case 'marketing':
        return lower.contains('market') ||
            lower.contains('seo') ||
            lower.contains('social') ||
            lower.contains('growth') ||
            lower.contains('ads');
      case 'writing':
        return lower.contains('writ') ||
            lower.contains('content') ||
            lower.contains('copy') ||
            lower.contains('blog') ||
            lower.contains('edit');
      default:
        return lower.contains(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadJobs,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeroHeader(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _mode == DashboardMode.freelancer
                      ? _buildFreelancerView(context)
                      : _buildClientView(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO HEADER & MODE TOGGLE
  // ---------------------------------------------------------------------------
  Widget _buildHeroHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          gradient: AppTheme.getHeroGradient(context),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Greeting + Notification Bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back 👋',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                NotificationBell(currentUserId: _currentUserId),
              ],
            ),
            const SizedBox(height: 18),

            // Mode Selector: Find Work vs Hire Talent
            _buildModeSelector(context),
            const SizedBox(height: 16),

            // Search Bar
            _buildSearchBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeTab(
              label: 'Find Work',
              icon: Icons.work_outline_rounded,
              isSelected: _mode == DashboardMode.freelancer,
              onTap: () => setState(() => _mode = DashboardMode.freelancer),
            ),
            const SizedBox(width: 4),
            _buildModeTab(
              label: 'Hire Talent',
              icon: Icons.person_search_outlined,
              isSelected: _mode == DashboardMode.client,
              onTap: () => setState(() => _mode = DashboardMode.client),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
          if (_mode == DashboardMode.client && _searchQuery.isNotEmpty) {
            _performUserSearch(_searchQuery);
          }
        },
        decoration: InputDecoration(
          hintText: _mode == DashboardMode.freelancer
              ? 'Search jobs, skills, or projects...'
              : 'Search candidates, skills, or job posts...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FREELANCER VIEW ("FIND WORK")
  // ---------------------------------------------------------------------------
  Widget _buildFreelancerView(BuildContext context) {
    final activeJobs = _activeTrackedJobs;
    final searchResults = _searchResults;
    final recommendedJobs = _recommendedJobs;

    if (_searchQuery.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Results Section
          _buildSearchResultsSection(context, searchResults),
          const SizedBox(height: 28),

          // 2. Recommended Jobs Section (below search results)
          _buildRecommendedSection(context, recommendedJobs),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Real Freelancer Activity Metrics (no hardcoded reviews)
        _buildFreelancerMetrics(context),
        const SizedBox(height: 24),

        // 2. Application & Milestone Status Tracker
        if (activeJobs.isNotEmpty) ...[
          _buildApplicationTracker(context, activeJobs),
          const SizedBox(height: 28),
        ],

        // 3. Recommended Jobs / Projects Section
        _buildRecommendedSection(context, recommendedJobs),
        const SizedBox(height: 28),

        // 4. Quick Action Shortcuts
        _buildQuickActions(context),
        const SizedBox(height: 28),

        // 5. Advanced Filters (Categories + Priorities + Bookmarks)
        _buildAdvancedFilters(context),
        const SizedBox(height: 20),

        // 6. Live Jobs Feed from Database
        _buildLiveJobsSection(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFreelancerMetrics(BuildContext context) {
    final completed = widget.user?.projectsCompleted ?? 0;
    final hasRating = widget.user?.ratingCount != null && widget.user!.ratingCount > 0;
    final ratingDisplay = hasRating
        ? '${widget.user!.ratingAverage.toStringAsFixed(1)} ★'
        : 'No reviews';
    final xp = widget.user?.xp ?? 0;
    final activeCount = _activeTrackedJobs.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.pending_actions_rounded,
              iconColor: const Color(0xFF00A9E0),
              value: '$activeCount',
              label: 'Active',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF1DBF73),
              value: '$completed',
              label: 'Completed',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.star_rounded,
              iconColor: hasRating ? Colors.amber : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              value: ratingDisplay,
              label: 'Rating',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.military_tech_outlined,
              iconColor: const Color(0xFF8B5CF6),
              value: '$xp XP',
              label: 'Level',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationTracker(BuildContext context, List<Map<String, dynamic>> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Application Tracker',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DBF73).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${jobs.length} tracked',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DBF73),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigate(1),
                child: const Text(
                  'Workspace Hub →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined, color: AppTheme.primary.withValues(alpha: 0.6), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No active applications yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Apply to live jobs below to track status and milestones.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                final title = job['title'] ?? 'Job';
                final status = job['status'] ?? 'Pending';
                final milestones = (job['milestones'] as List?) ?? [];
                final completedCount = milestones.where((m) => m['done'] == true).length;

                Color statusColor;
                switch (status.toString().toLowerCase()) {
                  case 'completed':
                    statusColor = const Color(0xFF1DBF73);
                    break;
                  case 'in progress':
                    statusColor = const Color(0xFF00A9E0);
                    break;
                  case 'review':
                    statusColor = Colors.orange;
                    break;
                  default:
                    statusColor = Colors.blueGrey;
                }

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(job: job, currentUserId: _currentUserId),
                      ),
                    ).then((_) => _loadJobs());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 230,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              milestones.isNotEmpty
                                  ? '$completedCount/${milestones.length} milestones'
                                  : 'Active contract',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            if (milestones.isNotEmpty)
                              Text(
                                '${((completedCount / milestones.length) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAdvancedFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pills + Bookmark Toggle
        SizedBox(
          height: 38,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              // Saved / Bookmarks Filter Chip
              InkWell(
                onTap: () => setState(() => _showOnlyBookmarked = !_showOnlyBookmarked),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showOnlyBookmarked ? Colors.amber : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showOnlyBookmarked
                          ? Colors.amber
                          : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showOnlyBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 15,
                        color: _showOnlyBookmarked ? Colors.black87 : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Saved (${_bookmarkedJobIds.length})',
                        style: TextStyle(
                          color: _showOnlyBookmarked ? Colors.black87 : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Categories
              ..._categories.map((cat) {
                final isSelected = _selectedCategory == cat && !_showOnlyBookmarked;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                      _showOnlyBookmarked = false;
                    }),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Priority Filter Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Urgency: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _priorities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final p = _priorities[index];
                      final isSelected = _selectedPriority == p;
                      return InkWell(
                        onTap: () => setState(() => _selectedPriority = p),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.15)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CLIENT VIEW ("HIRE TALENT")
  // ---------------------------------------------------------------------------
  Widget _buildClientView(BuildContext context) {
    final clientJobs = _clientJobs;
    final searchResults = _searchResults;
    final recommendedJobs = _recommendedJobs;

    if (_searchQuery.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserSearchResultsSection(context, _userSearchResults),
          const SizedBox(height: 28),
          _buildRecommendedSection(context, recommendedJobs),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Real Client Metrics
        _buildClientMetrics(context, clientJobs),
        const SizedBox(height: 24),

        // 2. Post a Job Hero Call-To-Action Banner
        _buildPostJobBanner(context),
        const SizedBox(height: 28),

        // 3. My Posted Jobs Section from Database
        _buildPostedJobsSection(context, clientJobs),
        const SizedBox(height: 32),

        // 4. Recommended Jobs / Projects Section
        _buildRecommendedSection(context, recommendedJobs),
        const SizedBox(height: 28),

        // 5. Quick Actions for Client
        _buildQuickActions(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildClientMetrics(BuildContext context, List<Map<String, dynamic>> myJobs) {
    final postedCount = myJobs.length;
    final inProgress = myJobs.where((j) => j['status'] == 'In Progress' || j['status'] == 'Accepted').length;
    final totalApplicants = myJobs.fold<int>(0, (sum, j) => sum + ((j['applicants'] as List?)?.length ?? 0));
    final completed = myJobs.where((j) => j['status'] == 'Completed').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.post_add_rounded,
              iconColor: AppTheme.primary,
              value: '$postedCount',
              label: 'Jobs Posted',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.people_outline_rounded,
              iconColor: const Color(0xFF00A9E0),
              value: '$totalApplicants',
              label: 'Applicants',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.hourglass_top_rounded,
              iconColor: Colors.orange,
              value: '$inProgress',
              label: 'In Progress',
            ),
            Container(height: 36, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            _buildStatItem(
              context,
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF1DBF73),
              value: '$completed',
              label: 'Completed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostJobBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F88C6), Color(0xFF26B6C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F88C6).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Need work done fast?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Publish your project with required skills, deadlines, and milestones to get proposals from skilled freelancers.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.onNavigate(2),
              icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
              label: const Text('Post a Project Now', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostedJobsSection(BuildContext context, List<Map<String, dynamic>> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Posted Projects',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
              ),
              InkWell(
                onTap: () => widget.onNavigate(1),
                child: const Text(
                  'Manage All →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 36, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    const Text('No posted projects yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first job to see applicants and tracking here.',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return _buildJobCard(context, jobs[index]);
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH RESULTS & RECOMMENDED SECTIONS
  // ---------------------------------------------------------------------------
  Widget _buildUserSearchResultsSection(BuildContext context, List<AppUser> results) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_search, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Talent Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSearchingUsers)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${results.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear Search', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isSearchingUsers && results.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No talents found matching "$_searchQuery"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (!_isSearchingUsers)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final user = results[index];
                final nameInitials = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(user: user)));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                              child: Text(nameInitials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  if (user.title.isNotEmpty)
                                    Text(user.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(user: user)));
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection(BuildContext context, List<Map<String, dynamic>> results) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${results.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear Search', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No jobs found matching "$_searchQuery"',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching for different keywords, skills, or project titles.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _buildModernJobCard(context, results[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(BuildContext context, List<Map<String, dynamic>> recommended) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Recommended Projects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Matched',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigate(1),
                child: const Text(
                  'Explore →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (recommended.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add skills to your profile to receive tailored job recommendations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 300,
                  child: _buildModernJobCard(context, recommended[index], isHorizontal: true),
                );
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LIVE JOBS FEED (FREELANCER)
  // ---------------------------------------------------------------------------
  Widget _buildLiveJobsSection(BuildContext context) {
    final jobs = _filteredJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Live Jobs Feed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${jobs.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              InkWell(
                onTap: () => widget.onNavigate(1),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          )
        else if (_errorMessage != null && _allJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: _loadJobs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (jobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.work_off_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showOnlyBookmarked || _selectedPriority != 'All'
                        ? 'No jobs match your filters'
                        : 'No jobs posted yet',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try resetting filters or changing the search keywords.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                        _selectedPriority = 'All';
                        _showOnlyBookmarked = false;
                      });
                    },
                    child: const Text('Reset All Filters'),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: jobs.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildModernJobCard(context, job, isHorizontal: false),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildModernJobCard(
    BuildContext context,
    Map<String, dynamic> job, {
    bool isHorizontal = false,
  }) {
    final jobId = (job['_id'] ?? '').toString();
    final title = (job['title'] ?? 'Untitled Job').toString();
    final description = (job['description'] ?? 'No description provided.').toString();
    final priority = (job['priority'] ?? 'Medium').toString();
    final status = (job['status'] ?? 'Open').toString();
    final skills = (job['skillsRequired'] as List?)?.map((s) => s.toString()).toList() ?? [];
    final isBookmarked = _bookmarkedJobIds.contains(jobId);

    final creatorName = _getCreatorName(job);
    final assigneeName = _getAssigneeName(job);
    final isCreator = _isUserCreator(job);
    final isAssignee = _isUserAssigned(job);

    final statusColor = _getStatusColor(status);

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.blueGrey;
        break;
      default:
        priorityColor = AppTheme.primary;
    }

    return Container(
      width: isHorizontal ? 300 : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isHorizontal ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Row: Status + Priority + Bookmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _toggleBookmark(jobId),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isBookmarked
                        ? Colors.amber
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Skills chips
          if (skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Creator & Assignee info
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'By $creatorName${assigneeName.isNotEmpty ? ' • Assigned to $assigneeName' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (isHorizontal) const Spacer() else const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(
                          job: job,
                          currentUserId: _currentUserId,
                        ),
                      ),
                    ).then((_) => _loadJobs());
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primary,
                    ),
                  ),
                ),
              ),
              if (isAssignee) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobChatScreen(
                            jobId: jobId,
                            jobTitle: title,
                            currentUserId: _currentUserId,
                            recipientName: creatorName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text(
                      'Message',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ] else if (isCreator && assigneeName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobChatScreen(
                            jobId: jobId,
                            jobTitle: title,
                            currentUserId: _currentUserId,
                            recipientName: assigneeName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text(
                      'Message',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    return _buildModernJobCard(context, job, isHorizontal: true);
  }

  // ---------------------------------------------------------------------------
  // QUICK ACTIONS & STATS HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Post a Job',
                  icon: Icons.add_circle_outline,
                  color: AppTheme.primary,
                  onTap: () => widget.onNavigate(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Workspace Hub',
                  icon: Icons.grid_view_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () => widget.onNavigate(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Collaborate',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () => widget.onNavigate(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'AI Breakdown',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiTaskBreakdownScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
