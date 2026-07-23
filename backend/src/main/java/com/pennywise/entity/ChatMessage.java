package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "chat_history")
public class ChatMessage extends BaseEntity {

    private UUID userId;

    /** user | assistant */
    @Column(nullable = false)
    private String role;

    @Column(nullable = false, columnDefinition = "text")
    private String message;
}
