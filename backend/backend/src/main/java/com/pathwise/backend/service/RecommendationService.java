package com.pathwise.backend.service;

import com.pathwise.backend.dto.CollegeOptionResponse;
import com.pathwise.backend.dto.RecommendationResponse;
import com.pathwise.backend.dto.TargetCollegeResponse;
import com.pathwise.backend.repository.CutoffHistoryRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class RecommendationService {

    private final CutoffHistoryRepository cutoffHistoryRepository;

    public RecommendationService(CutoffHistoryRepository cutoffHistoryRepository) {
        this.cutoffHistoryRepository = cutoffHistoryRepository;
    }

    // ========================================================================
    // MAIN ENDPOINT: Returns both Preferred Analysis + Target Colleges
    // ========================================================================
    @Transactional(readOnly = true)
    public TargetCollegeResponse getTargetColleges(
            Double studentCutoff,
            String community,
            String preferredCity,
            String preferredCourse,
            String hostelRequired,
            List<String> preferredColleges) {

        String comm = community.toLowerCase(Locale.ROOT);
        List<Object[]> rows = cutoffHistoryRepository.findTargetColleges(comm);

        // ⭐ SECTION 1: Preferred Colleges Analysis (probability formula)
        List<TargetCollegeResponse.PreferredCollegeAnalysis> preferredAnalysis = new ArrayList<>();
        Set<String> seenPreferred = new HashSet<>();

        // 🎯 SECTION 2: Target Colleges (weighted scoring)
        Map<String, TargetCollegeResponse.TargetCollege> targetMap = new LinkedHashMap<>();

        // Resolve course aliases for matching
        String prefCourseLower = preferredCourse != null ? preferredCourse.toLowerCase() : "";

        for (Object[] row : rows) {
            String collegeName = String.valueOf(row[0]);
            String branchName = String.valueOf(row[1]);
            Double collegeCutoff = convertToDouble(row[2]);
            String city = String.valueOf(row[3]);
            String district = String.valueOf(row[4]);
            String branchCode = String.valueOf(row[5]);

            if (collegeCutoff == null || collegeCutoff <= 0) continue;

            String branchLower = branchName.toLowerCase();

            // --- Check if this college is in the user's preferred list ---
            boolean isPreferred = false;
            if (preferredColleges != null) {
                for (String pref : preferredColleges) {
                    if (collegeName.toLowerCase().contains(pref.toLowerCase())
                            || pref.toLowerCase().contains(collegeName.toLowerCase())) {
                        isPreferred = true;
                        break;
                    }
                }
            }

            // ⭐ Preferred: ONLY include rows matching the user's chosen course
            if (isPreferred && matchesCourse(prefCourseLower, branchLower)) {
                String dedupeKey = collegeName.toLowerCase();
                if (seenPreferred.add(dedupeKey)) {
                    double probability = calculateProbability(studentCutoff, collegeCutoff);
                    String chanceLabel = getProbabilityLabel(probability);

                    preferredAnalysis.add(TargetCollegeResponse.PreferredCollegeAnalysis.builder()
                            .college_name(collegeName)
                            .course(branchName)
                            .your_cutoff(studentCutoff)
                            .college_cutoff(collegeCutoff)
                            .probability(Math.round(probability * 100.0) / 100.0)
                            .chance_label(chanceLabel)
                            .build());
                }
            }

            // 🎯 Target: only include rows matching preferred course, deduplicate by college
            if (matchesCourse(prefCourseLower, branchLower)) {
                double score = calculateWeightedScore(
                        studentCutoff, collegeCutoff,
                        preferredCity, city, district,
                        preferredCourse, branchCode, branchName,
                        hostelRequired,
                        collegeName, preferredColleges
                );

                String key = collegeName.toLowerCase();
                TargetCollegeResponse.TargetCollege existing = targetMap.get(key);
                double roundedScore = Math.round(score * 100.0) / 100.0;

                if (existing == null || roundedScore > existing.getScore()) {
                    targetMap.put(key, TargetCollegeResponse.TargetCollege.builder()
                            .college_name(collegeName)
                            .course(branchName)
                            .score(roundedScore)
                            .chance_label(getProbabilityLabel(score))
                            .build());
                }
            }
        }

        // Sort preferred by probability DESC
        preferredAnalysis.sort(Comparator.comparing(
                TargetCollegeResponse.PreferredCollegeAnalysis::getProbability).reversed());

        // Sort target by score DESC and take top 10
        List<TargetCollegeResponse.TargetCollege> top10 = targetMap.values().stream()
                .sorted(Comparator.comparing(TargetCollegeResponse.TargetCollege::getScore).reversed())
                .limit(10)
                .collect(Collectors.toList());

        return TargetCollegeResponse.builder()
                .preferred_colleges_analysis(preferredAnalysis)

                .target_colleges(top10)
                .build();
    }

    // ========================================================================
    // FINAL REPORT ENDPOINT: Generates top 5 Safe (Preferred) + 15 Target
    // ========================================================================
    @Transactional(readOnly = true)
    public com.pathwise.backend.dto.FinalReportResponse generateFinalReport(com.pathwise.backend.dto.FinalReportRequest request) {
        String comm = request.getCategory() != null ? request.getCategory().toLowerCase(Locale.ROOT) : "";
        List<Object[]> rows = cutoffHistoryRepository.findTargetColleges(comm);

        Double studentCutoff = request.getStudent_cutoff() != null ? request.getStudent_cutoff() : 0.0;
        String preferredCourse = request.getPreferred_course() != null ? request.getPreferred_course() : "";
        String preferredDistrict = request.getDistrict() != null ? request.getDistrict() : "";
        boolean hostelRequired = request.getHostel_required() != null ? request.getHostel_required() : false;
        List<String> preferredCollegeNames = request.getPreferred_college_names() != null ? request.getPreferred_college_names() : new ArrayList<>();

        List<com.pathwise.backend.dto.FinalReportResponse.SafeCollegeResponse> safeColleges = new ArrayList<>();
        List<com.pathwise.backend.dto.FinalReportResponse.TargetCollegeResponse> targetColleges = new ArrayList<>();

        for (Object[] row : rows) {
            String collegeName = String.valueOf(row[0]);
            String branchName = String.valueOf(row[1]);
            Double collegeCutoff = convertToDouble(row[2]);
            String city = String.valueOf(row[3]);
            String district = String.valueOf(row[4]);
            String branchCode = String.valueOf(row[5]);

            if (collegeCutoff == null || collegeCutoff <= 0) continue;

            // --- Check if preferred ---
            boolean isPreferred = false;
            if (preferredCollegeNames != null) {
                for (String pref : preferredCollegeNames) {
                    if (collegeName.toLowerCase().contains(pref.toLowerCase()) || pref.toLowerCase().contains(collegeName.toLowerCase())) {
                        isPreferred = true;
                        break;
                    }
                }
            }

            // 1. Cutoff Score
            double cutoffProb = calculateProbability(studentCutoff, collegeCutoff);

            // 2. Location Score
            double locationScore = 0.4;
            if (!preferredDistrict.isEmpty() && !preferredDistrict.equalsIgnoreCase("any")) {
                String prefDistLower = preferredDistrict.toLowerCase();
                String actDistLower = district != null ? district.toLowerCase() : "";
                String actCityLower = city != null ? city.toLowerCase() : "";

                if (actCityLower.contains(prefDistLower) || prefDistLower.contains(actCityLower) && !actCityLower.isEmpty()) {
                    locationScore = 1.0; // same city
                } else if (actDistLower.contains(prefDistLower) || prefDistLower.contains(actDistLower) && !actDistLower.isEmpty()) {
                    locationScore = 0.7; // same district
                }
            } else {
                locationScore = 1.0; // No preference -> default to match
            }

            // 3. Interest Score
            double interestScore = 0.2;
            if (!preferredCourse.isEmpty()) {
                String prefCourseLower = preferredCourse.toLowerCase();
                String actBranchLower = branchName != null ? branchName.toLowerCase() : "";
                String actCodeLower = branchCode != null ? branchCode.toLowerCase() : "";

                if (actBranchLower.equals(prefCourseLower) || actCodeLower.equals(prefCourseLower) || matchesCourseAlias(prefCourseLower, actBranchLower)) {
                    interestScore = 1.0; // exactMatch
                }
            } else {
                interestScore = 1.0; // no preference
            }

            // 4. Hostel Score
            double hostelScore = 0.5;
            if (hostelRequired) {
                hostelScore = 1.0; // Assuming available
            }

            // 5. Category Score
            double categoryScore = 1.0; // Fixed as per DB filter

            // 6. Preference Boost
            double prefScore = isPreferred ? 1.0 : 0.0;

            // 🧮 FINAL SCORE FORMULA
            double finalScore = (0.7 * cutoffProb) +
                                (0.1 * locationScore) +
                                (0.1 * interestScore) +
                                (0.05 * hostelScore) +
                                (0.05 * prefScore);

            double probability = finalScore * 100.0;
            probability = Math.round(probability * 10.0) / 10.0;
            String chanceLabel = getProbabilityLabel(probability);

            // ⭐ 1. SAFE COLLEGES (Top 5 based on User Preferences)
            if (isPreferred) {
                safeColleges.add(com.pathwise.backend.dto.FinalReportResponse.SafeCollegeResponse.builder()
                        .collegeName(collegeName)
                        .course(branchName)
                        .collegeCutoff(collegeCutoff)
                        .chanceLabel(chanceLabel)
                        .probability(probability)
                        .district(district)
                        .build());
            }

            // 🎯 2. TARGET COLLEGES (15 with new specific algorithm)
            targetColleges.add(com.pathwise.backend.dto.FinalReportResponse.TargetCollegeResponse.builder()
                    .collegeName(collegeName)
                    .course(branchName)
                    .scorePercentage(probability)
                    .district(district)
                    .chanceLabel(chanceLabel)
                    .cutoffScore(Math.round(cutoffProb * 100.0) / 100.0)
                    .locationScore(Math.round(locationScore * 100.0) / 100.0)
                    .interestScore(Math.round(interestScore * 100.0) / 100.0)
                    .hostelScore(Math.round(hostelScore * 100.0) / 100.0)
                    .categoryScore(Math.round(categoryScore * 100.0) / 100.0)
                    .preferenceBonus(Math.round(prefScore * 100.0) / 100.0)
                    .build());
        }

        // Sort safeColleges by probability descending and limit to 5
        safeColleges.sort(Comparator.comparing(com.pathwise.backend.dto.FinalReportResponse.SafeCollegeResponse::getProbability).reversed());
        List<com.pathwise.backend.dto.FinalReportResponse.SafeCollegeResponse> finalSafeColleges = safeColleges.stream().limit(5).collect(Collectors.toList());

        // Sort targetColleges by finalScore descending and limit to 15
        targetColleges.sort(Comparator.comparing(com.pathwise.backend.dto.FinalReportResponse.TargetCollegeResponse::getScorePercentage).reversed());
        List<com.pathwise.backend.dto.FinalReportResponse.TargetCollegeResponse> finalTargetColleges = targetColleges.stream().limit(15).collect(Collectors.toList());

        return com.pathwise.backend.dto.FinalReportResponse.builder()
                .studentName(request.getStudent_name() != null ? request.getStudent_name() : "Student")
                .studentCutoff(studentCutoff)
                .studentCategory(request.getCategory() != null ? request.getCategory().toUpperCase() : "")
                .preferredCourse(preferredCourse)
                .preferredLocation(preferredDistrict)
                .hostelRequired(hostelRequired)
                .safeColleges(finalSafeColleges)
                .targetColleges(finalTargetColleges)
                .build();
    }

    // ========================================================================
    // ⭐ PREFERRED COLLEGES: Realistic Probability Formula
    // probability = 1 / (1 + exp(-k * diff))
    // ========================================================================
    private double calculateProbability(Double studentCutoff, Double collegeCutoff) {
        double diff = studentCutoff - collegeCutoff;
        double k = 0.6;
        double probability = 1.0 / (1.0 + Math.exp(-k * diff));
        
        if (probability > 0.98) {
            probability = 1.0;
        } else if (probability < 0.02) {
            probability = 0.0;
        }
        return probability;
    }

    private String getProbabilityLabel(double probabilityPercent) {
        if (probabilityPercent >= 85) return "Excellent";
        if (probabilityPercent >= 70) return "Strong";
        if (probabilityPercent >= 50) return "Moderate";
        return "Dream";
    }

    // ========================================================================
    // 🎯 TARGET COLLEGES: Weighted Scoring Model
    // ========================================================================
    private double calculateWeightedScore(
            Double studentCutoff, Double collegeCutoff,
            String preferredCity, String city, String district,
            String preferredCourse, String branchCode, String branchName,
            String hostelRequired,
            String collegeName, List<String> preferredColleges) {

        // 1. Cutoff Match Score (Sigmoid)
        double cutoffProb = calculateProbability(studentCutoff, collegeCutoff);

        // 2. Location Match Score
        double locationScore = 0.4;
        if (preferredCity != null && !preferredCity.isEmpty()) {
            String prefLower = preferredCity.toLowerCase();
            String actCityLower = city != null ? city.toLowerCase() : "";
            String actDistLower = district != null ? district.toLowerCase() : "";

            if (actCityLower.contains(prefLower) || prefLower.contains(actCityLower) && !actCityLower.isEmpty()) {
                locationScore = 1.0;
            } else if (actDistLower.contains(prefLower) || prefLower.contains(actDistLower) && !actDistLower.isEmpty()) {
                locationScore = 0.7;
            }
        } else {
            locationScore = 1.0;
        }

        // 3. Course Interest Match
        double courseScore = 0.2;
        if (preferredCourse != null && !preferredCourse.isEmpty()) {
            String prefCourseLower = preferredCourse.toLowerCase();
            String actBranchLower = branchName != null ? branchName.toLowerCase() : "";
            String actCodeLower = branchCode != null ? branchCode.toLowerCase() : "";

            if (actBranchLower.equals(prefCourseLower) || actCodeLower.equals(prefCourseLower) || matchesCourseAlias(prefCourseLower, actBranchLower)) {
                courseScore = 1.0;
            }
        } else {
            courseScore = 1.0;
        }

        // 4. Hostel Facility Score
        double hostelScore = 0.5;
        if ("yes".equalsIgnoreCase(hostelRequired) || "true".equalsIgnoreCase(hostelRequired)) {
            hostelScore = 1.0;
        }

        // 5. Preference Boost
        double prefScore = 0.0;
        if (preferredColleges != null) {
            for (String pref : preferredColleges) {
                if (collegeName.toLowerCase().contains(pref.toLowerCase())
                        || pref.toLowerCase().contains(collegeName.toLowerCase())) {
                    prefScore = 1.0;
                    break;
                }
            }
        }

        double finalScore = (0.7 * cutoffProb) +
                            (0.1 * locationScore) +
                            (0.1 * courseScore) +
                            (0.05 * hostelScore) +
                            (0.05 * prefScore);

        return finalScore * 100.0;
    }

    /**
     * Check if a branch name matches the user's preferred course.
     * Uses direct substring match + alias expansion.
     */
    private boolean matchesCourse(String prefCourseLower, String branchLower) {
        if (prefCourseLower == null || prefCourseLower.isEmpty()) return true; // no filter
        if (branchLower.contains(prefCourseLower) || prefCourseLower.contains(branchLower)) return true;
        return matchesCourseAlias(prefCourseLower, branchLower);
    }

    /**
     * Match common course abbreviations like CS → Computer Science
     */
    private boolean matchesCourseAlias(String preferred, String actual) {
        Map<String, List<String>> aliases = Map.of(
                "cs", List.of("computer science", "computer", "cse"),
                "cse", List.of("computer science", "computer", "cs"),
                "ece", List.of("electronics and communication", "electronics", "ec"),
                "eee", List.of("electrical and electronics", "electrical", "ee"),
                "mech", List.of("mechanical engineering", "mechanical"),
                "civil", List.of("civil engineering"),
                "it", List.of("information technology"),
                "ai", List.of("artificial intelligence", "ai and"),
                "aids", List.of("artificial intelligence and data science"),
                "bio", List.of("biotechnology", "biomedical", "bio technology")
        );

        List<String> expandedAliases = aliases.getOrDefault(preferred, List.of());
        for (String alias : expandedAliases) {
            if (actual.contains(alias)) return true;
        }
        // Also check reverse
        for (Map.Entry<String, List<String>> entry : aliases.entrySet()) {
            if (entry.getValue().stream().anyMatch(a -> a.contains(preferred))) {
                if (actual.contains(entry.getKey())) return true;
            }
        }
        return false;
    }

    // ========================================================================
    // Legacy /api/recommend endpoint
    // ========================================================================
    @Transactional(readOnly = true)
    public Map<String, List<RecommendationResponse>> getRecommendations(Double userCutoff, String userCommunity) {
        String community = userCommunity.toLowerCase(Locale.ROOT);
        List<Object[]> rows = cutoffHistoryRepository.findTargetColleges(community);

        List<RecommendationResponse> safeColleges = new ArrayList<>();
        List<RecommendationResponse> preferredColleges = new ArrayList<>();

        for (Object[] row : rows) {
            String collegeName = String.valueOf(row[0]);
            String branchName = String.valueOf(row[1]);
            Double cutoff = convertToDouble(row[2]);

            if (cutoff == null) continue;

            RecommendationResponse response = RecommendationResponse.builder()
                    .collegeName(collegeName)
                    .courseName(branchName)
                    .cutoff(cutoff)
                    .category(community.toUpperCase(Locale.ROOT))
                    .build();

            if (cutoff <= userCutoff) {
                safeColleges.add(response);
            } else if (cutoff > userCutoff && cutoff <= userCutoff + 5) {
                preferredColleges.add(response);
            }
        }

        Map<String, List<RecommendationResponse>> result = new LinkedHashMap<>();
        result.put("safe_colleges", safeColleges);
        result.put("preferred_colleges", preferredColleges);

        return result;
    }

    @Transactional(readOnly = true)
    public List<String> getAllCourses() {
        return cutoffHistoryRepository.findDistinctBranches();
    }

    public long getCollegeCount() {
        return cutoffHistoryRepository.count();
    }

    @Transactional(readOnly = true)
    public List<CollegeOptionResponse> getCollegeOptions(String courseName) {
        List<CollegeOptionResponse> options = new ArrayList<>();

        if (courseName == null || courseName.trim().isEmpty()) {
            List<Object[]> allColleges = cutoffHistoryRepository.findAllColleges();
            for (Object[] row : allColleges) {
                Long collegeId = convertToLong(row[0]);
                String collegeName = String.valueOf(row[1]);
                String district = String.valueOf(row[2]);

                options.add(CollegeOptionResponse.builder()
                        .collegeId(collegeId != null ? collegeId.toString() : "")
                        .collegeName(collegeName)
                        .district(district != null ? district : "")
                        .build());
            }
        } else {
            List<Object[]> colleges = cutoffHistoryRepository.findCollegesByCourseName(courseName.trim());
            for (Object[] row : colleges) {
                Long collegeId = convertToLong(row[0]);
                String collegeName = String.valueOf(row[1]);
                String district = String.valueOf(row[2]);

                options.add(CollegeOptionResponse.builder()
                        .collegeId(collegeId != null ? collegeId.toString() : "")
                        .collegeName(collegeName)
                        .district(district != null ? district : "")
                        .build());
            }
        }

        return options;
    }

    private Long convertToLong(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Number) return ((Number) obj).longValue();
        try {
            return Long.parseLong(obj.toString());
        } catch (Exception e) {
            return null;
        }
    }

    private Double convertToDouble(Object obj) {
        if (obj == null) return null;
        if (obj instanceof Number) return ((Number) obj).doubleValue();
        try {
            return Double.parseDouble(obj.toString());
        } catch (Exception e) {
            return null;
        }
    }
}
