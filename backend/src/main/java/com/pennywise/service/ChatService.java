package com.pennywise.service;

import com.pennywise.dto.ChatMessageDto;
import com.pennywise.dto.ChatRequest;
import com.pennywise.entity.ChatMessage;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.ChatMessageRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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

    private final ChatMessageRepository chatMessageRepository;
    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;
    private final RestTemplate restTemplate = new RestTemplate();

    public ChatService(ChatMessageRepository chatMessageRepository,
                       TransactionRepository transactionRepository,
                       GoalRepository goalRepository,
                       CurrentUserProvider currentUserProvider) {
        this.chatMessageRepository = chatMessageRepository;
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
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
        YearMonth now = YearMonth.now();
        Instant from = now.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to = now.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);

        List<Transaction> txs = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), from, to);

        BigDecimal totalDebit = txs.stream()
                .filter(t -> t.getDirection().name().equals("DEBIT"))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());
        StringBuilder goalsSummary = new StringBuilder();
        for (Goal g : goals) {
            goalsSummary.append(String.format("- %s: ₹%s saved of ₹%s target by %s\n",
                    g.getName(), g.getCurrentSaved(), g.getTargetAmount(), g.getDeadline()));
        }

        return String.format("""
                You are PennyWise, an AI personal finance Chartered Accountant for Indian users.
                You give honest, practical, compassionate financial advice tailored to Indian financial products
                (SIP, PPF, NPS, ELSS, FD, RD, gold, etc.) and Indian tax rules.
                Keep answers concise (under 150 words), use ₹ for currency.

                User's financial snapshot:
                - Monthly income: ₹%s
                - Spent this month: ₹%s
                - Risk appetite: %s
                - User type: %s
                - Active goals:
                %s

                Answer the user's question using this context when relevant.
                Never give exact stock tips. Always remind the user to consult a SEBI-registered advisor for large decisions.
                """,
                user.getMonthlyIncome() != null ? user.getMonthlyIncome() : "not set",
                totalDebit,
                user.getRiskAppetite() != null ? user.getRiskAppetite() : "medium",
                user.getUserType() != null ? user.getUserType() : "professional",
                goalsSummary.length() > 0 ? goalsSummary : "  No goals set yet\n"
        );
    }

    private String callOpenAi(List<Map<String, String>> messages, String apiKey) {
        if (apiKey == null || apiKey.isBlank()) {
            return "Please add your OpenAI API key in Settings → AI Assistant to enable the chat.";
        }
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            Map<String, Object> body = Map.of(
                    "model", "gpt-4o-mini",
                    "messages", messages,
                    "max_tokens", 400,
                    "temperature", 0.7
            );

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.postForObject(
                    "https://api.openai.com/v1/chat/completions",
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
        } catch (Exception e) {
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
