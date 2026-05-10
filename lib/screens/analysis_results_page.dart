import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guidex/app_routes.dart';
import 'package:guidex/models/recommendation.dart';
import 'package:guidex/models/recommendation_result.dart';
import 'package:guidex/services/api_service.dart';
import 'package:guidex/services/report_export_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AnalysisResultsPage extends StatefulWidget {
  final String? name;
  final double? cutoff;
  final String? category;
  final List<String>? selectedCourses;
  final String? interest;
  final String? district;
  final List<String>? preferredCollegeIds;
  final List<String>? preferredColleges;
  final RecommendationResult? prefetchedResult;
  final List<Recommendation>? prefetchedRecommendations;
  final String? prefetchError;

  const AnalysisResultsPage({
    super.key,
    this.name = 'John Doe',
    this.cutoff = 182.5,
    this.category = 'BC',
    this.selectedCourses = const ['CSE', 'AI/Data Science', 'ECE'],
    this.interest,
    this.district,
    this.preferredCollegeIds,
    this.preferredColleges,
    this.prefetchedResult,
    this.prefetchedRecommendations,
    this.prefetchError,
  });

  @override
  State<AnalysisResultsPage> createState() => _AnalysisResultsPageState();
}

class _AnalysisResultsPageState extends State<AnalysisResultsPage> {
  final ApiService _apiService = ApiService();
  static const int _sectionPageSize = 12;

  bool _isLoading = true;
  bool _isDownloadingReport = false;
  String? _errorMessage;
  RecommendationResult _result = const RecommendationResult.empty();
  int _preferredVisibleCount = _sectionPageSize;
  int _safeVisibleCount = _sectionPageSize;

  List<Recommendation> get _preferredRecommendations =>
      _result.preferredColleges;
  List<Recommendation> get _safeRecommendations => _result.safeColleges;
  List<Recommendation> get _allRecommendations => _result.all;

  String get _resolvedCategory {
    final value = widget.category?.trim().toUpperCase();
    return (value == null || value.isEmpty) ? 'MBC' : value;
  }

  double get _resolvedCutoff {
    return widget.cutoff ?? 182.5;
  }

  String get _resolvedInterest {
    final interest = widget.interest?.trim();
    if (interest != null && interest.isNotEmpty) {
      return interest;
    }

    final firstCourse = widget.selectedCourses?.firstWhere(
      (item) => item.trim().isNotEmpty,
      orElse: () => 'Software',
    );
    return firstCourse?.trim() ?? 'Software';
  }

  String get _resolvedName {
    final value = widget.name?.trim();
    return (value == null || value.isEmpty) ? 'John Doe' : value;
  }

