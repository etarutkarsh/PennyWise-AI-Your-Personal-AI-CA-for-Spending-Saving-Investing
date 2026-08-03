package com.pennywise.controller;

import com.pennywise.domain.decision.DecisionResponse;
import com.pennywise.mapper.DecisionResponseMapper;
import com.pennywise.service.TodayDecisionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/decisions")
public class TodayDecisionController {

    private static final Logger log = LoggerFactory.getLogger(TodayDecisionController.class);

    private final TodayDecisionService todayDecisionService;
    private final DecisionResponseMapper decisionResponseMapper;

    public TodayDecisionController(
            TodayDecisionService todayDecisionService,
            DecisionResponseMapper decisionResponseMapper) {
        this.todayDecisionService = todayDecisionService;
        this.decisionResponseMapper = decisionResponseMapper;
    }

    @GetMapping("/today")
    public ResponseEntity<DecisionResponse> getToday() {
        return ResponseEntity.ok(
                decisionResponseMapper.fromToday(todayDecisionService.compute()));
    }

    /**
     * Records a decision lifecycle transition (viewed / accepted / rejected / executed / observed / reviewed / learned).
     * Phase 1 stub: persists nothing yet; simply acknowledges the event so the mobile client's
     * fire-and-forget recording succeeds. A future phase will wire this into the Decision Memory
     * Engine so the Digital Twin can learn from user reactions to recommendations.
     */
    @PostMapping("/{decisionId}/lifecycle")
    public ResponseEntity<Map<String, String>> recordLifecycleEvent(
            @PathVariable String decisionId,
            @RequestBody(required = false) Map<String, String> body) {
        String state = body == null ? null : body.get("state");
        log.info("Decision lifecycle event received: decisionId={}, state={}", decisionId, state);
        return ResponseEntity.ok(Map.of(
                "status", "accepted",
                "decisionId", decisionId,
                "state", state == null ? "" : state
        ));
    }
}
