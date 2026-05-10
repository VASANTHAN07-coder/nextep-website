class CollegeOption {
  final String collegeId;
  final String collegeName;
  final String? district;

  const CollegeOption({
    required this.collegeId,
    required this.collegeName,
    this.district,
  });

  factory CollegeOption.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return fallback;
    }

    final districtValue = readString(const ['district']);

    return CollegeOption(
      collegeId: readString(
        const ['college_id', 'collegeId', 'id', 'college_code', 'collegeCode'],
      ),
      collegeName: readString(
        const ['college_name', 'collegeName', 'name'],
        fallback: 'Unknown College',
      ),
      district: districtValue.isEmpty ? null : districtValue,
    );
  }

  String get displayLabel {
    if (district == null || district!.trim().isEmpty) {
      return collegeName;
    }
    return '$collegeName - ${district!.trim()}';
  }
}
