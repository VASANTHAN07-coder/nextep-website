package com.pathwise.backend.repository;

import com.pathwise.backend.model.CutoffHistory;
import com.pathwise.backend.model.CutoffHistoryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CutoffHistoryRepository extends JpaRepository<CutoffHistory, CutoffHistoryId> {

    @Query(value = "SELECT " +
            "ch.college_name, " +
            "ch.branch_name, " +
            "CASE " +
            "  WHEN CAST(:community AS TEXT) = 'oc' THEN ch.oc " +
            "  WHEN CAST(:community AS TEXT) = 'bc' THEN ch.bc " +
            "  WHEN CAST(:community AS TEXT) = 'bcm' THEN ch.bcm " +
            "  WHEN CAST(:community AS TEXT) = 'mbc' THEN ch.mbc " +
            "  WHEN CAST(:community AS TEXT) = 'sc' THEN ch.sc " +
            "  WHEN CAST(:community AS TEXT) = 'sca' THEN ch.sca " +
            "  WHEN CAST(:community AS TEXT) = 'st' THEN ch.st " +
            "END AS cutoff, " +
            "COALESCE(c.city, '') AS city, " +
            "COALESCE(c.district, '') AS district, " +
            "ch.branch_name AS branch_code " +
            "FROM cutoff_history ch " +
            "LEFT JOIN colleges c ON ch.college_name = c.college_name " +
            "WHERE (CASE " +
            "  WHEN CAST(:community AS TEXT) = 'oc' THEN ch.oc " +
            "  WHEN CAST(:community AS TEXT) = 'bc' THEN ch.bc " +
            "  WHEN CAST(:community AS TEXT) = 'bcm' THEN ch.bcm " +
            "  WHEN CAST(:community AS TEXT) = 'mbc' THEN ch.mbc " +
            "  WHEN CAST(:community AS TEXT) = 'sc' THEN ch.sc " +
            "  WHEN CAST(:community AS TEXT) = 'sca' THEN ch.sca " +
            "  WHEN CAST(:community AS TEXT) = 'st' THEN ch.st " +
            "END) IS NOT NULL",
            nativeQuery = true)
    List<Object[]> findTargetColleges(
            @Param("community") String community
    );

    @Query(value = "SELECT DISTINCT bm.branch_name FROM branch_master bm ORDER BY bm.branch_name", nativeQuery = true)
    List<String> findDistinctBranches();

    @Query(value = "SELECT DISTINCT " +
            "ch.college_id, " +
            "ch.college_name, " +
            "COALESCE(c.district, '') AS district " +
            "FROM cutoff_history ch " +
            "LEFT JOIN colleges c ON ch.college_name = c.college_name " +
            "WHERE LOWER(ch.branch_name) LIKE LOWER(CONCAT('%', CAST(:courseName AS TEXT), '%')) " +
            "ORDER BY ch.college_name", nativeQuery = true)
    List<Object[]> findCollegesByCourseName(
            @Param("courseName") String courseName
    );

    @Query(value = "SELECT DISTINCT " +
            "c.college_id, " +
            "c.college_name, " +
            "c.district " +
            "FROM colleges c " +
            "ORDER BY c.college_name", nativeQuery = true)
    List<Object[]> findAllColleges();
}
