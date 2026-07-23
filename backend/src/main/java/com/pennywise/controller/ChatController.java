package com.pennywise.controller;

import com.pennywise.dto.ChatMessageDto;
import com.pennywise.dto.ChatRequest;
import com.pennywise.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/ai/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping("/history")
    public ResponseEntity<List<ChatMessageDto>> getHistory() {
        return ResponseEntity.ok(chatService.getHistory());
    }

    @PostMapping
    public ResponseEntity<ChatMessageDto> chat(
            @RequestBody ChatRequest request,
            @RequestHeader(value = "X-OpenAI-Key", required = false) String openAiKey) {
        return ResponseEntity.ok(chatService.chat(request, openAiKey));
    }
}
