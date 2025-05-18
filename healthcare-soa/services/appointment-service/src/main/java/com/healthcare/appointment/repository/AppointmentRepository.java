package com.healthcare.appointment.repository;

import com.healthcare.appointment.model.Appointment;
import com.healthcare.appointment.model.AppointmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Integer>, AppointmentRepositoryCustom {
    
    List<Appointment> findByPatientId(Long patientId);
    
    List<Appointment> findByDoctorName(String doctorName);
    
    List<Appointment> findByStatus(AppointmentStatus status);
    
    // Custom implementation methods moved to AppointmentRepositoryCustom
    // to handle schema compatibility in enterprise environments where
    // database changes require formal approval processes
}
