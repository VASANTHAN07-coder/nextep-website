package com.pathwise.backend.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.*;
import java.util.*;

@RestController
public class HealthController {

    @Autowired
    private DataSource dataSource;

    @GetMapping("/")
    public Map<String, Object> root() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("service", "pathwise-backend");
        response.put("status", "ok");
        response.put("message", "Pathwise backend is running");
        return response;
    }

    @GetMapping("/api/status")
    public Map<String, Object> apiRoot() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("service", "pathwise-backend");
        response.put("status", "ok");
        response.put("message", "Pathwise API is running");
        return response;
    }

    @GetMapping("/api/schema-check")
    public Map<String, Object> schemaCheck() {
        Map<String, Object> result = new LinkedHashMap<>();
        try (Connection conn = dataSource.getConnection()) {
            result.put("db_connected", true);

            // Check cutoff_history columns
            result.put("cutoff_history_columns", getTableColumns(conn, "cutoff_history"));
            result.put("colleges_columns", getTableColumns(conn, "colleges"));
            result.put("branch_master_columns", getTableColumns(conn, "branch_master"));

            // Row counts
            result.put("cutoff_history_count", getRowCount(conn, "cutoff_history"));
            result.put("colleges_count", getRowCount(conn, "colleges"));
            result.put("branch_master_count", getRowCount(conn, "branch_master"));

        } catch (Exception e) {
            result.put("db_connected", false);
            result.put("error", e.getMessage());
        }
        return result;
    }

    private List<Map<String, String>> getTableColumns(Connection conn, String tableName) throws SQLException {
        List<Map<String, String>> columns = new ArrayList<>();
        String sql = "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = ? ORDER BY ordinal_position";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> col = new LinkedHashMap<>();
                    col.put("name", rs.getString("column_name"));
                    col.put("type", rs.getString("data_type"));
                    columns.add(col);
                }
            }
        }
        return columns;
    }

    private long getRowCount(Connection conn, String tableName) throws SQLException {
        // Use a safe table name (no injection risk since we control the input)
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + tableName)) {
            rs.next();
            return rs.getLong(1);
        }
    }
}