  List<String> get _resolvedSelectedCourses {
    final cleaned = (widget.selectedCourses ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (cleaned.isNotEmpty) {
      return cleaned;
    }

    final interest = _resolvedInterest.trim();
    if (interest.isNotEmpty) {
      return <String>[interest];
    }

    return const <String>['Computer Science Engineering'];
  }

  List<String> get _resolvedPreferredCollegeIds {
    return (widget.preferredCollegeIds ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(5)
        .toList();
  }

  List<String> get _resolvedPreferredCollegeNames {
    return (widget.preferredColleges ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    if (widget.prefetchedResult != null) {
      _result = widget.prefetchedResult!;
      _isLoading = false;
      if (widget.prefetchError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar('Failed to fetch recommendations');
        });
      }
      return;
    }

    if (widget.prefetchedRecommendations != null) {
      _result = RecommendationResult(
        preferredColleges: const [],
        safeColleges:
            List<Recommendation>.from(widget.prefetchedRecommendations!),
      );
      _isLoading = false;
      if (widget.prefetchError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackBar('Failed to fetch recommendations');
        });
      }
      return;
    }

    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (_resolvedCutoff <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a valid cutoff and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestedDistrict = widget.district?.trim();

      final results = await _apiService.getRecommendationResult(
        category: _resolvedCategory,
        cutoff: _resolvedCutoff,
        preferredCourse: _resolvedInterest,
        district: requestedDistrict,
        preferredCollegeIds: _resolvedPreferredCollegeIds,
        preferredCollegeNames: _resolvedPreferredCollegeNames,
      );

      if (!mounted) return;

      setState(() {
        _result = results;
        _isLoading = false;
        _preferredVisibleCount = _sectionPageSize;
        _safeVisibleCount = _sectionPageSize;
      });

      if (results.isEmpty) {
        final districtLabel =
            (requestedDistrict == null || requestedDistrict.isEmpty)
                ? 'all districts'
                : requestedDistrict;
        _showSnackBar(
          'No exact $_resolvedInterest seats found for $districtLabel. Try Software/IT or another category.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      debugPrint('Recommendation fetch failed: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch recommendations';
      });
      _showSnackBar('Failed to fetch recommendations');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildInsightCard(),
                    const SizedBox(height: 32),
                    _buildContent(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1F2937),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF1F2937),
              size: 22,
            ),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Analysis Report',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your cutoff and preferences',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _resolvedName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _resolvedCategory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUTOFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resolvedCutoff.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COURSES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _resolvedSelectedCourses
                          .map((course) => _buildChip(course))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    final totalColleges = _allRecommendations.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Insight',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    Text(
                      '$totalColleges Colleges',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  totalColleges == 0
                      ? 'No college recommendations available yet for this profile. Please refresh or re-analyze with different preferences.'
                      : 'You have $totalColleges recommendations with cutoff ${_resolvedCutoff.toStringAsFixed(1)} in $_resolvedCategory category. Review preferred and safe college groups below.',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1B4B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _allRecommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to load recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allRecommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No colleges found for the selected criteria.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      );
    }

    final showPreferredSection = _resolvedPreferredCollegeIds.isNotEmpty ||
        _preferredRecommendations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreferredSection)
          _buildRecommendationSection(
            title: 'Your Preferred Colleges',
            color: const Color(0xFF2563EB),
            items: _preferredRecommendations,
            visibleCount: _preferredVisibleCount,
            sortByCutoffAscending: false,
            showCourseInfo: false,
            showLocationAction: false,
            onShowMore: () {
              setState(() {
                _preferredVisibleCount += _sectionPageSize;
              });
            },
          ),
        if (showPreferredSection) const SizedBox(height: 24),
        _buildRecommendationSection(
          title: 'Safe Colleges',
          color: const Color(0xFF22C55E),
          items: _safeRecommendations,
          visibleCount: _safeVisibleCount,
          sortByCutoffAscending: false,
          showCourseInfo: true,
          showLocationAction: true,
          onShowMore: () {
            setState(() {
              _safeVisibleCount += _sectionPageSize;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationSection({
    required String title,
    required Color color,
    required List<Recommendation> items,
    required int visibleCount,
    required bool sortByCutoffAscending,
    required bool showCourseInfo,
    required bool showLocationAction,
    required VoidCallback onShowMore,
  }) {
    final sortedItems = sortByCutoffAscending
        ? _sortRecommendationList(items)
        : List<Recommendation>.from(items);
    final visibleItems = sortedItems.take(visibleCount).toList();
    final remaining = sortedItems.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('$title (${items.length})', color),
        const SizedBox(height: 12),
        if (visibleItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No colleges in this category for current cutoff and filters.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ...visibleItems.map(
          (item) => _buildCollegeCard(
            item,
            color,
            showCourseInfo: showCourseInfo,
            showLocationAction: showLocationAction,
          ),
        ),
        if (remaining > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onShowMore,
              child: Text('Show ${math.min(_sectionPageSize, remaining)} more'),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildCollegeCard(
    Recommendation item,
    Color color, {
    required bool showCourseInfo,
    required bool showLocationAction,
  }) {
    final probability = item.probability;
    final badge = _categoryLabel(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.collegeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                if (showCourseInfo || showLocationAction) ...[
                  Row(
                    children: [
                      if (showCourseInfo)
                        Expanded(
                          child: Text(
                            item.courseName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (showLocationAction)
                        IconButton(
                          icon: Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey.shade700,
                            size: 20,
                          ),
                          splashRadius: 18,
                          tooltip: 'Open in Google Maps',
                          onPressed: () => _openCollegeLocation(item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    _buildProbabilityIndicator(probability, color),
                    const SizedBox(width: 8),
                    Text(
                      '$probability% Probability',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityIndicator(int value, Color color) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Final Report Button (Primary)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.finalReport,
                arguments: {
                  'studentName': widget.name ?? 'Student',
                  'category': widget.category ?? 'OC',
                  'studentCutoff': widget.cutoff ?? 0,
                  'preferredCourse': widget.interest ??
                      (widget.selectedCourses?.firstOrNull ?? ''),
                  'district': widget.district,
                  'hostelRequired': false,
                  'preferredCollegeIds': widget.preferredCollegeIds ?? [],
                  'preferredCollegeNames': widget.preferredColleges ?? [],
                  'allRecommendations': _allRecommendations,
                  'safeColleges': _safeRecommendations,
                  'preferredRecommendations': _preferredRecommendations,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'View Final Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isDownloadingReport ? null : _downloadReport,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDownloadingReport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Download',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.analysisTest,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Re-analyze',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Recommendation> _sortRecommendationList(List<Recommendation> items) {
    final sorted = List<Recommendation>.from(items)
      ..sort((a, b) {
        final byProbability = b.probability.compareTo(a.probability);
        if (byProbability != 0) {
          return byProbability;
        }
        final byCutoff = b.cutoff.compareTo(a.cutoff);
        if (byCutoff != 0) {
          return byCutoff;
        }
        return a.collegeName
            .toLowerCase()
            .compareTo(b.collegeName.toLowerCase());
      });

    return sorted;
  }

  String? _normalizeCategoryToken(String value) {
    final normalized = value.trim().toLowerCase();

    const aliases = <String, String>{
      'preferred': 'preferred',
      'safe': 'safe',
      'likely': 'safe',
      'safety': 'safe',
      'secure': 'safe',
    };

    return aliases[normalized];
  }

  Future<void> _openCollegeLocation(Recommendation item) async {
    final query = Uri.encodeComponent(
      '${item.collegeName} ${item.district ?? ''}'.trim(),
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnackBar('Unable to open location for ${item.collegeName}.');
    }
  }

  String _categoryLabel(String category) {
    final normalized = _normalizeCategoryToken(category) ?? 'safe';
    if (normalized == 'preferred') {
      return 'Preferred';
    }
    return 'Safe';
  }

  Future<void> _downloadReport() async {
    await generateAndDownloadPdf();
  }

  Future<void> generateAndDownloadPdf() async {
    if (_isDownloadingReport) {
      return;
    }

    setState(() {
      _isDownloadingReport = true;
    });

    try {
      await ReportExportService.exportToPDF(
        studentName: _resolvedName,
        studentCutoff: _resolvedCutoff,
        category: _resolvedCategory,
        preferredCourse: _resolvedSelectedCourses.join(', '),
        safeColleges: _safeRecommendations,
        targetColleges: [],
        preferredColleges: _preferredRecommendations,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('PDF report generated successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_formatReportError(error));
      debugPrint('Report download failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingReport = false;
        });
      }
    }
  }

  String _buildFileName() {
    final now = DateTime.now();
    final safeName = _resolvedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final suffix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    if (safeName.isEmpty) {
      return 'analysis_report_$suffix';
    }
    return '${safeName}_analysis_report_$suffix';
  }

  String _formatReportError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Failed to generate PDF report.';
    }

    final cleaned = message.startsWith('Exception:')
        ? message.substring('Exception:'.length).trim()
        : message;

    return 'Failed to generate PDF report: $cleaned';
  }
}
