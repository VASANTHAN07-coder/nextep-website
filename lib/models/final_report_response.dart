class FinalReportResponse {
  final String studentName;
  final double studentCutoff;
  final String studentCategory;
  final String preferredCourse;
  final String? preferredLocation;
  final bool hostelRequired;
  final List<SafeCollegeResponse> safeColleges;
  final List<TargetCollegeResponse> targetColleges;

  FinalReportResponse({
    required this.studentName,
    required this.studentCutoff,
    required this.studentCategory,
    required this.preferredCourse,
    this.preferredLocation,
    required this.hostelRequired,
    required this.safeColleges,
    required this.targetColleges,
  });

  factory FinalReportResponse.fromJson(Map<String, dynamic> json) {
    return FinalReportResponse(
      studentName: json['studentName'] ?? 'Student',
      studentCutoff: (json['studentCutoff'] as num?)?.toDouble() ?? 0,
      studentCategory: json['studentCategory'] ?? '',
      preferredCourse: json['preferredCourse'] ?? '',
      preferredLocation: json['preferredLocation'],
      hostelRequired: json['hostelRequired'] ?? false,
      safeColleges: (json['safeColleges'] as List?)
              ?.map((c) => SafeCollegeResponse.fromJson(c))
              .toList() ??
          [],
      targetColleges: (json['targetColleges'] as List?)
              ?.map((c) => TargetCollegeResponse.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class SafeCollegeResponse {
  final String collegeName;
  final String course;
  final double collegeCutoff;
  final String? district;
  final double probability;
  final String chanceLabel;

  SafeCollegeResponse({
    required this.collegeName,
    required this.course,
    required this.collegeCutoff,
    this.district,
    required this.probability,
    required this.chanceLabel,
  });

  factory SafeCollegeResponse.fromJson(Map<String, dynamic> json) {
    return SafeCollegeResponse(
      collegeName: json['collegeName'] ?? '',
      course: json['course'] ?? '',
      collegeCutoff: (json['collegeCutoff'] as num?)?.toDouble() ?? 0,
      district: json['district'],
      probability: (json['probability'] as num?)?.toDouble() ?? 0,
      chanceLabel: json['chanceLabel'] ?? '',
    );
  }
}

class TargetCollegeResponse {
  final String collegeName;
  final String course;
  final double scorePercentage;
  final String? district;
  final String chanceLabel;
  final double cutoffScore;
  final double locationScore;
  final double interestScore;
  final double hostelScore;
  final double categoryScore;
  final double preferenceBonus;
  final double cutoff;

  TargetCollegeResponse({
    required this.collegeName,
    required this.course,
    required this.scorePercentage,
    this.district,
    required this.chanceLabel,
    required this.cutoffScore,
    required this.locationScore,
    required this.interestScore,
    required this.hostelScore,
    required this.categoryScore,
    required this.preferenceBonus,
    required this.cutoff,
  });

  factory TargetCollegeResponse.fromJson(Map<String, dynamic> json) {
    return TargetCollegeResponse(
      collegeName: json['collegeName'] ?? '',
      course: json['course'] ?? '',
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0,
      district: json['district'],
      chanceLabel: json['chanceLabel'] ?? '',
      cutoffScore: (json['cutoffScore'] as num?)?.toDouble() ?? 0,
      locationScore: (json['locationScore'] as num?)?.toDouble() ?? 0,
      interestScore: (json['interestScore'] as num?)?.toDouble() ?? 0,
      hostelScore: (json['hostelScore'] as num?)?.toDouble() ?? 0,
      categoryScore: (json['categoryScore'] as num?)?.toDouble() ?? 0,
      preferenceBonus: (json['preferenceBonus'] as num?)?.toDouble() ?? 0,
      cutoff: (json['cutoff'] as num?)?.toDouble() ?? 0,
    );
  }
}
