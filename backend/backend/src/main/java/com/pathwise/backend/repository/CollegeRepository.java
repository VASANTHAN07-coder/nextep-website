package com.pathwise.backend.repository;

import com.pathwise.backend.model.College;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CollegeRepository extends JpaRepository<College, Integer> {
    @Query("SELECT DISTINCT c.district FROM College c WHERE c.district IS NOT NULL AND c.district <> '' ORDER BY c.district")
    List<String> findDistinctDistricts();
}
