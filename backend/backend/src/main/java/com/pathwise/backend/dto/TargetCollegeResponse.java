package com.pathwise.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TargetCollegeResponse {

    // ⭐ Preferred Colleges Analysis (user-selected colleges)
    private List<PreferredCollegeAnalysis> preferred_colleges_analysis;

    // 🎯 Target Colleges (top 10 by weighted scoring)
    private List<TargetCollege> target_colleges;

    /**
     * ⭐ Preferred College with probability based on cutoff ratio
     * probability = (student_cutoff / college_cutoff) × 100
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PreferredCollegeAnalysis {
        private String college_name;
        private String course;
        private Double your_cutoff;
        private Double college_cutoff;
        private Double probability;
        private String chance_label;
    }

    /**
     * 🎯 Target College with weighted score
     * Score = 0.4×Cutoff + 0.2×Location + 0.15×Course + 0.1×Hostel + 0.1×Category + 0.05×Preference
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TargetCollege {
        private String college_name;
        private String course;
        private Double score;
        private String chance_label;
    }
}
