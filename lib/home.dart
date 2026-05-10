import 'package:flutter/material.dart';
import 'package:guidex/app_routes.dart';
import 'package:guidex/models/student_profile.dart';
import 'package:guidex/services/api_service.dart';
import 'package:guidex/services/auth/auth_scope.dart';
import 'package:guidex/models/recommendation.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ApiService _apiService = ApiService();
  final _authController = AuthScope.controller;
  int _selectedIndex = 0;
  List<Recommendation> _recommendedColleges = [];
  bool _isRecommendationsLoading = true;

  // Mocking the user category for now.
  // In a real app, this would come from a preference or user profile.
  // Categories: '12th', 'college', 'aspirant'
  final String _userCategory = '12th';

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthChanged);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    await _authController.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _loadRecommendations() async {
    try {
      // Mocking cutoff and interest for the dashboard preview
      final results = await _apiService.getRecommendations(
          category: 'OC', cutoff: 185.0, interest: 'Software');
      setState(() {
        _recommendedColleges = results;
        _isRecommendationsLoading = false;
      });
    } catch (e) {
      setState(() => _isRecommendationsLoading = false);
      debugPrint('Error loading dashboard recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF9FAFB);
    const Color primaryColor = Color(0xFF3B82F6);
    const Color secondaryColor = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              _buildGreeting(),
              const SizedBox(height: 24),

              // Your Next Step Highlight Card
              _buildNextStepCard(primaryColor, secondaryColor),
              const SizedBox(height: 32),

              // Progress Section
              _buildProgressSection(primaryColor),
              const SizedBox(height: 32),

              // Quick Actions Grid
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(primaryColor),
              const SizedBox(height: 32),

              // Personalized Content Section
              _buildPersonalizedContent(primaryColor, secondaryColor),
              const SizedBox(height: 32),

              // Today's Plan Section
              _buildTodaysPlan(primaryColor),
              const SizedBox(height: 100), // Spacing for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }

  Widget _buildGreeting() {
    final StudentProfile? user = _authController.currentUser;
    final String firstName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : 'Student';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning, $firstName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ready to conquer your goals today?',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: _authController.isLoading ? null : _logout,
          icon: const Icon(Icons.logout_rounded),
          color: const Color(0xFF111827),
        ),
      ],
    );
  }

  Widget _buildNextStepCard(Color primary, Color secondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Next Step',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore Top Engineering\nColleges in India',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '60%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          const Text(
            '3 out of 5 mock tests completed this week',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(Color primary) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Colleges',
        'icon': Icons.school_outlined,
        'color': Colors.orange,
      },
      {'title': 'Courses', 'icon': Icons.book_outlined, 'color': Colors.green},
      {'title': 'Tests', 'icon': Icons.edit_document, 'color': Colors.red},
      {
        'title': 'Career Paths',
        'icon': Icons.trending_up,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (index == 0) {
              Navigator.pushNamed(context, AppRoutes.analysisTest);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${actions[index]['title']} coming soon!')),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  actions[index]['icon'],
                  color: actions[index]['color'],
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  actions[index]['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalizedContent(Color primary, Color secondary) {
    String title = '';
    List<Map<String, String>> items = [];

    if (_userCategory == '12th') {
      title = 'Colleges for You';
      if (_isRecommendationsLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_recommendedColleges.isEmpty) {
        items = [
          {'title': 'IIT Madras', 'subtitle': 'Top Engineering Research'},
          {'title': 'BITS Pilani', 'subtitle': 'Excellence in Technology'},
        ];
      } else {
        items = _recommendedColleges.take(5).map<Map<String, String>>((e) {
          return {
            'title': e.collegeName,
            'subtitle': e.courseName,
          };
        }).toList();
      }
    } else if (_userCategory == 'college') {
      title = 'Skills & Internships';
      items = [
        {
          'title': 'Google Summer of Code',
          'subtitle': 'Open Source Opportunity',
        },
        {'title': 'Data Science Bootcamp', 'subtitle': 'Trending Skill'},
      ];
    } else {
      title = 'Focus Areas';
      items = [
        {'title': 'Physics: Optics', 'subtitle': 'Weak Area identified by AI'},
        {'title': 'Mock Test 4', 'subtitle': 'Recommended for Practice'},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All', style: TextStyle(color: primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.star, color: secondary, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      items[index]['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index]['subtitle']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysPlan(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Plan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.calendar_today, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskItem("Solve 20 Math problems", true),
          const SizedBox(height: 12),
          _buildTaskItem("Read Chemistry Chapter 4", false),
          const SizedBox(height: 12),
          _buildTaskItem("Attempt Mock English Quiz", false),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, bool completed) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: completed ? Colors.green : Colors.transparent,
            border: Border.all(
              color: completed ? Colors.green : Colors.white38,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: completed
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: completed ? Colors.white54 : Colors.white,
            fontSize: 14,
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(Color primary) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Learn',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Tests'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
