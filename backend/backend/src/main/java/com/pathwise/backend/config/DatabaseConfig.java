package com.pathwise.backend.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DatabaseConfig {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseConfig.class);

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${spring.datasource.username}")
    private String dbUsername;

    @PostConstruct
    public void logDatabaseConnection() {
        logger.info("===============================================================================");
        logger.info("DATABASE CONNECTION INITIALIZED");
        logger.info("URL: {}", dbUrl);
        logger.info("User: {}", dbUsername);
        logger.info("===============================================================================");
    }
}
