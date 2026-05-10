class StudentProfile {
  StudentProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.cutoff,
    required this.category,
    required this.preferredCourse,
  });

  final String uid;
  final String name;
  final String email;
  final double cutoff;
  final String category;
  final String preferredCourse;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'cutoff': cutoff,
      'category': category,
      'preferred_course': preferredCourse,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> map) {
    return StudentProfile(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      cutoff: _toDouble(map['cutoff']),
      category: (map['category'] ?? '').toString(),
      preferredCourse: (map['preferred_course'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
