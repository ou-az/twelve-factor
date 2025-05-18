package com.healthcare.patient.repository;

import com.healthcare.patient.model.Patient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
/**
 * Patient repository using Integer as the ID type to match database schema.
 * This demonstrates an enterprise pattern for adapting to existing database constraints.
 */
public interface PatientRepository extends JpaRepository<Patient, Integer> {
    Optional<Patient> findByMedicalRecordNumber(String medicalRecordNumber);
    Optional<Patient> findByEmail(String email);
}
