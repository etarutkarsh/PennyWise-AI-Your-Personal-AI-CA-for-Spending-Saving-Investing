package com.pennywise.controller;

import com.pennywise.dto.AchievementDto;
import com.pennywise.dto.LearningProgressDto;
import com.pennywise.service.LearningService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/learning")
@RequiredArgsConstructor
public class LearningController {

    private final LearningService learningService;

    @GetMapping
    public ResponseEntity<List<LearningProgressDto>> getProgress() {
        return ResponseEntity.ok(learningService.getProgress());
    }

    /** Body: { "topic": "salary", "lessonId": "salary_basics", "quizScore": 80 } */
    @PostMapping
    public ResponseEntity<LearningProgressDto> completeLesson(@RequestBody Map<String, Object> body) {
        String topic    = (String) body.get("topic");
        String lessonId = (String) body.get("lessonId");
        Integer score   = body.get("quizScore") != null ? ((Number) body.get("quizScore")).intValue() : null;
        return ResponseEntity.ok(learningService.completeLesson(topic, lessonId, score));
    }

    @GetMapping("/achievements")
    public ResponseEntity<List<AchievementDto>> getAchievements() {
        return ResponseEntity.ok(learningService.getAchievements());
    }

    /** Body: { "code": "onboarding_complete" } — for client-side achievement unlocks */
    @PostMapping("/achievements")
    public ResponseEntity<AchievementDto> unlockAchievement(@RequestBody Map<String, String> body) {
        return ResponseEntity.ok(learningService.unlockAchievementForCurrentUser(body.get("code")));
    }

    @GetMapping("/xp")
    public ResponseEntity<Map<String, Integer>> getTotalXp() {
        return ResponseEntity.ok(Map.of("totalXp", learningService.getTotalXp()));
    }
}
