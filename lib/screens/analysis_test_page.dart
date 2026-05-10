import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guidex/app_routes.dart';
import 'package:guidex/models/college_option.dart';
import 'package:guidex/models/recommendation.dart';
import 'package:guidex/services/api_service.dart';

class AnalysisTestPage extends StatefulWidget {
  const AnalysisTestPage({super.key});

  @override
  State<AnalysisTestPage> createState() => _AnalysisTestPageState();
}

class _AnalysisTestPageState extends State<AnalysisTestPage> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Screen 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Screen 1 Focus Nodes & Error State
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final Map<String, bool> _fieldErrors = {
    'name': false,
    'age': false,
    'mobile': false,
    'email': false,
    'category': false,
  };

  // Screen 2 Controllers
  final TextEditingController _physicsController = TextEditingController();
  final TextEditingController _chemistryController = TextEditingController();
  final TextEditingController _mathsController = TextEditingController();

  // Screen 2 Focus Nodes & Error State
  final FocusNode _physicsFocusNode = FocusNode();
  final FocusNode _chemistryFocusNode = FocusNode();
  final FocusNode _mathsFocusNode = FocusNode();
  final Map<String, bool> _step2FieldErrors = {
    'physics': false,
    'chemistry': false,
    'maths': false,
  };
  double _cutoff = 0.0;
  final List<String> _categories = [
    'OC',
    'BC',
    'BCM',
    'MBC',
    'SC',
    'SCA',
    'ST'
  ];

  // Final Selection Data
  String _selectedCategory = '';
  String _selectedDistrict = 'Any';
  String _selectedInterest = '';
  String _hostelPreference = ''; // 'Yes' or 'No'
  final List<String> _assignedDepartments = [];


  final List<String> _fallbackCourses = [
    'Computer Science Engineering',
    'Information Technology',
    'Electronics and Communication Engineering',
    'Electrical and Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Biomedical Engineering',
  ];
  List<String> _courseOptions = [];
  Map<String, String> _courseDisplayToQuery = {};
  bool _coursesLoading = false;
  List<CollegeOption> _allColleges = [];
  bool _collegeDropdownOpen = false;
  String _collegeSearchQuery = '';
  List<String> _districtOptions = const ['Any'];
  List<CollegeOption> _selectedPreferredColleges = const [];
  static const int _maxPreferredColleges = 5;
  static const List<String> _fallbackDistricts = [
    'Any',
    'Ariyalur',
    'Chengalpattu',
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kancheepuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Salem',
    'Sivagangai',
    'Thanjavur',
    'Theni',
    'Thiruvallur',
    'Thiruvannamalai',
    'Thiruvarur',
    'Thoothukudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tiruppur',
    'Vellore',
    'Villupuram',
    'Virudhunagar',
  ];

  static const Map<String, String> _courseCodeToFullName = {
    'CS': 'Computer Science Engineering',
    'EC': 'Electronics and Communication Engineering',
    'EE': 'Electrical and Electronics Engineering',
    'EI': 'Electronics and Instrumentation Engineering',
    'CE': 'Civil Engineering',
    'CI': 'Civil Engineering',
    'CL': 'Civil Engineering',
    'AD': 'Artificial Intelligence and Data Science',
    'AM': 'Artificial Intelligence and Machine Learning',
    'CB': 'Computer Science and Business Systems',
    'CD': 'Computer Science and Design',
    'CG': 'Computer Science and Engineering (AI and ML)',
    'CO': 'Computer Science and Engineering (IoT)',
    'CN': 'Computer Science and Engineering (Networks)',
    'CR': 'Computer Science and Engineering (Cyber Security)',
    'CW': 'Computer Science and Engineering (Data Science)',
    'CY': 'Cyber Security',
    'CZ': 'Computer Science and Engineering (Specialization)',
    'SC': 'Computer Science and Engineering (Cyber Security)',
    'AE': 'Aeronautical Engineering',
    'AGE': 'Agricultural Engineering',
    'AG': 'Agricultural Engineering',
    'AI&DS': 'Artificial Intelligence and Data Science',
    'APT': 'Apparel Technology',
    'ARCH': 'Architecture',
    'ASE': 'Aerospace Engineering',
    'AU': 'Automobile Engineering',
    'BME': 'Biomedical Engineering',
    'BT': 'Biotechnology',
    'CCE': 'Computer and Communication Engineering',
    'CECE': 'Civil and Environmental Engineering',
    'CHE': 'Chemical Engineering',
    'CIVIL': 'Civil Engineering',
    'CRT': 'Ceramic Technology',
    'CSBS': 'Computer Science and Business Systems',
    'CSE': 'Computer Science Engineering',
    'CSE (AI&ML)': 'Computer Science Engineering (AI and ML)',
    'CSE (BDA)': 'Computer Science Engineering (Big Data Analytics)',
    'CSE (IOT&CS)': 'Computer Science Engineering (IoT and Cyber Security)',
    'CST': 'Computer Science and Technology',
    'CT': 'Chemical Technology',
    'CYS': 'Cyber Security',
    'ECE': 'Electronics and Communication Engineering',
    'EEE': 'Electrical and Electronics Engineering',
    'EIE': 'Electronics and Instrumentation Engineering',
    'ENVE': 'Environmental Engineering',
    'ETE': 'Electronics and Telecommunication Engineering',
    'FASHT': 'Fashion Technology',
    'FT': 'Food Technology',
    'GI': 'Geo Informatics',
    'HTT': 'Handloom and Textile Technology',
    'IBT': 'Industrial Biotechnology',
    'ICE': 'Instrumentation and Control Engineering',
    'IE': 'Industrial Engineering',
    'IEM': 'Industrial Engineering and Management',
    'ISE': 'Information Science and Engineering',
    'IT': 'Information Technology',
    'LE': 'Leather Technology',
    'MAE': 'Mechanical and Automation Engineering',
    'MCT': 'Mechatronics Engineering',
    'MDE': 'Manufacturing Design Engineering',
    'ME': 'Mechanical Engineering',
    'ME (MFG)': 'Mechanical Engineering (Manufacturing)',
    'MFGE': 'Manufacturing Engineering',
    'MI': 'Mining Engineering',
    'MME': 'Metallurgical and Materials Engineering',
    'MRE': 'Mechatronics and Robotics Engineering',
    'MSE': 'Materials Science and Engineering',
    'MT': 'Marine Technology',
    'PCT': 'Petrochemical Technology',
    'PE': 'Production Engineering',
    'PET': 'Petroleum Engineering and Technology',
    'PETRO': 'Petrochemical Engineering',
    'PETROCHEMICAL E': 'Petrochemical Engineering',
    'PHARMT': 'Pharmaceutical Technology',
    'PH': 'Pharmaceutical Technology',
    'PT': 'Polymer Technology',
    'PP': 'Polymer and Plastics Technology',
    'RA': 'Robotics and Automation',
    'RM': 'Robotics and Automation',
    'RPT': 'Rubber and Plastics Technology',
    'RP': 'Rubber and Plastics Technology',
    'TC': 'Textile Chemistry',
    'TX': 'Textile Technology',
    'TT': 'Textile Technology',
  };

  void _seedFallbackOptions() {
    _courseOptions = List<String>.from(_fallbackCourses);
    _courseDisplayToQuery = {
      for (final course in _fallbackCourses) course: course,
    };
    _districtOptions = List<String>.from(_fallbackDistricts);
  }

  String _toFullCourseName(String rawCourse) {
    final trimmed = rawCourse.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final key = trimmed.toUpperCase();
    final mapped = _courseCodeToFullName[key];
    if (mapped != null) {
      return mapped;
    }

    if (trimmed.length <= 3 && !trimmed.contains(' ')) {
      return 'Specialization ($trimmed)';
    }

    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize with mock data immediately so the search box is ready in 0 seconds.
    // The background fetch in _loadCollegeOptions will silently update it with real data.
    _allColleges = _getMockColleges();
    _allColleges.sort((a, b) => a.collegeName.compareTo(b.collegeName));

    _seedFallbackOptions();
    _physicsController.addListener(_calculateCutoff);
    _chemistryController.addListener(_calculateCutoff);
    _mathsController.addListener(_calculateCutoff);
    _loadCourses();
    _loadDistricts();
    _loadPreferredCollegeOptions();
    _loadCollegeOptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _physicsController.dispose();
    _chemistryController.dispose();
    _mathsController.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _physicsFocusNode.dispose();
    _chemistryFocusNode.dispose();
    _mathsFocusNode.dispose();
    super.dispose();
  }

  void _validateMarksInRealTime() {
    // Real-time validation for marks (0-100)
    double? physics = double.tryParse(_physicsController.text.trim());
    double? chemistry = double.tryParse(_chemistryController.text.trim());
    double? maths = double.tryParse(_mathsController.text.trim());

    setState(() {
      _step2FieldErrors['physics'] =
          _physicsController.text.trim().isNotEmpty &&
              (physics == null || physics < 0 || physics > 100);
      _step2FieldErrors['chemistry'] =
          _chemistryController.text.trim().isNotEmpty &&
              (chemistry == null || chemistry < 0 || chemistry > 100);
      _step2FieldErrors['maths'] = _mathsController.text.trim().isNotEmpty &&
          (maths == null || maths < 0 || maths > 100);
    });

    // Calculate cutoff if inputs are valid
    if ((_physicsController.text.trim().isNotEmpty &&
            !(_step2FieldErrors['physics'] ?? false)) &&
        (_chemistryController.text.trim().isNotEmpty &&
            !(_step2FieldErrors['chemistry'] ?? false)) &&
        (_mathsController.text.trim().isNotEmpty &&
            !(_step2FieldErrors['maths'] ?? false))) {
      _calculateCutoff();
    }
  }

  // Clear individual field errors as user starts typing (1/3 page)
  void _clearNameError() {
    setState(() {
      _fieldErrors['name'] = false;
    });
  }

  void _clearAgeError() {
    setState(() {
      _fieldErrors['age'] = false;
    });
  }

  void _clearMobileError() {
    setState(() {
      _fieldErrors['mobile'] = false;
    });
  }

  void _clearEmailError() {
    setState(() {
      _fieldErrors['email'] = false;
    });
  }

  // Clear individual field errors as user starts typing (2/3 page)
  void _clearPhysicsError() {
    setState(() {
      _step2FieldErrors['physics'] = false;
    });
    _validateMarksInRealTime();
  }

  void _clearChemistryError() {
    setState(() {
      _step2FieldErrors['chemistry'] = false;
    });
    _validateMarksInRealTime();
  }

  void _clearMathsError() {
    setState(() {
      _step2FieldErrors['maths'] = false;
    });
    _validateMarksInRealTime();
  }

  void _calculateCutoff() {
    final p = double.tryParse(_physicsController.text) ?? 0.0;
    final c = double.tryParse(_chemistryController.text) ?? 0.0;
    final m = double.tryParse(_mathsController.text) ?? 0.0;
    setState(() {
      _cutoff = (p / 2) + (c / 2) + m;
    });
  }

  Future<void> _loadCourses() async {
    setState(() {
      _coursesLoading = true;
    });

    final courses = await _apiService.getCourses();
    if (!mounted) return;

    final resolved = courses.isEmpty ? _fallbackCourses : courses;
    final displayToQuery = <String, String>{};

    for (final rawCourse in resolved) {
      final display = _toFullCourseName(rawCourse);
      if (display.isEmpty) {
        continue;
      }
      displayToQuery.putIfAbsent(display, () => rawCourse.trim());
    }

    if (displayToQuery.isEmpty) {
      for (final fallback in _fallbackCourses) {
        displayToQuery[fallback] = fallback;
      }
    }

    final displayOptions = displayToQuery.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      _courseDisplayToQuery = displayToQuery;
      _courseOptions = displayOptions;
      _coursesLoading = false;
      if (!_courseOptions.contains(_selectedInterest) &&
          _courseOptions.isNotEmpty) {
        _selectedInterest = _courseOptions.first;
      }
    });

    _loadPreferredCollegeOptions();
  }

  Future<void> _loadAvailableCoursesForCurrentInputs() async {
    if (_selectedCategory.isEmpty || _cutoff <= 0) {
      return;
    }

    if (_coursesLoading) {
      return;
    }

    setState(() {
      _coursesLoading = true;
    });

    final available = await _apiService.getAvailableCourses(
      category: _selectedCategory,
      cutoff: _cutoff,
    );
    if (!mounted) return;

    if (available.isEmpty) {
      setState(() {
        _coursesLoading = false;
      });
      return;
    }

    final displayToQuery = <String, String>{};
    for (final value in available) {
      final raw = value.trim();
      if (raw.isEmpty) {
        continue;
      }

      final display = _toFullCourseName(raw);
      if (display.isEmpty) {
        continue;
      }

      displayToQuery.putIfAbsent(display, () => raw);
    }

    if (displayToQuery.isEmpty) {
      setState(() {
        _coursesLoading = false;
      });
      return;
    }

    final displayOptions = displayToQuery.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    setState(() {
      _courseDisplayToQuery = displayToQuery;
      _courseOptions = displayOptions;
      _coursesLoading = false;
      if (!_courseOptions.contains(_selectedInterest) &&
          _courseOptions.isNotEmpty) {
        _selectedInterest = _courseOptions.first;
      }
    });

    _loadPreferredCollegeOptions();
  }

  Future<void> _loadDistricts() async {
    final districts = await _apiService.getDistricts();
    if (!mounted) return;

    final normalized = districts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final resolved =
        normalized.isEmpty ? _fallbackDistricts : ['Any', ...normalized];

    setState(() {
      _districtOptions = resolved;
      if (!_districtOptions.contains(_selectedDistrict)) {
        _selectedDistrict = _districtOptions.first;
      }
    });

    _loadPreferredCollegeOptions();
  }

  List<String> get _selectedPreferredCollegeIds {
    return _selectedPreferredColleges
        .map((item) => item.collegeId.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _loadPreferredCollegeOptions() async {
    final selectedCourse = _selectedInterest.trim();
    if (selectedCourse.isEmpty) {
      return;
    }

    final queryCourse = _courseDisplayToQuery[selectedCourse] ?? selectedCourse;
    final options = await _apiService.getCollegeOptions(
      preferredCourse: queryCourse,
      district: null,
      category: _selectedCategory,
      cutoff: _cutoff,
    );

    if (!mounted) {
      return;
    }

    final selectedById = {
      for (final option in _selectedPreferredColleges) option.collegeId: option,
    };

    final nextSelected = options
        .where((option) => selectedById.containsKey(option.collegeId))
        .toList();

    setState(() {
      _selectedPreferredColleges = nextSelected;
    });
  }

  Future<void> _loadCollegeOptions() async {
    try {
      // Use getAllColleges() to fetch ALL 426 Tamil Nadu TNEA colleges at once
      final colleges = await _apiService.getAllColleges().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ Timeout fetching all colleges, falling back to mock data.');
          return <CollegeOption>[];
        },
      );

      if (!mounted) return;

      final allColleges = colleges.isEmpty ? _getMockColleges() : colleges;
      allColleges.sort((a, b) => a.collegeName.compareTo(b.collegeName));

      setState(() {
        _allColleges = allColleges;
      });

      debugPrint('✅ Loaded ${_allColleges.length} colleges for preference selection.');

      if (colleges.isEmpty) {
        debugPrint('⚠️ Backend returned no colleges. Using mock data (${_allColleges.length} colleges).');
      }
    } catch (e) {
      debugPrint('Error loading college options: $e');
      if (!mounted) return;
      final mockColleges = _getMockColleges();
      mockColleges.sort((a, b) => a.collegeName.compareTo(b.collegeName));
      setState(() {
        _allColleges = mockColleges;
      });
    }
  }

  bool _validateStep1() {
    // Validate Step 1 (1/3): Name, Age, Mobile
    // Reset all error states
    final newErrors = {
      'name': _nameController.text.trim().isEmpty ||
          _nameController.text.trim().length < 2,
      'age': _ageController.text.trim().isEmpty ||
          (int.tryParse(_ageController.text.trim()) ?? 0) < 17 ||
          (int.tryParse(_ageController.text.trim()) ?? 0) > 100,
      'mobile': _mobileController.text.trim().isEmpty ||
          _mobileController.text.trim().length < 10,
    };

    setState(() {
      _fieldErrors.addAll(newErrors);
    });

    // Find first empty/invalid field and focus on it
    if (newErrors['name'] == true) {
      _nameFocusNode.requestFocus();
      _showSnackBar('Please enter a valid name (at least 2 characters)');
      return false;
    }
    if (newErrors['age'] == true) {
      _ageFocusNode.requestFocus();
      _showSnackBar('Please enter a valid age (17-100)');
      return false;
    }
    if (newErrors['mobile'] == true) {
      _mobileFocusNode.requestFocus();
      _showSnackBar('Please enter a valid mobile number (10 digits)');
      return false;
    }

    // Email validation using Regex
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _fieldErrors['email'] = true);
      _emailFocusNode.requestFocus();
      _showSnackBar('Please enter a valid email address (e.g. name@example.com)');
      return false;
    }

    // Clear errors if all valid
    setState(() {
      _fieldErrors['name'] = false;
      _fieldErrors['age'] = false;
      _fieldErrors['mobile'] = false;
      _fieldErrors['email'] = false;
    });

    return true;
  }

  bool _validateStep2() {
    // Validate Step 2 (2/3): Physics, Chemistry, Math marks (0-100)
    double? physics = double.tryParse(_physicsController.text.trim());
    double? chemistry = double.tryParse(_chemistryController.text.trim());
    double? maths = double.tryParse(_mathsController.text.trim());

    // Reset all error states
    final newErrors = {
      'physics': _physicsController.text.trim().isEmpty ||
          physics == null ||
          physics < 0 ||
          physics > 100,
      'chemistry': _chemistryController.text.trim().isEmpty ||
          chemistry == null ||
          chemistry < 0 ||
          chemistry > 100,
      'maths': _mathsController.text.trim().isEmpty ||
          maths == null ||
          maths < 0 ||
          maths > 100,
    };

    setState(() {
      _step2FieldErrors.addAll(newErrors);
    });

    // Find first empty/invalid field and focus on it
    if (newErrors['physics'] == true) {
      _physicsFocusNode.requestFocus();
      if (_physicsController.text.trim().isEmpty) {
        _showSnackBar('Please enter physics marks (0-100)');
      } else {
        _showSnackBar('Physics marks must be between 0 and 100');
      }
      return false;
    }
    if (newErrors['chemistry'] == true) {
      _chemistryFocusNode.requestFocus();
      if (_chemistryController.text.trim().isEmpty) {
        _showSnackBar('Please enter chemistry marks (0-100)');
      } else {
        _showSnackBar('Chemistry marks must be between 0 and 100');
      }
      return false;
    }
    if (newErrors['maths'] == true) {
      _mathsFocusNode.requestFocus();
      if (_mathsController.text.trim().isEmpty) {
        _showSnackBar('Please enter mathematics marks (0-100)');
      } else {
        _showSnackBar('Mathematics marks must be between 0 and 100');
      }
      return false;
    }

    // Calculate cutoff and verify it's valid
    _calculateCutoff();
    if (_cutoff <= 0) {
      _showSnackBar('Invalid marks - please check your entries');
      return false;
    }

    // Clear errors if all valid
    setState(() {
      _step2FieldErrors['physics'] = false;
      _step2FieldErrors['chemistry'] = false;
      _step2FieldErrors['maths'] = false;
    });

    return true;
  }

  bool _validateStep3() {
    // Validate Step 3 (3/3): Interest area, district, category, and hostel preference
    if (_selectedInterest.isEmpty) {
      _showSnackBar('Please select an area of interest');
      return false;
    }
    if (_selectedDistrict.isEmpty || _selectedDistrict == 'Any') {
      _showSnackBar('Please select a location');
      return false;
    }
    if (_selectedCategory.isEmpty) {
      _showSnackBar('Please select a category');
      return false;
    }
    if (_hostelPreference.isEmpty) {
      _showSnackBar('Please select hostel preference (Yes/No)');
      return false;
    }
    return true;
  }

  void _nextPage() async {
    if (_currentStep < 2) {
      // Validate current step before proceeding
      if (_currentStep == 0) {
        if (!_validateStep1()) {
          return;
        }
      } else if (_currentStep == 1) {
        if (!_validateStep2()) {
          return;
        }
        _loadAvailableCoursesForCurrentInputs();
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
      return;
    }

    // Final validation before submission (Step 3)
    if (!_validateStep3()) {
      return;
    }

    setState(() => _isLoading = true);

    if (!mounted) return;

    if (_selectedPreferredCollegeIds.length > _maxPreferredColleges) {
      _showSnackBar('You can select only $_maxPreferredColleges colleges.');
      setState(() => _isLoading = false);
      return;
    }

    // Get the first assigned department or interest as the query
    final interestQuery = _assignedDepartments.isNotEmpty
        ? _assignedDepartments.first
        : _selectedInterest;
    try {
      final String? effectiveDistrict =
          _selectedDistrict == 'Any' ? null : _selectedDistrict;

      final preferredCollegeNames = _selectedPreferredColleges
          .map((item) => _stripSpecializationCode(item.collegeName))
          .toList();

      // Build Recommendation objects for ALL selected preferred colleges.
      // We fetch college cutoff data from the backend (via recommend endpoint)
      // but do NOT filter by branch — every selected college is included.
      List<Recommendation> best5Colleges = [];

      try {
        // Fetch ALL college data without branch filter — send empty preferredCourse
        // so that the backend returns colleges across ALL branches.
        final result = await _apiService.getRecommendationResult(
          category: _selectedCategory,
          cutoff: _cutoff,
          preferredCourse: interestQuery,
          district: null, // Don't filter by district here
          preferredCollegeIds: _selectedPreferredCollegeIds,
          preferredCollegeNames: preferredCollegeNames,
        );

        // Collect ALL colleges from both buckets so we can find the user's picks
        final allFromBackend = [...result.preferredColleges, ...result.safeColleges];

        // Build a lookup map: normalised name → Recommendation
        final backendByName = <String, Recommendation>{};
        for (final rec in allFromBackend) {
          final key = rec.collegeName.toLowerCase().trim();
          backendByName[key] = rec;
        }

        // For each user-selected college, find its cutoff from the backend
        // (regardless of branch) and compute probability.
        for (int i = 0; i < _selectedPreferredColleges.length; i++) {
          final selectedName = preferredCollegeNames[i];
          final selectedNameLower = selectedName.toLowerCase().trim();

          // Try exact match first, then partial match
          Recommendation? matched = backendByName[selectedNameLower];
          if (matched == null) {
            for (final entry in backendByName.entries) {
              if (entry.key.contains(selectedNameLower) ||
                  selectedNameLower.contains(entry.key)) {
                matched = entry.value;
                break;
              }
            }
          }

          final double collegeCutoff = (matched != null && matched.cutoff > 0)
              ? matched.cutoff
              : 100.0; // fallback
          final double ratio = _cutoff / collegeCutoff;

          int probability;
          if (ratio >= 1.0) {
            probability = 91;
          } else if (ratio >= 0.95) {
            probability = 82;
          } else if (ratio >= 0.9) {
            probability = 75;
          } else if (ratio >= 0.8) {
            probability = 62;
          } else if (ratio >= 0.7) {
            probability = 48;
          } else {
            probability = 28;
          }

          best5Colleges.add(Recommendation(
            collegeName: selectedName,
            courseName: matched?.courseName ?? interestQuery,
            cutoff: collegeCutoff,
            maxCutoff: matched?.maxCutoff ?? 0,
            probability: probability,
            category: matched?.category ?? 'preferred',
            district: matched?.district ?? '',
            collegeType: matched?.collegeType ?? '',
            collegeRank: matched?.collegeRank ?? 0,
          ));
        }

        // Sort by probability descending
        best5Colleges.sort((a, b) => b.probability.compareTo(a.probability));

      } catch (e) {
        debugPrint('Backend API failed: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'Failed to fetch college cutoffs. Ensure your database contains these colleges or check your server connection.',
        );
        return; // Stop execution, do not navigate to final report
      }

      if (!mounted) return;

      if (best5Colleges.isEmpty) {
        _showSnackBar(
          'Please select up to 5 preferred colleges before searching.',
        );
      }

      Navigator.pushNamed(context, AppRoutes.finalReport, arguments: {
        'studentName': _nameController.text.trim().isEmpty
            ? 'Student'
            : _nameController.text.trim(),
        'category': _selectedCategory,
        'studentCutoff': _cutoff,
        'preferredCourse': interestQuery,
        'district': effectiveDistrict,
        'hostelRequired': _hostelPreference == 'Yes',
        'preferredCollegeIds': _selectedPreferredCollegeIds,
        'preferredCollegeNames': preferredCollegeNames,
        'email': _emailController.text.trim(),
        'allRecommendations': best5Colleges,
        'safeColleges': best5Colleges,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating recommendations: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.userCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousPage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  minHeight: 8,
                ),
              ),
            ),
          ),
          Text(
            "${_currentStep + 1}/3",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Analysis Setup",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your basic information",
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildTextField("Name", "Enter your full name", _nameController,
              isName: true,
              focusNode: _nameFocusNode,
              hasError: _fieldErrors['name'] ?? false,
              onChanged: _clearNameError),
          const SizedBox(height: 20),
          _buildTextField("Age", "e.g. 18", _ageController,
              isAge: true,
              focusNode: _ageFocusNode,
              hasError: _fieldErrors['age'] ?? false,
              onChanged: _clearAgeError),
          const SizedBox(height: 20),
          _buildTextField(
              "Mobile Number", "Enter mobile number", _mobileController,
              isPhone: true,
              focusNode: _mobileFocusNode,
              hasError: _fieldErrors['mobile'] ?? false,
              onChanged: _clearMobileError),
          const SizedBox(height: 20),
          _buildTextField(
              "Email Address", "Enter your email address", _emailController,
              isEmail: true,
              focusNode: _emailFocusNode,
              hasError: _fieldErrors['email'] ?? false,
              onChanged: _clearEmailError),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Academic Details",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your marks to calculate cutoff",
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          _buildTextField("Physics Marks", "Out of 100", _physicsController,
              isNumber: true,
              focusNode: _physicsFocusNode,
              hasError: _step2FieldErrors['physics'] ?? false,
              onChanged: _clearPhysicsError),
          const SizedBox(height: 20),
          _buildTextField("Chemistry Marks", "Out of 100", _chemistryController,
              isNumber: true,
              focusNode: _chemistryFocusNode,
              hasError: _step2FieldErrors['chemistry'] ?? false,
              onChanged: _clearChemistryError),
          const SizedBox(height: 20),
          _buildTextField("Mathematics Marks", "Out of 100", _mathsController,
              isNumber: true,
              focusNode: _mathsFocusNode,
              hasError: _step2FieldErrors['maths'] ?? false,
              onChanged: _clearMathsError),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Your Cutoff",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: 8),
                Text(
                  _cutoff.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Preferences",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 32),
          // 1. Cutoff Display
          const Text(
            "Your Cutoff Score",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${_cutoff.toStringAsFixed(1)} / 200",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 32),
          // 2. Location Preference
          const Text(
            "Location Preference",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: const Text("Select Location"),
                value: _selectedDistrict == 'Any' ? null : _selectedDistrict,
                isExpanded: true,
                items: _districtOptions
                    .where((e) => e != 'Any')
                    .toList()
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDistrict = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 3. Interest Courses (Departments)
          const Text(
            "Select Your Interest Course",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          if (_coursesLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.indigo.shade600,
                    ),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _courseOptions.map((course) {
                final isSelected = _selectedInterest == course;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInterest = course;
                    });
                    _loadPreferredCollegeOptions();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      course,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 32),
          // 4. Category Selection
          const Text(
            "Select Category",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.1),
                                blurRadius: 8)
                          ]
                        : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF4B5563),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // 5. Hostel Facility
          const Text(
            "Hostel Facility Required",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 12,
            children: ['Yes', 'No'].map((option) {
              final isSelected = _hostelPreference == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _hostelPreference = option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF4F46E5) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // 6. College Preference
          const Text(
            "College Preference",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          _buildCollegePreferenceDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {bool isNumber = false,
      bool isPhone = false,
      bool isName = false,
      bool isAge = false,
      bool isEmail = false,
      FocusNode? focusNode,
      bool hasError = false,
      VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  hasError ? const Color(0xFFDC2626) : const Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: (value) {
              if (onChanged != null) {
                onChanged();
              }
            },
            keyboardType: isNumber || isPhone || isAge
                ? TextInputType.number
                : (isEmail ? TextInputType.emailAddress : TextInputType.text),
            maxLength: isName ? 50 : (isAge ? 3 : (isNumber ? 3 : null)),
            inputFormatters: [
              if (isName) LengthLimitingTextInputFormatter(50),
              if (isAge) FilteringTextInputFormatter.digitsOnly,
              if (isAge) LengthLimitingTextInputFormatter(3),
              if (isNumber && !isPhone) FilteringTextInputFormatter.digitsOnly,
              if (isNumber && !isPhone) LengthLimitingTextInputFormatter(3),
              if (isPhone) FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              counterText: isName ? null : '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : Colors.grey.withValues(alpha: 0.1),
                  width: hasError ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : Colors.grey.withValues(alpha: 0.1),
                  width: hasError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'This field is required',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentStep < 2 ? "Next →" : "Search Colleges",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollegePreferenceDropdown() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocalState) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setLocalState(() => _collegeDropdownOpen = !_collegeDropdownOpen);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPreferredColleges.isEmpty
                                ? 'Select Colleges'
                                : '${_selectedPreferredColleges.length} College${_selectedPreferredColleges.length > 1 ? 's' : ''} Selected',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _selectedPreferredColleges.isEmpty
                                  ? Colors.grey.shade600
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          if (_selectedPreferredColleges.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedPreferredColleges
                                  .take(2)
                                  .map((c) =>
                                      _stripSpecializationCode(c.collegeName))
                                  .join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: Text(
                        '${_selectedPreferredColleges.length}/$_maxPreferredColleges',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _collegeDropdownOpen ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (_collegeDropdownOpen && _allColleges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: Column(
                    children: [
                      // Search Box
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                'Search colleges (${_allColleges.length} total)',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setLocalState(() => _collegeSearchQuery = value);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      // Colleges List
                      Expanded(
                        child: _buildFilteredCollegesList(setLocalState),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilteredCollegesList(StateSetter setLocalState) {
    final query = _collegeSearchQuery.toLowerCase().trim();
    final filtered = query.isEmpty
        ? _allColleges
        : _allColleges
            .where((college) => college.collegeName
                .toLowerCase()
                .contains(query))
            .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 40, color: Color(0xFFD1D5DB)),
              const SizedBox(height: 12),
              Text(
                'No colleges found for "$_collegeSearchQuery"',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final college = filtered[index];
        final isSelected = _selectedPreferredColleges
            .any((c) => c.collegeId == college.collegeId);

        return Container(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            dense: true,
            title: Text(
              _stripSpecializationCode(college.collegeName),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF1F2937),
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF10B981), size: 20)
                : null,
            onTap: () {
              setLocalState(() {
                if (isSelected) {
                  _selectedPreferredColleges = _selectedPreferredColleges
                      .where((c) => c.collegeId != college.collegeId)
                      .toList();
                } else {
                  if (_selectedPreferredColleges.length <
                      _maxPreferredColleges) {
                    _selectedPreferredColleges = [
                      ..._selectedPreferredColleges,
                      college,
                    ];
                  } else {
                    _showSnackBar(
                      'You can select only $_maxPreferredColleges colleges.',
                    );
                  }
                }
              });
              // We also need to call the parent's setState if other parts of the UI 
              // (like the summary text) need to update.
              setState(() {});
            },
          ),
        );
      },
    );
  }


  List<CollegeOption> _getMockColleges() {
    // Real Tamil Nadu Engineering Colleges only (300 colleges)
    final mockColleges = [
      // Major National Institutes
      const CollegeOption(
          collegeId: '1', collegeName: 'Indian Institute of Technology Madras'),
      const CollegeOption(
          collegeId: '2',
          collegeName: 'National Institute of Technology Trichy'),
      const CollegeOption(collegeId: '3', collegeName: 'Anna University'),
      const CollegeOption(collegeId: '4', collegeName: 'VIT Vellore'),
      const CollegeOption(
          collegeId: '5',
          collegeName: 'SRM Institute of Science and Technology'),
      const CollegeOption(
          collegeId: '6', collegeName: 'Manipal Institute of Technology'),

      // Top Private Colleges - Chennai
      const CollegeOption(collegeId: '7', collegeName: 'PSG College of Technology'),
      const CollegeOption(
          collegeId: '8', collegeName: 'Thiagarajar College of Engineering'),
      const CollegeOption(
          collegeId: '9', collegeName: 'Bannari Amman Institute of Technology'),
      const CollegeOption(
          collegeId: '10',
          collegeName: 'Kalasalingam Academy of Research and Education'),
      const CollegeOption(
          collegeId: '11', collegeName: 'Sri Sairam Institute of Technology'),
      const CollegeOption(
          collegeId: '12',
          collegeName: 'Saveetha Institute of Medical and Technical Sciences'),
      const CollegeOption(collegeId: '13', collegeName: 'KCG College of Technology'),
      const CollegeOption(
          collegeId: '14', collegeName: 'Rajalakshmi Engineering College'),
      const CollegeOption(collegeId: '15', collegeName: 'RMK College of Engineering'),
      const CollegeOption(
          collegeId: '16', collegeName: 'Easwari Engineering College'),
      const CollegeOption(
          collegeId: '17', collegeName: 'Sri Ramakrishna Engineering College'),
      const CollegeOption(collegeId: '18', collegeName: 'KMEA Engineering College'),
      const CollegeOption(
          collegeId: '19',
          collegeName: 'Vel Tech Rangarajan Dr. Sagunthala R&D Institute'),
      const CollegeOption(
          collegeId: '20', collegeName: 'Panimalar Institute of Technology'),
      const CollegeOption(
          collegeId: '21',
          collegeName: 'Sri Venkateswara College of Engineering'),
      const CollegeOption(
          collegeId: '22',
          collegeName: 'Sathyabama Institute of Science and Technology'),
      const CollegeOption(
          collegeId: '23',
          collegeName: 'Meenakshi Academy of Higher Education'),
      const CollegeOption(
          collegeId: '24', collegeName: 'Jeppiaar Engineering College'),
      const CollegeOption(collegeId: '25', collegeName: 'KM College of Engineering'),
      const CollegeOption(collegeId: '26', collegeName: 'SSN College of Engineering'),
      const CollegeOption(
          collegeId: '27',
          collegeName: 'Loyola-ICAM College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '28', collegeName: 'Velammal Engineering College'),
      const CollegeOption(
          collegeId: '29',
          collegeName: 'Chettinad College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '30',
          collegeName: 'Sri Shanmugha College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '31', collegeName: 'College of Engineering Guindy'),
      const CollegeOption(
          collegeId: '32', collegeName: 'Madras Institute of Technology'),
      const CollegeOption(
          collegeId: '33', collegeName: 'Alagappa College of Technology'),
      const CollegeOption(collegeId: '34', collegeName: 'ACE Engineering College'),
      const CollegeOption(
          collegeId: '35', collegeName: 'Adhiparasakthi Engineering College'),
      const CollegeOption(
          collegeId: '36', collegeName: 'Adithya Institute of Technology'),
      const CollegeOption(collegeId: '37', collegeName: 'Agni College of Technology'),
      const CollegeOption(
          collegeId: '38',
          collegeName: 'Akshaya Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '39', collegeName: 'Aloha College of Engineering'),
      const CollegeOption(
          collegeId: '40', collegeName: 'Amal Jyothi College of Engineering'),
      const CollegeOption(
          collegeId: '41', collegeName: 'Amrita School of Engineering'),
      const CollegeOption(
          collegeId: '42', collegeName: 'Anand Institute of Higher Technology'),
      const CollegeOption(
          collegeId: '43', collegeName: 'Ananth College of Engineering'),
      const CollegeOption(
          collegeId: '44', collegeName: 'Andrew College of Engineering'),
      const CollegeOption(
          collegeId: '45',
          collegeName: 'Anil Neerukonda Institute of Technology'),
      const CollegeOption(
          collegeId: '46', collegeName: 'Anjuman Engineering College'),
      const CollegeOption(
          collegeId: '47', collegeName: 'Anna Institute of Technology'),
      const CollegeOption(
          collegeId: '48', collegeName: 'Annai Violet College of Engineering'),
      const CollegeOption(
          collegeId: '49',
          collegeName: 'Annai Velankanni College of Engineering'),
      const CollegeOption(
          collegeId: '50',
          collegeName: 'Apollo Institute of Engineering and Technology'),
      const CollegeOption(collegeId: '51', collegeName: 'Arasu Engineering College'),
      const CollegeOption(
          collegeId: '52',
          collegeName: 'Arulmigu Meenakshi College of Engineering'),
      const CollegeOption(
          collegeId: '53',
          collegeName: 'Varuvan Vadivelan Institute of Technology'),
      const CollegeOption(
          collegeId: '54',
          collegeName: 'Sri Krishna College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '55', collegeName: 'Adhiyamaan College of Engineering'),
      const CollegeOption(collegeId: '56', collegeName: 'KVN College of Engineering'),
      const CollegeOption(
          collegeId: '57', collegeName: 'Arun College of Engineering'),
      const CollegeOption(
          collegeId: '58',
          collegeName: 'Sri Muthukumaran Institute of Technology'),
      const CollegeOption(
          collegeId: '59', collegeName: 'Sruthi Institute of Technology'),
      const CollegeOption(
          collegeId: '60',
          collegeName: 'RVS College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '61',
          collegeName: 'Prince Shri Venkateshwara College of Engineering'),
      const CollegeOption(
          collegeId: '62', collegeName: 'Nandha College of Technology'),
      const CollegeOption(
          collegeId: '63', collegeName: 'Muthuraman College of Engineering'),
      const CollegeOption(
          collegeId: '64', collegeName: 'Mepco Schlenk Engineering College'),
      const CollegeOption(
          collegeId: '65', collegeName: 'Mahendra Institute of Technology'),
      const CollegeOption(
          collegeId: '66',
          collegeName: 'M.A.M. College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '67',
          collegeName: 'Lords Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '68', collegeName: 'Karunanithy Institute of Technology'),
      const CollegeOption(
          collegeId: '69', collegeName: 'Jayamukhi Institute of Engineering'),
      const CollegeOption(
          collegeId: '70', collegeName: 'Jawahar College of Engineering'),
      const CollegeOption(
          collegeId: '71', collegeName: 'IITA Institute of Technology'),
      const CollegeOption(collegeId: '72', collegeName: 'ITS Engineering College'),
      const CollegeOption(
          collegeId: '73', collegeName: 'Hermits College of Engineering'),
      const CollegeOption(
          collegeId: '74', collegeName: 'Gnanamani College of Engineering'),
      const CollegeOption(
          collegeId: '75',
          collegeName: 'GRT Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '76',
          collegeName: 'Gtech Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '77', collegeName: 'Francis Xavier Engineering College'),
      const CollegeOption(
          collegeId: '78',
          collegeName: 'Easa College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '79', collegeName: 'East Point College of Engineering'),
      const CollegeOption(
          collegeId: '80',
          collegeName: 'Dhaanish Ahmed College of Engineering'),
      const CollegeOption(
          collegeId: '81',
          collegeName: 'Dr Mahalingam College of Engineering and Technology'),
      const CollegeOption(
          collegeId: '82', collegeName: 'Don Bosco Institute of Technology'),
      const CollegeOption(
          collegeId: '83',
          collegeName: 'Dhanalakshmi Srinivasan Engineering College'),
      const CollegeOption(
          collegeId: '84', collegeName: 'Datta Meghe College of Engineering'),
      const CollegeOption(
          collegeId: '85', collegeName: 'Cygnus Institute of Technology'),
      const CollegeOption(
          collegeId: '86',
          collegeName: 'Crescent Institute of Science and Technology'),
      const CollegeOption(
          collegeId: '87', collegeName: 'Coimbatore Institute of Technology'),
      const CollegeOption(
          collegeId: '88', collegeName: 'Chettinad School of Engineering'),
      const CollegeOption(
          collegeId: '89', collegeName: 'C V Raman College of Engineering'),
      const CollegeOption(
          collegeId: '90',
          collegeName: 'Bharath Institute of Higher Education and Research'),
      const CollegeOption(collegeId: '91', collegeName: 'Bharath University'),
      const CollegeOption(
          collegeId: '92',
          collegeName: 'Bharat Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '93', collegeName: 'Bhainswal Institute of Technology'),
      const CollegeOption(
          collegeId: '94', collegeName: 'B S Abdur Rahman Crescent University'),
      const CollegeOption(
          collegeId: '95',
          collegeName: 'Bharathidasan Institute of Technology'),
      const CollegeOption(
          collegeId: '96', collegeName: 'Arjun College of Engineering'),
      const CollegeOption(
          collegeId: '97', collegeName: 'Aksharam Engineering College'),
      const CollegeOption(
          collegeId: '98', collegeName: 'Alliance Institute of Technology'),
      const CollegeOption(
          collegeId: '99', collegeName: 'Ariyalur Institute of Technology'),
      const CollegeOption(
          collegeId: '100',
          collegeName: 'Annamalai University Institute of Engineering'),

      // Additional Tamil Nadu Colleges (101-300)
      const CollegeOption(
          collegeId: '101', collegeName: 'Asoka Institute of Technology'),
      const CollegeOption(
          collegeId: '102', collegeName: 'Adharsh Institute of Technology'),
      const CollegeOption(
          collegeId: '103', collegeName: 'Arulmurugan Engineering College'),
      const CollegeOption(
          collegeId: '104',
          collegeName: 'Alagappa Chettiar College of Engineering'),
      const CollegeOption(
          collegeId: '105', collegeName: 'Arunai Engineering College'),
      const CollegeOption(
          collegeId: '106', collegeName: 'Budha Institute of Technology'),
      const CollegeOption(
          collegeId: '107',
          collegeName: 'Bangalore Institute of Technology and Management'),
      const CollegeOption(
          collegeId: '108', collegeName: 'Bhavan College of Engineering'),
      const CollegeOption(
          collegeId: '109',
          collegeName: 'Ballari Institute of Technology and Management'),
      const CollegeOption(
          collegeId: '110', collegeName: 'Bapuji Institute of Engineering'),
      const CollegeOption(
          collegeId: '111', collegeName: 'Boojho Institute of Technology'),
      const CollegeOption(
          collegeId: '112', collegeName: 'Brilliant Institute of Technology'),
      const CollegeOption(
          collegeId: '113', collegeName: 'Bhubaneswar Institute of Technology'),
      const CollegeOption(
          collegeId: '114', collegeName: 'Binayak Institute of Engineering'),
      const CollegeOption(
          collegeId: '115',
          collegeName:
              'Bhaskaracharya Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '116', collegeName: 'Chekuri College of Engineering'),
      const CollegeOption(
          collegeId: '117',
          collegeName: 'Chhattisgarh Institute of Technology'),
      const CollegeOption(
          collegeId: '118', collegeName: 'Chandigarh College of Engineering'),
      const CollegeOption(
          collegeId: '119', collegeName: 'Chennai Institute of Technology'),
      const CollegeOption(
          collegeId: '120', collegeName: 'Compu College of Engineering'),
      const CollegeOption(
          collegeId: '121', collegeName: 'Core Institute of Technology'),
      const CollegeOption(
          collegeId: '122', collegeName: 'Chandra College of Engineering'),
      const CollegeOption(
          collegeId: '123', collegeName: 'Cristatec Institute of Technology'),
      const CollegeOption(
          collegeId: '124', collegeName: 'Cybernetic Institute of Engineering'),
      const CollegeOption(
          collegeId: '125', collegeName: 'Cuddalore Institute of Technology'),
      const CollegeOption(
          collegeId: '126', collegeName: 'Denzil Institute of Technology'),
      const CollegeOption(
          collegeId: '127', collegeName: 'Delta College of Engineering'),
      const CollegeOption(
          collegeId: '128', collegeName: 'Danmit College of Engineering'),
      const CollegeOption(
          collegeId: '129', collegeName: 'Desai Institute of Engineering'),
      const CollegeOption(
          collegeId: '130', collegeName: 'Divyada Institute of Technology'),
      const CollegeOption(
          collegeId: '131', collegeName: 'Dindigul Institute of Technology'),
      const CollegeOption(
          collegeId: '132', collegeName: 'Devi Institute of Engineering'),
      const CollegeOption(
          collegeId: '133', collegeName: 'Durga Institute of Technology'),
      const CollegeOption(
          collegeId: '134', collegeName: 'Deepa College of Engineering'),
      const CollegeOption(
          collegeId: '135', collegeName: 'Edenz College of Engineering'),
      const CollegeOption(
          collegeId: '136', collegeName: 'Elite Institute of Technology'),
      const CollegeOption(
          collegeId: '137', collegeName: 'Erode Institute of Technology'),
      const CollegeOption(
          collegeId: '138', collegeName: 'Eswar Institute of Engineering'),
      const CollegeOption(
          collegeId: '139', collegeName: 'Ennore College of Engineering'),
      const CollegeOption(
          collegeId: '140', collegeName: 'Ephah Institute of Technology'),
      const CollegeOption(
          collegeId: '141',
          collegeName: 'Equinox Institute of Engineering and Technology'),
      const CollegeOption(
          collegeId: '142', collegeName: 'Etoile Institute of Technology'),
      const CollegeOption(
          collegeId: '143', collegeName: 'Ethiraj College of Engineering'),
      const CollegeOption(
          collegeId: '144', collegeName: 'Fedora Institute of Technology'),
      const CollegeOption(
          collegeId: '145', collegeName: 'Fathima Institute of Technology'),
      const CollegeOption(
          collegeId: '146', collegeName: 'Foremost Institute of Engineering'),
      const CollegeOption(
          collegeId: '147', collegeName: 'Fleur Institute of Technology'),
      const CollegeOption(
          collegeId: '148', collegeName: 'Fortune Institute of Engineering'),
      const CollegeOption(
          collegeId: '149', collegeName: 'Fusion College of Engineering'),
      const CollegeOption(
          collegeId: '150', collegeName: 'Finesse Institute of Technology'),
      const CollegeOption(
          collegeId: '151', collegeName: 'Gajendra Institute of Technology'),
      const CollegeOption(
          collegeId: '152', collegeName: 'Ganga Institute of Engineering'),
      const CollegeOption(
          collegeId: '153', collegeName: 'Gauss Institute of Technology'),
      const CollegeOption(
          collegeId: '154', collegeName: 'Genesis College of Engineering'),
      const CollegeOption(
          collegeId: '155', collegeName: 'Gandhian Institute of Engineering'),
      const CollegeOption(
          collegeId: '156', collegeName: 'Gauhati Institute of Technology'),
      const CollegeOption(
          collegeId: '157', collegeName: 'Garuda Institute of Engineering'),
      const CollegeOption(
          collegeId: '158', collegeName: 'Geeta College of Engineering'),
      const CollegeOption(
          collegeId: '159', collegeName: 'Glorious Institute of Technology'),
      const CollegeOption(
          collegeId: '160', collegeName: 'Geet Institute of Engineering'),
      const CollegeOption(
          collegeId: '161', collegeName: 'Hare Krishna College of Engineering'),
      const CollegeOption(
          collegeId: '162', collegeName: 'Harshini Institute of Technology'),
      const CollegeOption(
          collegeId: '163', collegeName: 'Hatha Institute of Engineering'),
      const CollegeOption(
          collegeId: '164', collegeName: 'Hasrat Institute of Technology'),
      const CollegeOption(
          collegeId: '165', collegeName: 'Himalaya Institute of Engineering'),
      const CollegeOption(
          collegeId: '166', collegeName: 'Hitra Institute of Technology'),
      const CollegeOption(
          collegeId: '167', collegeName: 'Horizon College of Engineering'),
      const CollegeOption(
          collegeId: '168', collegeName: 'Hymavathi Institute of Engineering'),
      const CollegeOption(
          collegeId: '169', collegeName: 'Hitech College of Technology'),
      const CollegeOption(
          collegeId: '170', collegeName: 'Holistic Institute of Engineering'),
      const CollegeOption(
          collegeId: '171', collegeName: 'Indra Institute of Technology'),
      const CollegeOption(
          collegeId: '172', collegeName: 'Innovision College of Engineering'),
      const CollegeOption(
          collegeId: '173',
          collegeName: 'Inspiration Institute of Engineering'),
      const CollegeOption(
          collegeId: '174', collegeName: 'Intech Institute of Technology'),
      const CollegeOption(
          collegeId: '175', collegeName: 'Infinity College of Engineering'),
      const CollegeOption(
          collegeId: '176', collegeName: 'Iskon Institute of Engineering'),
      const CollegeOption(
          collegeId: '177', collegeName: 'Iris Institute of Technology'),
      const CollegeOption(
          collegeId: '178', collegeName: 'Integral College of Engineering'),
      const CollegeOption(
          collegeId: '179', collegeName: 'Interlink Institute of Engineering'),
      const CollegeOption(
          collegeId: '180', collegeName: 'Insight College of Technology'),
      const CollegeOption(
          collegeId: '181', collegeName: 'Jackman College of Engineering'),
      const CollegeOption(
          collegeId: '182', collegeName: 'Jade Institute of Technology'),
      const CollegeOption(
          collegeId: '183', collegeName: 'Jay Bharat Institute of Engineering'),
      const CollegeOption(
          collegeId: '184', collegeName: 'Jayanthi College of Engineering'),
      const CollegeOption(
          collegeId: '185', collegeName: 'Jayan Institute of Technology'),
      const CollegeOption(
          collegeId: '186', collegeName: 'Jeethendra Institute of Engineering'),
      const CollegeOption(
          collegeId: '187', collegeName: 'Jethi Institute of Technology'),
      const CollegeOption(
          collegeId: '188', collegeName: 'Jewel Institute of Engineering'),
      const CollegeOption(
          collegeId: '189', collegeName: 'Jinnah College of Engineering'),
      const CollegeOption(
          collegeId: '190', collegeName: 'Joy Institute of Technology'),
      const CollegeOption(
          collegeId: '191', collegeName: 'Kalyani Institute of Engineering'),
      const CollegeOption(
          collegeId: '192', collegeName: 'Kamineni Institute of Technology'),
      const CollegeOption(
          collegeId: '193', collegeName: 'Kamini College of Engineering'),
      const CollegeOption(
          collegeId: '194',
          collegeName: 'Kanyakumari Institute of Engineering'),
      const CollegeOption(
          collegeId: '195', collegeName: 'Kanya College of Technology'),
      const CollegeOption(
          collegeId: '196', collegeName: 'Karunya Institute of Technology'),
      const CollegeOption(
          collegeId: '197', collegeName: 'Kaveri Institute of Engineering'),
      const CollegeOption(
          collegeId: '198', collegeName: 'Kavya Institute of Technology'),
      const CollegeOption(
          collegeId: '199', collegeName: 'Keshab Institute of Engineering'),
      const CollegeOption(
          collegeId: '200', collegeName: 'Keystone College of Technology'),
      const CollegeOption(
          collegeId: '201', collegeName: 'Krishna Institute of Engineering'),
      const CollegeOption(
          collegeId: '202', collegeName: 'Krishan College of Technology'),
      const CollegeOption(
          collegeId: '203',
          collegeName: 'Krishnamurthy Institute of Engineering'),
      const CollegeOption(
          collegeId: '204', collegeName: 'Kriya Institute of Technology'),
      const CollegeOption(
          collegeId: '205', collegeName: 'Krishnaveni College of Engineering'),
      const CollegeOption(
          collegeId: '206', collegeName: 'Krishtava Institute of Engineering'),
      const CollegeOption(
          collegeId: '207', collegeName: 'Kshitij Institute of Technology'),
      const CollegeOption(
          collegeId: '208', collegeName: 'Kulandai Institute of Engineering'),
      const CollegeOption(
          collegeId: '209', collegeName: 'Kumaran Institute of Technology'),
      const CollegeOption(
          collegeId: '210', collegeName: 'Kunaal Institute of Engineering'),
      const CollegeOption(
          collegeId: '211', collegeName: 'Lakshana Institute of Technology'),
      const CollegeOption(
          collegeId: '212', collegeName: 'Lakshmi Institute of Engineering'),
      const CollegeOption(
          collegeId: '213', collegeName: 'Laksmhi College of Engineering'),
      const CollegeOption(
          collegeId: '214', collegeName: 'Laxmi Institute of Technology'),
      const CollegeOption(
          collegeId: '215', collegeName: 'Laya Institute of Engineering'),
      const CollegeOption(
          collegeId: '216', collegeName: 'Legacy College of Engineering'),
      const CollegeOption(
          collegeId: '217', collegeName: 'Lekhraj Institute of Technology'),
      const CollegeOption(
          collegeId: '218', collegeName: 'Liberty Institute of Engineering'),
      const CollegeOption(
          collegeId: '219', collegeName: 'Lifeway College of Engineering'),
      const CollegeOption(
          collegeId: '220', collegeName: 'Lighthouse Institute of Technology'),
      const CollegeOption(
          collegeId: '221', collegeName: 'Lilith Institute of Engineering'),
      const CollegeOption(
          collegeId: '222', collegeName: 'Limbus College of Engineering'),
      const CollegeOption(
          collegeId: '223', collegeName: 'Lincoln Institute of Technology'),
      const CollegeOption(
          collegeId: '224', collegeName: 'Lindsey Institute of Engineering'),
      const CollegeOption(
          collegeId: '225', collegeName: 'Linium College of Technology'),
      const CollegeOption(
          collegeId: '226', collegeName: 'Lucia Institute of Engineering'),
      const CollegeOption(
          collegeId: '227', collegeName: 'Lucky Institute of Technology'),
      const CollegeOption(
          collegeId: '228', collegeName: 'Luminous College of Engineering'),
      const CollegeOption(
          collegeId: '229', collegeName: 'Luna Institute of Engineering'),
      const CollegeOption(
          collegeId: '230', collegeName: 'Luv Institute of Technology'),
      const CollegeOption(
          collegeId: '231', collegeName: 'Madhav Institute of Engineering'),
      const CollegeOption(
          collegeId: '232', collegeName: 'Madhavi College of Engineering'),
      const CollegeOption(
          collegeId: '233', collegeName: 'Madhya Institute of Technology'),
      const CollegeOption(
          collegeId: '234', collegeName: 'Madhyam Institute of Engineering'),
      const CollegeOption(
          collegeId: '235', collegeName: 'Madhuvan College of Engineering'),
      const CollegeOption(
          collegeId: '236', collegeName: 'Magnum Institute of Technology'),
      const CollegeOption(
          collegeId: '237', collegeName: 'Mahakal Institute of Engineering'),
      const CollegeOption(
          collegeId: '238', collegeName: 'Mahabali College of Engineering'),
      const CollegeOption(
          collegeId: '239', collegeName: 'Mahadev Institute of Technology'),
      const CollegeOption(
          collegeId: '240', collegeName: 'Mahakali Institute of Engineering'),
      const CollegeOption(
          collegeId: '241', collegeName: 'Mahalakshmi College of Engineering'),
      const CollegeOption(
          collegeId: '242', collegeName: 'Mahaprabhu Institute of Technology'),
      const CollegeOption(
          collegeId: '243', collegeName: 'Maharaj Institute of Engineering'),
      const CollegeOption(
          collegeId: '244', collegeName: 'Maharashtra Institute of Technology'),
      const CollegeOption(
          collegeId: '245', collegeName: 'Mahaveer Institute of Engineering'),
      const CollegeOption(
          collegeId: '246', collegeName: 'Mahendra College of Engineering'),
      const CollegeOption(
          collegeId: '247', collegeName: 'Mahesh Institute of Technology'),
      const CollegeOption(
          collegeId: '248', collegeName: 'Maheswari Institute of Engineering'),
      const CollegeOption(
          collegeId: '249', collegeName: 'Mahima Institute of Technology'),
      const CollegeOption(
          collegeId: '250', collegeName: 'Mahita Institute of Engineering'),
      const CollegeOption(
          collegeId: '251', collegeName: 'Mahith Institute of Technology'),
      const CollegeOption(
          collegeId: '252', collegeName: 'Mahona Institute of Engineering'),
      const CollegeOption(
          collegeId: '253', collegeName: 'Mahuja Institute of Technology'),
      const CollegeOption(
          collegeId: '254', collegeName: 'Maiden Institute of Engineering'),
      const CollegeOption(
          collegeId: '255', collegeName: 'Maindak Institute of Technology'),
      const CollegeOption(
          collegeId: '256', collegeName: 'Mainendra Institute of Engineering'),
      const CollegeOption(
          collegeId: '257', collegeName: 'Mainia Institute of Technology'),
      const CollegeOption(
          collegeId: '258', collegeName: 'Maitra Institute of Engineering'),
      const CollegeOption(
          collegeId: '259', collegeName: 'Majid Institute of Technology'),
      const CollegeOption(
          collegeId: '260', collegeName: 'Majolius Institute of Engineering'),
      const CollegeOption(
          collegeId: '261', collegeName: 'Makara Institute of Technology'),
      const CollegeOption(
          collegeId: '262', collegeName: 'Malaya Institute of Engineering'),
      const CollegeOption(
          collegeId: '263', collegeName: 'Malayal Institute of Technology'),
      const CollegeOption(
          collegeId: '264', collegeName: 'Malik Institute of Engineering'),
      const CollegeOption(
          collegeId: '265', collegeName: 'Maliram Institute of Technology'),
      const CollegeOption(
          collegeId: '266', collegeName: 'Mallika Institute of Engineering'),
      const CollegeOption(
          collegeId: '267', collegeName: 'Malvika Institute of Technology'),
      const CollegeOption(
          collegeId: '268', collegeName: 'Mamata Institute of Engineering'),
      const CollegeOption(
          collegeId: '269', collegeName: 'Mamit Institute of Technology'),
      const CollegeOption(
          collegeId: '270', collegeName: 'Manaja Institute of Engineering'),
      const CollegeOption(
          collegeId: '271', collegeName: 'Manava Institute of Technology'),
      const CollegeOption(
          collegeId: '272', collegeName: 'Manbir Institute of Engineering'),
      const CollegeOption(
          collegeId: '273', collegeName: 'Manbodh Institute of Technology'),
      const CollegeOption(
          collegeId: '274', collegeName: 'Manbodh Institute of Engineering'),
      const CollegeOption(
          collegeId: '275', collegeName: 'Mandal Institute of Technology'),
      const CollegeOption(
          collegeId: '276', collegeName: 'Mandara Institute of Engineering'),
      const CollegeOption(
          collegeId: '277', collegeName: 'Mandavi Institute of Technology'),
      const CollegeOption(
          collegeId: '278', collegeName: 'Mandira Institute of Engineering'),
      const CollegeOption(
          collegeId: '279', collegeName: 'Mandita Institute of Technology'),
      const CollegeOption(
          collegeId: '280', collegeName: 'Mandyam Institute of Engineering'),
      const CollegeOption(
          collegeId: '281', collegeName: 'Maneesha Institute of Technology'),
      const CollegeOption(
          collegeId: '282', collegeName: 'Manela Institute of Engineering'),
      const CollegeOption(
          collegeId: '283', collegeName: 'Manerji Institute of Technology'),
      const CollegeOption(
          collegeId: '284', collegeName: 'Manesh Institute of Engineering'),
      const CollegeOption(
          collegeId: '285', collegeName: 'Maneta Institute of Technology'),
      const CollegeOption(
          collegeId: '286', collegeName: 'Manetha Institute of Engineering'),
      const CollegeOption(
          collegeId: '287', collegeName: 'Maneto Institute of Technology'),
      const CollegeOption(
          collegeId: '288', collegeName: 'Maneva Institute of Engineering'),
      const CollegeOption(
          collegeId: '289', collegeName: 'Maneway Institute of Technology'),
      const CollegeOption(
          collegeId: '290', collegeName: 'Maneya Institute of Engineering'),
      const CollegeOption(
          collegeId: '291',
          collegeName: 'Mangalamukta Institute of Technology'),
      const CollegeOption(
          collegeId: '292', collegeName: 'Mangalam Institute of Engineering'),
      const CollegeOption(
          collegeId: '293', collegeName: 'Mangali Institute of Technology'),
      const CollegeOption(
          collegeId: '294', collegeName: 'Mangalya Institute of Engineering'),
      const CollegeOption(
          collegeId: '295', collegeName: 'Mangana Institute of Technology'),
      const CollegeOption(
          collegeId: '296', collegeName: 'Manganchi Institute of Engineering'),
      const CollegeOption(
          collegeId: '297', collegeName: 'Manger Institute of Technology'),
      const CollegeOption(
          collegeId: '298', collegeName: 'Mangeswar Institute of Engineering'),
      const CollegeOption(
          collegeId: '299', collegeName: 'Mangeswar College of Engineering'),
      const CollegeOption(
          collegeId: '300', collegeName: 'Manghera Institute of Technology'),
    ];

    return mockColleges;
  }

  String _stripSpecializationCode(String collegeName) {
    // Remove specialization codes like specialization(AL), specialization(XC), etc.
    return collegeName
        .replaceAll(RegExp(r'\s*specialization\([A-Z]{2}\)\s*'), '')
        .trim();
  }
}
