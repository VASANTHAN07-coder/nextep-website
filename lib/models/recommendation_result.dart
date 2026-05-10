import 'package:guidex/models/recommendation.dart';

class RecommendationResult {
  final List<Recommendation> preferredColleges;
  final List<Recommendation> safeColleges;

  const RecommendationResult({
    required this.preferredColleges,
    required this.safeColleges,
  });

  const RecommendationResult.empty()
      : preferredColleges = const [],
        safeColleges = const [];

  bool get isEmpty => preferredColleges.isEmpty && safeColleges.isEmpty;

  List<Recommendation> get all => [
        ...preferredColleges,
        ...safeColleges,
      ];
}
