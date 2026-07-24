package com.pennywise.service;

import com.pennywise.dto.LeaderboardEntryDto;
import com.pennywise.entity.User;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import com.pennywise.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class LeaderboardService {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;

    public LeaderboardService(UserRepository userRepository,
                              TransactionRepository transactionRepository,
                              GoalRepository goalRepository,
                              CurrentUserProvider currentUserProvider) {
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public List<LeaderboardEntryDto> getLeaderboard() {
        User currentUser = currentUserProvider.get();
        List<User> allUsers = userRepository.findAll();

        java.time.ZonedDateTime now = java.time.ZonedDateTime.now(java.time.ZoneOffset.UTC);
        Instant startOfMonth = now.withDayOfMonth(1).toLocalDate()
                .atStartOfDay(java.time.ZoneOffset.UTC).toInstant();
        Instant endOfMonth = now.toInstant();

        // Score = (tx count this month × 2) + (goal count × 5)
        record UserScore(UUID userId, String fullName, int score) {}

        List<UserScore> scores = new ArrayList<>();
        for (User user : allUsers) {
            long txCount = transactionRepository
                    .findByUserIdAndTransactionDateBetween(user.getId(), startOfMonth, endOfMonth)
                    .size();
            long goalCount = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId()).size();
            int score = (int) (txCount * 2 + goalCount * 5);
            scores.add(new UserScore(user.getId(), user.getFullName(), score));
        }

        scores.sort(Comparator.comparingInt(UserScore::score).reversed());

        List<LeaderboardEntryDto> result = new ArrayList<>();
        int currentUserRank = -1;
        LeaderboardEntryDto currentUserEntry = null;

        for (int i = 0; i < scores.size(); i++) {
            UserScore us = scores.get(i);
            int rank = i + 1;
            boolean isCurrent = us.userId().equals(currentUser.getId());
            LeaderboardEntryDto entry = LeaderboardEntryDto.builder()
                    .rank(rank)
                    .displayName(anonymize(us.fullName()))
                    .score(us.score())
                    .grade(gradeFor(us.score()))
                    .isCurrentUser(isCurrent)
                    .build();

            if (isCurrent) {
                currentUserRank = rank;
                currentUserEntry = entry;
            }

            if (rank <= 20) {
                result.add(entry);
            }
        }

        // Append current user if not in top 20
        if (currentUserRank > 20 && currentUserEntry != null) {
            result.add(currentUserEntry);
        }

        return result;
    }

    private String anonymize(String fullName) {
        if (fullName == null || fullName.isBlank()) return "User***";
        String[] parts = fullName.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0];
        }
        String lastName = parts[parts.length - 1];
        String initial = lastName.length() > 0 ? String.valueOf(lastName.charAt(0)) : "";
        return parts[0] + " " + initial + "***";
    }

    private String gradeFor(int score) {
        if (score >= 100) return "S";
        if (score >= 60) return "A";
        if (score >= 30) return "B";
        if (score >= 10) return "C";
        return "D";
    }
}
