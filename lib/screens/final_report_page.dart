import 'package:flutter/material.dart';
import 'package:guidex/models/recommendation.dart';
import 'package:guidex/models/final_report_response.dart';
import 'package:guidex/services/api_service.dart';
import 'package:guidex/services/report_export_service.dart';

class FinalReportPage extends StatefulWidget {
  final String studentName;
  final String category;
  final double studentCutoff;
  final String preferredCourse;
  final String? district;
  final bool hostelRequired;
  final List<String> preferredCollegeIds;
  final List<String> preferredCollegeNames;
  final List<Recommendation>? allRecommendations;
  final List<Recommendation>? safeColleges;
  final List<Recommendation>? preferredRecommendations;

  const FinalReportPage({
    super.key,
    required this.studentName,
    required this.category,
    required this.studentCutoff,
    required this.preferredCourse,
    this.district,
    required this.hostelRequired,
    required this.preferredCollegeIds,
    required this.preferredCollegeNames,
    this.allRecommendations,
    this.safeColleges,
    this.preferredRecommendations,
  });

  @override
  State<FinalReportPage> createState() => _FinalReportPageState();
}

class _FinalReportPageState extends State<FinalReportPage> {
  final GlobalKey _reportKey = GlobalKey();

  late List<Recommendation> _filteredSafeColleges;
  bool _isLoading = true;
  FinalReportResponse? _finalReportResponse;
  // Client-side computed target colleges (fallback when backend returns empty)
  List<TargetCollegeResponse> _clientSideTargetColleges = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filteredSafeColleges = _generateSafeColleges();
    _loadFinalReport();
  }

  List<TargetCollegeResponse> get _allTargets {
    if (_finalReportResponse != null && _finalReportResponse!.targetColleges.isNotEmpty) {
      return _finalReportResponse!.targetColleges;
    }
    return _clientSideTargetColleges;
  }

  /// Returns exactly 5 preferred colleges (user selections + next best matches)
  List<TargetCollegeResponse> get _preferredColleges {
    final preferred = _allTargets.where((c) => c.preferenceBonus > 0).toList();
    if (preferred.length >= 5) return preferred.take(5).toList();

    // If fewer than 5 preferred, fill with the next best overall colleges not already included
    final others = _allTargets.where((c) => c.preferenceBonus == 0).toList();
    return [...preferred, ...others].take(5).toList();
  }

  /// Returns the next 15 target colleges (not in preferred)
  List<TargetCollegeResponse> get _targetColleges {
    final preferred = _preferredColleges;
    return _allTargets
        .where((c) => !preferred
            .any((p) => p.collegeName == c.collegeName && p.course == c.course))
        .take(15)
        .toList();
  }
  
  /// Returns only the student explicitly preferred colleges
  List<dynamic> get _explicitPreferredColleges {
    // Priority 1: What is actually being displayed in the "Preferred Colleges" section
    final displayed = _preferredCollegesForDisplay;
    if (displayed.isNotEmpty) {
      return displayed;
    }

    // Fallback: widget-passed recommendations
    if (widget.preferredRecommendations != null &&
        widget.preferredRecommendations!.isNotEmpty) {
      return widget.preferredRecommendations!;
    }
    // Final fallback: matched targets
    return _allTargets.where((c) => c.preferenceBonus > 0).toList();
  }

  Future<void> _loadFinalReport() async {
    try {
      final response = await ApiService().getFinalReport(
        studentName: widget.studentName,
        category: widget.category,
        studentCutoff: widget.studentCutoff,
        preferredCourse: widget.preferredCourse,
        district: widget.district,
        hostelRequired: widget.hostelRequired,
        preferredCollegeIds: widget.preferredCollegeIds,
        preferredCollegeNames: widget.preferredCollegeNames,
      );

      // If backend returned no target colleges, compute client-side
      List<TargetCollegeResponse> clientTargets = [];
      if (response.targetColleges.isEmpty) {
        debugPrint(
            'Backend returned 0 target colleges → computing client-side...');
        clientTargets = await _computeTargetCollegesClientSide();
        debugPrint(
            'Client-side computed ${clientTargets.length} target colleges.');
      }

      if (mounted) {
        setState(() {
          _finalReportResponse = response;
          _clientSideTargetColleges = clientTargets;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Even if backend fails, try client-side
      final clientTargets = await _computeTargetCollegesClientSide();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _clientSideTargetColleges = clientTargets;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAsPDF() async {
    await ReportExportService.exportToPDF(
      studentName: widget.studentName,
      category: widget.category,
      studentCutoff: widget.studentCutoff,
      preferredCourse: widget.preferredCourse,
      safeColleges: _preferredColleges,
      targetColleges: _targetColleges,
      preferredColleges: _explicitPreferredColleges,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CLIENT-SIDE TARGET COLLEGE ALGORITHM
  // Exact formula as specified:
  //   finalScore = 0.4×cutoff + 0.2×location + 0.15×interest
  //              + 0.1×hostel + 0.1×category + 0.05×preference
  //   Filter: finalScore >= 0.55  (NO upper cap)
  //   Sort by finalScore DESC, take top 15
  // ════════════════════════════════════════════════════════════════════════
  Future<List<TargetCollegeResponse>> _computeTargetCollegesClientSide() async {
    try {
      // Fetch all colleges the student qualifies for (with their cutoffs)
      final result = await ApiService().getRecommendationResult(
        category: widget.category,
        cutoff: widget.studentCutoff,
        preferredCourse: widget.preferredCourse,
        district: null, // No district filter — we want all colleges
        preferredCollegeIds: widget.preferredCollegeIds,
        preferredCollegeNames: widget.preferredCollegeNames,
      );

      final allColleges = [
        ...result.safeColleges,
        ...result.preferredColleges,
      ];

      if (allColleges.isEmpty) return [];

      final preferredNamesLower = widget.preferredCollegeNames
          .map((n) => n.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim())
          .toList();

      final scored = <_ScoredCollege>[];

      for (final college in allColleges) {
        final collegeCutoff = college.cutoff > 0 ? college.cutoff : 100.0;
        final studentCutoff = widget.studentCutoff;

        // ── 1. CUTOFF SCORE (40%) ──────────────────────────────────────
        final ratio = studentCutoff / collegeCutoff;
        double cutoffScore;
        if (ratio >= 1.0) {
          cutoffScore = 1.0;
        } else if (ratio >= 0.85) {
          cutoffScore = ratio;
        } else if (ratio >= 0.7) {
          cutoffScore = ratio * 0.8;
        } else {
          cutoffScore = ratio * 0.5;
        }

        // ── 2. LOCATION SCORE (20%) ────────────────────────────────────
        double locationScore;
        final prefDistrict = widget.district?.trim().toLowerCase() ?? '';
        final colDistrict = (college.district ?? '').trim().toLowerCase();
        if (prefDistrict.isEmpty) {
          locationScore = 1.0; // No preference → no penalty
        } else if (colDistrict == prefDistrict ||
            colDistrict.contains(prefDistrict) ||
            prefDistrict.contains(colDistrict)) {
          locationScore = 1.0; // Exact / nearby match
        } else {
          locationScore = 0.3; // No match
        }

        // ── 3. INTEREST SCORE (15%) ────────────────────────────────────
        double interestScore;
        final prefCourse = widget.preferredCourse.trim().toLowerCase();
        final colCourse = college.courseName.trim().toLowerCase();
        if (colCourse == prefCourse ||
            colCourse.contains(prefCourse) ||
            prefCourse.contains(colCourse)) {
          interestScore = 1.0; // Exact match
        } else if (_courseRelated(prefCourse, colCourse)) {
          interestScore = 0.7; // Related
        } else {
          interestScore = 0.2; // No match
        }

        // ── 4. HOSTEL SCORE (10%) ──────────────────────────────────────
        // We don't have hostel availability in the API,
        // so assume available for colleges with hostel pref.
        double hostelScore = widget.hostelRequired ? 1.0 : 0.5;

        // ── 5. CATEGORY SCORE (10%) ────────────────────────────────────
        // Already filtered by category in the API call → always 1.0
        const double categoryScore = 1.0;

        // ── 6. PREFERENCE BOOST (5%) ───────────────────────────────────
        final colNameLower = college.collegeName.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
        final isPreferred = preferredNamesLower.any((p) =>
            p.isNotEmpty &&
            (colNameLower.contains(p) || p.contains(colNameLower)));
        final isPreferredCourse = college.courseName.trim().toLowerCase() ==
            widget.preferredCourse.trim().toLowerCase();
        final double prefScore = isPreferred ? 1.0 : 0.0;

        // ── FINAL WEIGHTED SCORE ───────────────────────────────────────
        final finalScore = (0.40 * cutoffScore) +
            (0.20 * locationScore) +
            (0.15 * interestScore) +
            (0.10 * hostelScore) +
            (0.10 * categoryScore) +
            (0.05 * prefScore);

        final probability = finalScore * 100.0;

        // ── NO FILTER: Include all ranges ─────────────────────────────
        String label;
        if (probability >= 95) {
          label = 'Safe';
        } else if (probability >= 75) {
          label = 'Target';
        } else if (probability >= 60) {
          label = 'Dream';
        } else {
          label = 'Competitive';
        }

        if (finalScore >= 0.35) {
          // Show everything with >35% chance
          scored.add(_ScoredCollege(
            finalScore: finalScore,
            response: TargetCollegeResponse(
              collegeName: college.collegeName,
              course: college.courseName,
              scorePercentage: double.parse(probability.toStringAsFixed(2)),
              district: college.district ?? '',
              chanceLabel: label,
              cutoffScore: double.parse(cutoffScore.toStringAsFixed(2)),
              locationScore: double.parse(locationScore.toStringAsFixed(2)),
              interestScore: double.parse(interestScore.toStringAsFixed(2)),
              hostelScore: double.parse(hostelScore.toStringAsFixed(2)),
              categoryScore: double.parse(categoryScore.toStringAsFixed(2)),
              preferenceBonus: prefScore,
              cutoff: college.cutoff,
            ),
          ));
        }
      }

      // Sort DESC by finalScore, return all for splitting in getters
      scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));
      return scored.map((s) => s.response).toList();
    } catch (e) {
      debugPrint('Client-side target college computation failed: $e');
      return [];
    }
  }

  /// Returns true if two course strings are related (e.g. CSE ↔ Computer Science)
  bool _courseRelated(String pref, String actual) {
    const aliases = <String, List<String>>{
      'computer science engineering': ['cse', 'computer science', 'cs'],
      'information technology': ['it'],
      'electronics and communication': ['ece', 'ec'],
      'electrical and electronics': ['eee', 'ee'],
      'mechanical engineering': ['me', 'mech'],
      'artificial intelligence and data science': ['ai', 'aids', 'ad', 'ai ds'],
      'civil engineering': ['ce', 'civil'],
      'biomedical engineering': ['bme', 'bio'],
      'biotechnology': ['bt', 'bio'],
    };
    for (final entry in aliases.entries) {
      final variants = [entry.key, ...entry.value];
      final prefMatches =
          variants.any((v) => pref.contains(v) || v.contains(pref));
      final actualMatches =
          variants.any((v) => actual.contains(v) || v.contains(actual));
      if (prefMatches && actualMatches) return true;
    }
    return false;
  }

  List<Recommendation> _generateSafeColleges() {
    final safe = widget.safeColleges ?? widget.allRecommendations ?? [];

    // We no longer filter by safe margin, we show exact probability for preferred colleges
    final filtered = safe.toList();

    // Sort by probability (highest first)
    filtered.sort((a, b) => b.probability.compareTo(a.probability));

    // Return top 5
    return filtered.take(5).toList();
  }

  /// Returns preferred colleges for display.
  /// Prefers the locally-passed list; if empty, falls back to backend safeColleges.
  List<dynamic> get _preferredCollegesForDisplay {
    if (_filteredSafeColleges.isNotEmpty) {
      return _filteredSafeColleges;
    }
    // Fallback: use backend's safe colleges (which are the preferred colleges from final-report)
    if (_finalReportResponse != null &&
        _finalReportResponse!.safeColleges.isNotEmpty) {
      return _finalReportResponse!.safeColleges;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Final Report'),
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: RepaintBoundary(
                key: _reportKey,
                child: Container(
                  color: Colors.grey.shade50, // Background for screenshot
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Profile Header
                      _buildStudentHeader(),
                      const SizedBox(height: 24),

                      // Safe Colleges Section
                      _buildSafeCollegesSection(),
                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.red.shade50,
                          child: Text(
                            'Failed to load target colleges: $_errorMessage',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),

                      // Target Colleges Section
                      _buildTargetCollegesSection(),
                      const SizedBox(height: 24),

                      // Download Section
                      // (Moved into Target Colleges Section)
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Profile',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.studentName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfileInfo(
                  icon: Icons.trending_up,
                  label: 'Cutoff',
                  value: widget.studentCutoff.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _buildProfileInfo(
                  icon: Icons.school,
                  label: 'Category',
                  value: widget.category.toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildProfileInfo(
                  icon: Icons.code,
                  label: 'Course',
                  value: _getShortCourseName(widget.preferredCourse),
                ),
              ),
            ],
          ),
          if (widget.district != null && widget.district!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'District: ${widget.district}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSafeCollegesSection() {
    final colleges = _preferredCollegesForDisplay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preferred Colleges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Top ${colleges.length} preferred colleges based on your chances',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (colleges.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                'No preferred colleges found for this cutoff.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          Column(
            children: colleges.asMap().entries.map((entry) {
              final index = entry.key;
              final college = entry.value;
              if (college is Recommendation) {
                return _buildCollegeCard(college, index + 1);
              } else if (college is SafeCollegeResponse) {
                return _buildSafeCollegeCard(college, index + 1);
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCollegeCard(Recommendation college, int rank) {
    String chanceText = '';
    if (college.probability >= 90) {
      chanceText = 'Excellent';
    } else if (college.probability >= 75) {
      chanceText = 'Strong';
    } else if (college.probability >= 60) {
      chanceText = 'Moderate';
    } else if (college.probability >= 40) {
      chanceText = 'Low';
    } else {
      chanceText = 'Very Low';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // College Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  college.collegeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  college.courseName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '🎯 Chance: ${college.probability}% ($chanceText)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: college.probability >= 75
                        ? Colors.green.shade700
                        : (college.probability >= 60
                            ? Colors.orange.shade700
                            : Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      '📊 Your cutoff: ${widget.studentCutoff.toStringAsFixed(1)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '📉 College cutoff: ${college.cutoff.toStringAsFixed(1)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card for SafeCollegeResponse (from backend /api/final-report safeColleges list)
  Widget _buildSafeCollegeCard(SafeCollegeResponse college, int rank) {
    final double prob = college.probability;
    String chanceText;
    if (prob >= 90) {
      chanceText = 'Excellent';
    } else if (prob >= 75) {
      chanceText = 'Strong';
    } else if (prob >= 60) {
      chanceText = 'Moderate';
    } else if (prob >= 40) {
      chanceText = 'Low';
    } else {
      chanceText = 'Very Low';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  college.collegeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  college.course,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '🎯 Chance: ${prob.toStringAsFixed(0)}% ($chanceText)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: prob >= 75
                        ? Colors.green.shade700
                        : (prob >= 60
                            ? Colors.orange.shade700
                            : Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      '📊 Your cutoff: ${widget.studentCutoff.toStringAsFixed(1)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '📉 College cutoff: ${college.collegeCutoff.toStringAsFixed(1)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCollegesSection() {
    final colleges = _targetColleges;
    final preferred = _preferredColleges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preferred Colleges Header (UI)
        if (preferred.isNotEmpty) ...[
          _buildCategoryHeader('Preferred Choices',
              'Your selected top 5 matches', Colors.blue.shade600),
          const SizedBox(height: 12),
          ...preferred.asMap().entries.map(
              (entry) => _buildTargetCollegeCard(entry.value, entry.key + 1)),
          const SizedBox(height: 24),
        ],

        // Target Colleges Header (UI)
        _buildCategoryHeader('Target Colleges', 'Strong Probability (60-95%)',
            Colors.orange.shade600),
        const SizedBox(height: 16),

        if (colleges.isEmpty)
          _buildEmptyState('No additional target colleges found.')
        else
          Column(
            children: colleges.asMap().entries.map((entry) {
              final index = entry.key;
              final college = entry.value;
              return _buildTargetCollegeCard(college, index + 1);
            }).toList(),
          ),
        const SizedBox(height: 32),
        Center(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _downloadAsPDF,
              icon: const Icon(Icons.download, size: 20),
              label: const Text(
                'Download Analysis Report (PDF)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategoryHeader(String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTargetCollegeCard(TargetCollegeResponse college, int rank) {
    // Determine color based on chanceLabel
    Color statusColor;
    if (college.chanceLabel == 'Strong') {
      statusColor = Colors.green.shade600;
    } else if (college.chanceLabel == 'Moderate') {
      statusColor = Colors.orange.shade600;
    } else if (college.chanceLabel == 'Competitive') {
      statusColor = Colors.blue.shade600;
    } else {
      statusColor = Colors.purple.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // College Header
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.collegeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      college.course,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  college.chanceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreMetric('Probability', '${college.scorePercentage}%',
                  Icons.analytics),
              _buildScoreMetric(
                  'Min Cutoff', '${college.cutoff}', Icons.trending_down),
              _buildScoreMetric(
                  'Location',
                  '${(college.locationScore * 100).toInt()}%',
                  Icons.location_on),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String _getShortCourseName(String course) {
    const courseMap = {
      'Computer Science Engineering': 'CSE',
      'Information Technology': 'IT',
      'Electronics and Communication Engineering': 'ECE',
      'Electrical and Electronics Engineering': 'EEE',
      'Mechanical Engineering': 'ME',
      'Civil Engineering': 'CE',
      'Artificial Intelligence and Data Science': 'AI&DS',
      'Biomedical Engineering': 'BME',
      'Chemical Engineering': 'ChE',
      'Biotechnology': 'BT',
    };
    return courseMap[course] ?? course.substring(0, 3).toUpperCase();
  }
}

// ── Private helper for sorting during client-side computation ──────────────
class _ScoredCollege {
  final double finalScore;
  final TargetCollegeResponse response;
  const _ScoredCollege({required this.finalScore, required this.response});
}
