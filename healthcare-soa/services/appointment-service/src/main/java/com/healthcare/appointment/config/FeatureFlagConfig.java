package com.healthcare.appointment.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;

/**
 * Feature flag configuration to handle database schema mismatches in enterprise environments.
 * This pattern is commonly used in large organizations where database schema changes
 * require separate approvals and may lag behind application deployments.
 */
@Component
@ConfigurationProperties(prefix = "app.features")
@Data
public class FeatureFlagConfig {
    
    /**
     * Flag indicating if appointment datetime column is available in the database.
     * This allows the application to gracefully handle cases where database schema
     * updates are pending or require separate approvals in enterprise environments.
     */
    private boolean appointmentDatetimeEnabled = false;
    
    /**
     * Flag indicating if department column is available in the database.
     */
    private boolean departmentFieldEnabled = false;
    
    /**
     * Flag indicating if notes field is available in the database.
     */
    private boolean notesFieldEnabled = true;
}
