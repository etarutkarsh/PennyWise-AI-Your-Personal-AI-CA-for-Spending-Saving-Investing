package com.pennywise.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDto {
    private UUID id;
    private String documentType;
    private String originalFilename;
    private String fileUrl;
    private String ocrStatus;
    private Map<String, Object> ocrData;
    private Double confidenceScore;
    private String financialYear;
    private String taxCategory;
    private UUID linkedTransactionId;
    private String verificationStatus;
    private Instant createdAt;
    private Instant updatedAt;
}
