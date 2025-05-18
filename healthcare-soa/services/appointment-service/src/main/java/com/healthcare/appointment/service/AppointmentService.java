package com.healthcare.appointment.service;

import com.healthcare.appointment.config.FeatureFlagConfig;
import com.healthcare.appointment.model.Appointment;
import com.healthcare.appointment.model.AppointmentStatus;
import com.healthcare.appointment.repository.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import javax.persistence.EntityNotFoundException;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final RestTemplate restTemplate;
    private final FeatureFlagConfig featureFlags;
    
    @Value("${app.mule-esb-url}")
    private String muleEsbUrl;

    public List<Appointment> getAllAppointments() {
        return appointmentRepository.findAll();
    }

    public Appointment getAppointmentById(Integer id) {
        return appointmentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Appointment not found with ID: " + id));
    }

    public List<Appointment> getAppointmentsByPatientId(Long patientId) {
        // Verify patient existence via ESB (would be implemented in a real system)
        // String patientApiUrl = muleEsbUrl + "/api/patients/" + patientId;
        // restTemplate.getForObject(patientApiUrl, Object.class);
        
        return appointmentRepository.findByPatientId(patientId);
    }

    public List<Appointment> getAppointmentsInDateRange(LocalDateTime start, LocalDateTime end) {
        return appointmentRepository.findAppointmentsInDateRange(start, end);
    }
    
    public List<Appointment> getUpcomingAppointmentsForPatient(Long patientId) {
        return appointmentRepository.findUpcomingAppointmentsForPatient(patientId, LocalDateTime.now());
    }

    @Transactional
    public Appointment createAppointment(Appointment appointment) {
        // Additional validation like checking for scheduling conflicts could be added here
        return appointmentRepository.save(appointment);
    }

    @Transactional
    public Appointment updateAppointment(Integer id, Appointment appointmentDetails) {
        Appointment appointment = getAppointmentById(id);
        
        // Update appointment details
        appointment.setAppointmentType(appointmentDetails.getAppointmentType());
        
        // Conditionally update fields based on schema availability
        if (featureFlags.isAppointmentDatetimeEnabled()) {
            appointment.setAppointmentDateTime(appointmentDetails.getAppointmentDateTime());
        }
        
        appointment.setDoctorName(appointmentDetails.getDoctorName());
        
        if (featureFlags.isDepartmentFieldEnabled()) {
            appointment.setDepartment(appointmentDetails.getDepartment());
        }
        
        if (featureFlags.isNotesFieldEnabled()) {
            appointment.setNotes(appointmentDetails.getNotes());
        }
        
        if (appointmentDetails.getStatus() != null) {
            appointment.setStatus(appointmentDetails.getStatus());
        }
        
        return appointmentRepository.save(appointment);
    }
    
    @Transactional
    public Appointment updateAppointmentStatus(Integer id, AppointmentStatus status) {
        Appointment appointment = getAppointmentById(id);
        appointment.setStatus(status);
        return appointmentRepository.save(appointment);
    }

    @Transactional
    public void deleteAppointment(Integer id) {
        Appointment appointment = getAppointmentById(id);
        appointmentRepository.delete(appointment);
    }
}
