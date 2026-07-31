package com.pennywise.service;

import com.pennywise.dto.DocumentCreateRequest;
import com.pennywise.dto.DocumentDto;
import com.pennywise.entity.Document;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.DocumentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class DocumentService {

    private final DocumentRepository documentRepository;
    private final CurrentUserProvider currentUserProvider;

    public DocumentService(DocumentRepository documentRepository,
                           CurrentUserProvider currentUserProvider) {
        this.documentRepository = documentRepository;
        this.currentUserProvider = currentUserProvider;
    }

    @Transactional
    public DocumentDto create(DocumentCreateRequest request) {
        User user = currentUserProvider.get();

        Document doc = new Document();
        doc.setUserId(user.getId());
        doc.setDocumentType(Document.DocumentType.valueOf(request.getDocumentType().toUpperCase()));
        doc.setOriginalFilename(request.getOriginalFilename());
        doc.setFileUrl(request.getFileUrl());
        doc.setFinancialYear(request.getFinancialYear());
        doc.setTaxCategory(request.getTaxCategory());
        doc.setLinkedTransactionId(request.getLinkedTransactionId());

        return toDto(documentRepository.save(doc));
    }

    public List<DocumentDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        return documentRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream().map(this::toDto).toList();
    }

    public List<DocumentDto> listByType(String documentType) {
        User user = currentUserProvider.get();
        Document.DocumentType type = Document.DocumentType.valueOf(documentType.toUpperCase());
        return documentRepository.findByUserIdAndDocumentTypeOrderByCreatedAtDesc(user.getId(), type)
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public DocumentDto verify(UUID id) {
        Document doc = getOwnedDocument(id);
        doc.setVerificationStatus(Document.VerificationStatus.VERIFIED);
        return toDto(documentRepository.save(doc));
    }

    @Transactional
    public void delete(UUID id) {
        Document doc = getOwnedDocument(id);
        documentRepository.delete(doc);
    }

    private Document getOwnedDocument(UUID id) {
        User user = currentUserProvider.get();
        Document doc = documentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Document not found"));
        if (!doc.getUserId().equals(user.getId())) {
            throw new ResourceNotFoundException("Document not found");
        }
        return doc;
    }

    private DocumentDto toDto(Document doc) {
        return DocumentDto.builder()
                .id(doc.getId())
                .documentType(doc.getDocumentType().name())
                .originalFilename(doc.getOriginalFilename())
                .fileUrl(doc.getFileUrl())
                .ocrStatus(doc.getOcrStatus().name())
                .ocrData(doc.getOcrData())
                .confidenceScore(doc.getConfidenceScore())
                .financialYear(doc.getFinancialYear())
                .taxCategory(doc.getTaxCategory())
                .linkedTransactionId(doc.getLinkedTransactionId())
                .verificationStatus(doc.getVerificationStatus().name())
                .createdAt(doc.getCreatedAt())
                .updatedAt(doc.getUpdatedAt())
                .build();
    }
}
