package com.pathwise.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "colleges")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class College {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "college_id")
    private Integer collegeId;

    @Column(name = "college_name", nullable = false)
    private String collegeName;

    @Column(name = "college_type")
    private String collegeType;

    @Column(name = "district")
    private String district;

    @Column(name = "city")
    private String city;

    @Column(name = "hostel_available")
    private Boolean hostelAvailable;

    @Column(name = "transport_available")
    private Boolean transportAvailable;
}
