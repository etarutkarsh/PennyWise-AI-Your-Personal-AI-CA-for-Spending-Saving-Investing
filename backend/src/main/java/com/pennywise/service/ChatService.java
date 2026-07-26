package com.pennywise.service;

import com.pennywise.dto.ChatMessageDto;
import com.pennywise.dto.ChatRequest;
import com.pennywise.entity.ChatMessage;
import com.pennywise.entity.User;
import com.pennywise.repository.ChatMessageRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);

    private final ChatMessageRepository chatMessageRepository;
    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;
    private final FinancialGraphService financialGraphService;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${ai.openai.api-key:}")
    private String configuredApiKey;

    @Value("${ai.openai.base-url:http://host.docker.internal:20128/v1}")
    private String openAiBaseUrl;

    @Value("${ai.openai.model:auto}")
    private String model;

    public ChatService(ChatMessageRepository chatMessageRepository,
                       TransactionRepository transactionRepository,
                       GoalRepository goalRepository,
                       CurrentUserProvider currentUserProvider,
                       FinancialGraphService financialGraphService) {
        this.chatMessageRepository = chatMessageRepository;
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
        this.financialGraphService = financialGraphService;
    }

    public List<ChatMessageDto> getHistory() {
        User user = currentUserProvider.get();
        return chatMessageRepository.findByUserIdOrderByCreatedAtAsc(user.getId())
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public ChatMessageDto chat(ChatRequest request, String openAiKey) {
        User user = currentUserProvider.get();

        // Save user message
        saveMessage(user.getId(), "user", request.getMessage());

        // Build financial context for system prompt
        String systemPrompt = buildSystemPrompt(user);

        // Build conversation history for OpenAI (last 20 messages)
        List<ChatMessage> history = chatMessageRepository
                .findByUserIdOrderByCreatedAtAsc(user.getId());
        int start = Math.max(0, history.size() - 20);
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", systemPrompt));
        for (ChatMessage msg : history.subList(start, history.size())) {
            messages.add(Map.of("role", msg.getRole(), "content", msg.getMessage()));
        }

        // Call OpenAI
        String reply = callOpenAi(messages, openAiKey);

        // Save assistant reply
        ChatMessage saved = saveMessage(user.getId(), "assistant", reply);
        return toDto(saved);
    }

    private String buildSystemPrompt(User user) {
        // Build financial graph and use its compact text as context — fewer tokens, richer signal.
        String graphContext;
        try {
            var graph = financialGraphService.build();
            graphContext = financialGraphService.toPromptContext(graph);
        } catch (Exception e) {
            log.warn("Could not build financial graph for prompt context: {}", e.getMessage());
            graphContext = "No financial data available yet.";
        }

        return String.format("""
                You are PennyWise, an AI personal finance Chartered Accountant for Indian users.
                You give honest, practical, compassionate financial advice tailored to Indian financial products
                (SIP, PPF, NPS, ELSS, FD, RD, gold, etc.) and Indian tax rules.
                Keep answers concise (under 150 words), use ₹ for currency.

                User profile:
                - Monthly income: ₹%s
                - Risk appetite: %s
                - User type: %s

                %s
                Answer the user's question using this context when relevant.
                Never give exact stock tips. Always remind the user to consult a SEBI-registered advisor for large decisions.
                """,
                user.getMonthlyIncome() != null ? user.getMonthlyIncome() : "not set",
                user.getRiskAppetite() != null ? user.getRiskAppetite() : "medium",
                user.getUserType() != null ? user.getUserType() : "professional",
                graphContext
        );
    }

    private String callOpenAi(List<Map<String, String>> messages, String requestKey) {
        // Prefer key sent by client, fall back to server-configured key
        String apiKey = (requestKey != null && !requestKey.isBlank()) ? requestKey : configuredApiKey;

        if (apiKey == null || apiKey.isBlank()) {
            return "No OpenAI API key configured. Add OPENAI_API_KEY to the server .env file.";
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            Map<String, Object> body = Map.of(
                    "model", model,
                    "messages", messages,
                    "max_tokens", 400,
                    "temperature", 0.7
            );

            String endpoint = openAiBaseUrl.replaceAll("/+$", "") + "/chat/completions";
            log.debug("Calling AI endpoint: {}", endpoint);
            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    endpoint,
                    new HttpEntity<>(body, headers),
                    Map.class
            );

            if (response != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                if (choices != null && !choices.isEmpty()) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
                    return (String) message.get("content");
                }
            }
            return "I couldn't get a response right now. Please try again.";
        } catch (HttpClientErrorException e) {
            log.error("OpenAI API error {}: {}", e.getStatusCode(), e.getResponseBodyAsString());
            if (e.getStatusCode().value() == 401) {
                return "Invalid OpenAI API key. Please check the key in your server .env file.";
            }
            if (e.getStatusCode().value() == 429) {
                return "OpenAI rate limit reached. Please wait a moment and try again.";
            }
            return "OpenAI error " + e.getStatusCode().value() + ": " + e.getResponseBodyAsString();
        } catch (Exception e) {
            log.error("Unexpected error calling OpenAI", e);
            return "Something went wrong: " + e.getMessage();
        }
    }

    private ChatMessage saveMessage(java.util.UUID userId, String role, String text) {
        ChatMessage msg = new ChatMessage();
        msg.setUserId(userId);
        msg.setRole(role);
        msg.setMessage(text);
        return chatMessageRepository.save(msg);
    }

    private ChatMessageDto toDto(ChatMessage msg) {
        return ChatMessageDto.builder()
                .id(msg.getId())
                .role(msg.getRole())
                .message(msg.getMessage())
                .createdAt(msg.getCreatedAt())
                .build();
    }
}
