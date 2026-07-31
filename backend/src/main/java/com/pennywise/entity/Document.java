package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "documents")
public class Document extends BaseEntity {

    @Column(nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentType documentType;

    private String originalFilename;

    private String fileUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OcrStatus ocrStatus = OcrStatus.PENDING;

    /** Raw key-value pairs extracted by the OCR pipeline. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> ocrData;

    /** OCR confidence score 0.0–1.0. */
    private Double confidenceScore;

    /** Indian financial year, e.g. "2025-26". */
    private String financialYear;

    /** Tax deduction / income section this document supports. */
    private String taxCategory;

    /** FK to a transaction this document is evidence for (nullable). */
    private UUID linkedTransactionId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VerificationStatus verificationStatus = VerificationStatus.UNVERIFIED;

    // ── Enums ────────────────────────────────────────────────────────────────

    public enum DocumentType {
        FORM_16, FORM_26AS, AIS, RECEIPT, SALARY_SLIP,
        INSURANCE, HOME_LOAN, MUTUAL_FUND, PREVIOUS_ITR, OTHER
    }

    public enum OcrStatus {
        PENDING, PROCESSING, COMPLETED, FAILED
    }

    public enum VerificationStatus {
        UNVERIFIED, VERIFIED, DISPUTED
    }
}
