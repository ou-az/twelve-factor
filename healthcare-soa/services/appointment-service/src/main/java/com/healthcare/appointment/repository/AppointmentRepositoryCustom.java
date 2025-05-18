package com.healthcare.appointment.repository;

import com.healthcare.appointment.model.Appointment;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Custom repository interface to handle database schema compatibility in enterprise environments.
 * 
 * This pattern is commonly used in large organizations where database schema changes
 * require formal approval processes and application code needs to adapt to existing schemas.
 */
public interface AppointmentRepositoryCustom {
    
    /**
     * Find appointments within a date range.
     * Implementation handles schema compatibility for appointment_datetime column.
     */
    List<Appointment> findAppointmentsInDateRange(LocalDateTime start, LocalDateTime end);
    
    /**
     * Find upcoming appointments for a specific patient.
     * Implementation handles schema compatibility for appointment_datetime column.
     */
    List<Appointment> findUpcomingAppointmentsForPatient(Long patientId, LocalDateTime currentTime);
}
