package com.healthcare.patient.service;

import com.healthcare.patient.model.Patient;
import com.healthcare.patient.repository.PatientRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityNotFoundException;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PatientService {

    private final PatientRepository patientRepository;

    public List<Patient> getAllPatients() {
        return patientRepository.findAll();
    }

    public Patient getPatientById(Integer id) {
        return patientRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Patient not found with ID: " + id));
    }

    public Patient getPatientByMedicalRecordNumber(String mrn) {
        return patientRepository.findByMedicalRecordNumber(mrn)
                .orElseThrow(() -> new EntityNotFoundException("Patient not found with MRN: " + mrn));
    }

    @Transactional
    public Patient createPatient(Patient patient) {
        // Additional validation could be added here
        return patientRepository.save(patient);
    }

    @Transactional
    public Patient updatePatient(Integer id, Patient patientDetails) {
        Patient patient = getPatientById(id);
        
        // Update patient details
        patient.setFirstName(patientDetails.getFirstName());
        patient.setLastName(patientDetails.getLastName());
        patient.setDateOfBirth(patientDetails.getDateOfBirth());
        patient.setPhoneNumber(patientDetails.getPhoneNumber());
        patient.setEmail(patientDetails.getEmail());
        patient.setAddress(patientDetails.getAddress());
        
        return patientRepository.save(patient);
    }

    @Transactional
    public void deletePatient(Integer id) {
        Patient patient = getPatientById(id);
        patientRepository.delete(patient);
    }
}
