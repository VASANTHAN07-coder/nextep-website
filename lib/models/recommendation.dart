class Recommendation {
  final String collegeName;
  final String courseName;
  final double cutoff;
  final double maxCutoff;
  final int probability;
  final String category;
  final String? district;
  final String? collegeType;
  final int? collegeRank;

  Recommendation({
    required this.collegeName,
    required this.courseName,
    required this.cutoff,
    this.maxCutoff = 0.0,
    required this.probability,
    required this.category,
    this.district,
    this.collegeType,
    this.collegeRank,
  });

  @Deprecated('Use probability instead.')
  double get score => probability.toDouble();

  @Deprecated('Use category instead.')
  String get recommendationType => category;

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final parsedCategory = _normalizeCategory(_readOptionalString(
      json,
      const ['category', 'recommendation_type', 'recommendationType', 'type'],
    ));

    return Recommendation(
      collegeName: _readString(
        json,
        const ['college_name', 'collegeName', 'name', 'college'],
        fallback: 'Unknown College',
      ),
      courseName: _readString(
        json,
        const ['course_name', 'courseName', 'course', 'branch'],
        fallback: 'Unknown Course',
      ),
      district: _readOptionalString(json, const ['district', 'location']),
      collegeType: _readOptionalString(
        json,
        const ['college_type', 'collegeType', 'type_name'],
      ),
      collegeRank:
          _readInt(json, const ['college_rank', 'collegeRank', 'rank']),
      cutoff: _readDouble(
          json, const ['cutoff', 'closing_cutoff', 'closingCutoff', 'oc_min']),
      maxCutoff: _readDouble(
          json, const ['max_cutoff', 'maxCutoff', 'opening_cutoff', 'openingCutoff']),
      probability: _readProbability(
          json, const ['probability', 'score', 'match_score', 'matchScore']),
      category: parsedCategory ?? 'unknown',
    );
  }

  static String? _normalizeCategory(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return null;
    }

    const aliases = <String, String>{
      'preferred': 'preferred',
      'safe': 'safe',
      'likely': 'safe',
      'safety': 'safe',
      'secure': 'safe',
    };

    final normalized = aliases[value];
    if (normalized != null) {
      return normalized;
    }

    return null;
  }

  static int _readProbability(Map<String, dynamic> source, List<String> keys) {
    var raw = _readDouble(source, keys);
    if (raw >= 0 && raw <= 1) {
      raw = raw * 100;
    }

    final rounded = raw.round();
    if (rounded < 0) {
      return 0;
    }
    if (rounded > 100) {
      return 100;
    }
    return rounded;
  }

  static String? _readOptionalString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final value = _readString(source, keys, fallback: '');
    return value.isEmpty ? null : value;
  }

  static String _readString(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = source[key];
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

  static double _readDouble(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0.0;
  }

  static int? _readInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
