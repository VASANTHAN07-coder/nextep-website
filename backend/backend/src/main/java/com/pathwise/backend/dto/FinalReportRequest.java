package com.pathwise.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class FinalReportRequest {
    private String student_name;
    private String category;
    private Double student_cutoff;
    private String preferred_course;
    private String district;
    private Boolean hostel_required;
    private List<String> preferred_college_ids;
    private List<String> preferred_college_names;
}
