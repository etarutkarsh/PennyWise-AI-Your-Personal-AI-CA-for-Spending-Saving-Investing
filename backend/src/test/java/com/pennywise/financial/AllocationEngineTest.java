package com.pennywise.financial;

import com.pennywise.financial.engine.AllocationEngine;
import com.pennywise.financial.model.PortfolioAllocation;
import com.pennywise.financial.model.RiskCategory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class AllocationEngineTest {

    private AllocationEngine engine;

    @BeforeEach
    void setUp() {
        engine = new AllocationEngine();
    }

    @Test
    @DisplayName("All risk categories × ages produce allocations that sum to 100")
    void allAllocationsSum100() {
        for (RiskCategory cat : RiskCategory.values()) {
            for (int age : new int[]{25, 35, 45, 55, 65}) {
                PortfolioAllocation alloc = engine.allocate(cat, age);
                double total = alloc.equityPercent() + alloc.debtPercent()
                        + alloc.goldPercent() + alloc.cashPercent()
                        + alloc.internationalEquityPercent();
                assertThat(total)
                    .withFailMessage("Sum != 100 for %s age %d: %.2f", cat, age, total)
                    .isCloseTo(100.0, within(0.1));
            }
        }
    }

    @Test
    @DisplayName("Age 55 has less equity than age 35 for AGGRESSIVE")
    void age55_reducesEquityVsAge35() {
        PortfolioAllocation young = engine.allocate(RiskCategory.AGGRESSIVE, 35);
        PortfolioAllocation old   = engine.allocate(RiskCategory.AGGRESSIVE, 55);
        assertThat(old.equityPercent()).isLessThan(young.equityPercent());
        assertThat(old.debtPercent()).isGreaterThan(young.debtPercent());
    }

    @Test
    @DisplayName("CONSERVATIVE has more debt than AGGRESSIVE at same age")
    void conservativeHasMoreDebtThanAggressive() {
        PortfolioAllocation cons = engine.allocate(RiskCategory.CONSERVATIVE, 35);
        PortfolioAllocation agg  = engine.allocate(RiskCategory.AGGRESSIVE, 35);
        assertThat(cons.debtPercent()).isGreaterThan(agg.debtPercent());
        assertThat(cons.equityPercent()).isLessThan(agg.equityPercent());
    }

    @Test
    @DisplayName("VERY_AGGRESSIVE has highest equity at age 30")
    void veryAggressive_hasHighestEquity() {
        PortfolioAllocation cons = engine.allocate(RiskCategory.CONSERVATIVE, 30);
        PortfolioAllocation veryAgg = engine.allocate(RiskCategory.VERY_AGGRESSIVE, 30);
        assertThat(veryAgg.equityPercent()).isGreaterThan(cons.equityPercent());
    }

    @Test
    @DisplayName("Equity never falls below 10% regardless of age and conservative risk")
    void equity_floorAt10Percent() {
        // Age 80 with CONSERVATIVE should still have >= 10% equity
        PortfolioAllocation alloc = engine.allocate(RiskCategory.CONSERVATIVE, 80);
        assertThat(alloc.equityPercent()).isGreaterThanOrEqualTo(10.0);
    }

    @Test
    @DisplayName("Allocation metadata matches requested risk and age")
    void allocationMetadataIsCorrect() {
        PortfolioAllocation alloc = engine.allocate(RiskCategory.MODERATE, 40);
        assertThat(alloc.basedOnRisk()).isEqualTo(RiskCategory.MODERATE);
        assertThat(alloc.basedOnAge()).isEqualTo(40);
        assertThat(alloc.rationale()).isNotBlank();
    }
}
