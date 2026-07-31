package com.pennywise.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.UUID;

@Data
public class DocumentCreateRequest {

    @NotBlank
    private String documentType; // FORM_16 | FORM_26AS | AIS | RECEIPT | SALARY_SLIP | INSURANCE | HOME_LOAN | MUTUAL_FUND | PREVIOUS_ITR | OTHER

    private String originalFilename;

    private String fileUrl;

    private String financialYear; // e.g. "2025-26"

    private String taxCategory;

    private UUID linkedTransactionId;
}
