package com.pathwise.backend.controller;

import com.pathwise.backend.dto.CollegeOptionResponse;
import com.pathwise.backend.dto.RecommendationResponse;
import com.pathwise.backend.service.RecommendationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class RecommendationController {

    private final RecommendationService recommendationService;

    private static final Set<String> VALID_COMMUNITIES = Set.of("oc", "bc", "bcm", "mbc", "sc", "sca", "st");

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @GetMapping("/courses")
    public ResponseEntity<List<String>> getCourses() {
        return ResponseEntity.ok(recommendationService.getAllCourses());
    }

    @GetMapping("/college-options")
    public ResponseEntity<List<CollegeOptionResponse>> getCollegeOptions(
            @RequestParam(required = false) String preferred_course,
            @RequestParam(required = false) String district,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double cutoff) {
        
        try {
            final String courseName = (preferred_course != null && !preferred_course.trim().isEmpty()) 
                ? preferred_course.trim() 
                : null;
            
            List<CollegeOptionResponse> options = recommendationService.getCollegeOptions(courseName);
            
            // Filter by district if provided
            if (district != null && !district.trim().isEmpty() && !"any".equalsIgnoreCase(district.trim())) {
                options = options.stream()
                    .filter(opt -> opt.getDistrict() != null && opt.getDistrict().equalsIgnoreCase(district.trim()))
                    .collect(java.util.stream.Collectors.toList());
            }
            
            return ResponseEntity.ok(options);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(List.of());
        }
    }

    /**
     * GET /recommend?cutoff=195&community=bc
     */
    @GetMapping("/recommend")
    public ResponseEntity<?> getRecommendations(
            @RequestParam Double cutoff,
            @RequestParam String community) {

        String normalizedCommunity = community.toLowerCase(Locale.ROOT);

        // Validation: If community column does not exist → return error
        if (!VALID_COMMUNITIES.contains(normalizedCommunity)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Invalid community. Valid options: " + VALID_COMMUNITIES));
        }

        Map<String, List<RecommendationResponse>> response =
                recommendationService.getRecommendations(cutoff, normalizedCommunity);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/target-colleges")
    public ResponseEntity<?> getTargetColleges(
            @RequestParam Double cutoff,
            @RequestParam String community,
            @RequestParam(required = false) String preferred_city,
            @RequestParam(required = false) String preferred_course,
            @RequestParam(required = false) String hostel_required,
            @RequestParam(required = false) List<String> preferred_colleges) {

        String normalizedCommunity = community.toLowerCase(Locale.ROOT);
        if (!VALID_COMMUNITIES.contains(normalizedCommunity)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Invalid community. Valid options: " + VALID_COMMUNITIES));
        }

        return ResponseEntity.ok(recommendationService.getTargetColleges(
                cutoff, normalizedCommunity, preferred_city, preferred_course, hostel_required, preferred_colleges));
    }

    @PostMapping("/final-report")
    public ResponseEntity<com.pathwise.backend.dto.FinalReportResponse> generateFinalReport(
            @RequestBody com.pathwise.backend.dto.FinalReportRequest request) {
        
        // Basic validation
        if (request.getCategory() == null || request.getStudent_cutoff() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }

        String normalizedCommunity = request.getCategory().toLowerCase(Locale.ROOT);
        if (!VALID_COMMUNITIES.contains(normalizedCommunity)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }

        return ResponseEntity.ok(recommendationService.generateFinalReport(request));
    }

    @GetMapping("/test-db")
    public ResponseEntity<?> testDb() {
        try {
            long count = recommendationService.getCollegeCount();
            return ResponseEntity.ok(Map.of("status", "connected", "college_count", count));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    /**
     * Updating legacy POST endpoint to use new community-wise logic
     */
    @PostMapping("/recommend")
    public ResponseEntity<Map<String, List<RecommendationResponse>>> recommend(
            @RequestBody Map<String, Object> requestBody) {

        String category = readString(requestBody, "category");
        Double studentCutoff = readDouble(requestBody, "student_cutoff");

        if (category == null || studentCutoff == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "safe_colleges", List.of(),
                    "preferred_colleges", List.of()
            ));
        }

        String normalizedCommunity = category.toLowerCase(Locale.ROOT);
        if (!VALID_COMMUNITIES.contains(normalizedCommunity)) {
            return ResponseEntity.ok(Map.of(
                    "safe_colleges", List.of(),
                    "preferred_colleges", List.of()
            ));
        }

        Map<String, List<RecommendationResponse>> response =
                recommendationService.getRecommendations(studentCutoff, normalizedCommunity);

        return ResponseEntity.ok(response);
    }

    private String readString(Map<String, Object> body, String key) {
        Object value = body.get(key);
        if (value == null) return null;
        String text = value.toString().trim();
        return text.isEmpty() ? null : text;
    }

    private Double readDouble(Map<String, Object> body, String key) {
        Object value = body.get(key);
        if (value instanceof Number) return ((Number) value).doubleValue();
        if (value instanceof String) {
            try {
                return Double.parseDouble(((String) value).trim());
            } catch (NumberFormatException ignored) {}
        }
        return null;
    }
}
