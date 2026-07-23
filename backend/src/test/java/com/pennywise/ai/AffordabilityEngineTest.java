package com.pennywise.ai;

import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class AffordabilityEngineTest {

    private final AffordabilityEngine engine = new AffordabilityEngine();

    private AffordabilityRequest request(String item, long price) {
        AffordabilityRequest req = new AffordabilityRequest();
        req.setItemName(item);
        req.setPrice(BigDecimal.valueOf(price));
        return req;
    }

    @Test
    void safeToBuy_whenEmergencyFundStaysAboveFloorAndSurplusExists() {
        // income 50,000, expenses 30,000 -> surplus 20,000
        // emergency fund floor = 30,000 * 6 = 180,000; holding 250,000, buying 10,000
        AffordabilityResponse res = engine.evaluate(
                request("Headphones", 10_000),
                BigDecimal.valueOf(50_000),
                BigDecimal.valueOf(30_000),
                BigDecimal.valueOf(250_000));

        assertEquals("SAFE_TO_BUY", res.getVerdict());
        assertNotNull(res.getReason());
    }

    @Test
    void waitAndSave_whenPurchaseWouldBreachEmergencyFundFloor() {
        // emergency fund floor = 30,000 * 6 = 180,000; holding exactly 180,000, buying 90,000
        AffordabilityResponse res = engine.evaluate(
                request("iPhone", 90_000),
                BigDecimal.valueOf(50_000),
                BigDecimal.valueOf(30_000),
                BigDecimal.valueOf(180_000));

        assertEquals("WAIT_AND_SAVE", res.getVerdict());
        assertNotNull(res.getRecommendedWaitMonths());
        assertNotNull(res.getExpectedPurchaseDate());
    }

    @Test
    void dontBuy_whenNoMonthlySurplus() {
        // income 30,000, expenses 32,000 -> no surplus
        AffordabilityResponse res = engine.evaluate(
                request("PS5", 45_000),
                BigDecimal.valueOf(30_000),
                BigDecimal.valueOf(32_000),
                BigDecimal.valueOf(50_000));

        assertEquals("DONT_BUY", res.getVerdict());
    }
}
