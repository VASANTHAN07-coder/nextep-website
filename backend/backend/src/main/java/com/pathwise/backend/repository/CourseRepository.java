package com.pathwise.backend.repository;

import com.pathwise.backend.model.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CourseRepository extends JpaRepository<Course, Integer> {
	@Query("SELECT DISTINCT c.courseName FROM Course c WHERE c.courseName IS NOT NULL AND c.courseName <> '' ORDER BY c.courseName")
	List<String> findDistinctCourseNames();
}
