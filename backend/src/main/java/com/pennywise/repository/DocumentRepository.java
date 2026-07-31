package com.pennywise.repository;

import com.pennywise.entity.Document;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DocumentRepository extends JpaRepository<Document, UUID> {

    List<Document> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Document> findByUserIdAndDocumentTypeOrderByCreatedAtDesc(
            UUID userId, Document.DocumentType documentType);

    List<Document> findByUserIdAndFinancialYearOrderByCreatedAtDesc(
            UUID userId, String financialYear);
}
