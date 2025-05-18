package com.healthcare.appointment.repository;

import com.healthcare.appointment.model.Appointment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Custom repository implementation to handle database schema compatibility in enterprise environments.
 * 
 * This class adapts application code to work with existing database schemas where direct
 * column access may not be possible due to schema restrictions or permissions.
 */
@Repository
public class AppointmentRepositoryCustomImpl implements AppointmentRepositoryCustom {

    private static final Logger log = LoggerFactory.getLogger(AppointmentRepositoryCustomImpl.class);
    
    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Implementation finds all appointments and filters them in-memory based on 
     * date ranges stored in the notes field.
     * 
     * This pattern is used in enterprise environments when the ideal database schema
     * cannot be immediately implemented due to change management processes.
     */
    @Override
    public List<Appointment> findAppointmentsInDateRange(LocalDateTime start, LocalDateTime end) {
        log.info("Finding appointments between {} and {} using schema-compatible approach", start, end);
        
        try {
            // Get all appointments since we can't filter by appointment_datetime in SQL
            TypedQuery<Appointment> query = entityManager.createQuery(
                    "SELECT a FROM Appointment a", Appointment.class);
            
            // Filter in memory based on the appointment date extracted from notes
            return query.getResultList().stream()
                    .filter(appointment -> {
                        LocalDateTime appointmentTime = appointment.getAppointmentDateTime();
                        return appointmentTime != null && 
                               !appointmentTime.isBefore(start) && 
                               !appointmentTime.isAfter(end);
                    })
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Error finding appointments in date range: {}", e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    /**
     * Implementation finds appointments for a specific patient and filters them in-memory
     * based on current time.
     */
    @Override
    public List<Appointment> findUpcomingAppointmentsForPatient(Long patientId, LocalDateTime currentTime) {
        log.info("Finding upcoming appointments for patient {} after {} using schema-compatible approach", 
                patientId, currentTime);
        
        try {
            // Get all appointments for this patient
            TypedQuery<Appointment> query = entityManager.createQuery(
                    "SELECT a FROM Appointment a WHERE a.patientId = :patientId", 
                    Appointment.class);
            query.setParameter("patientId", patientId);
            
            // Filter in memory based on the appointment date extracted from notes
            return query.getResultList().stream()
                    .filter(appointment -> {
                        LocalDateTime appointmentTime = appointment.getAppointmentDateTime();
                        return appointmentTime != null && !appointmentTime.isBefore(currentTime);
                    })
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Error finding upcoming appointments for patient {}: {}", patientId, e.getMessage(), e);
            return new ArrayList<>();
        }
    }
}
