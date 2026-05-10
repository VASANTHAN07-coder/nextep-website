package com.pathwise.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "cutoff_history")
@IdClass(CutoffHistoryId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CutoffHistory {

    @Id
    @Column(name = "college_id")
    private String collegeId;

    @Id
    @Column(name = "branch_name")
    private String branchName;

    @Column(name = "college_name")
    private String collegeName;

    @Column(name = "oc")
    private Double oc;

    @Column(name = "bc")
    private Double bc;

    @Column(name = "bcm")
    private Double bcm;

    @Column(name = "mbc")
    private Double mbc;

    @Column(name = "sc")
    private Double sc;

    @Column(name = "sca")
    private Double sca;

    @Column(name = "st")
    private Double st;
}
