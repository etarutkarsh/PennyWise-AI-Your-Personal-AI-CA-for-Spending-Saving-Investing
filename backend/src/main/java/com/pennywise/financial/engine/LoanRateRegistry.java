package com.pennywise.financial.engine;

import com.pennywise.financial.model.LoanRate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Registry of benchmark interest rates for common Indian loan types.
 * Rates are 2025 market averages compiled from public lender rate cards
 * (SBI, HDFC Bank, ICICI Bank, Axis Bank).
 *
 * Note: Actual rates offered depend on credit score, tenure, lender, and relationship.
 */
@Service
public class LoanRateRegistry {

    private static final LocalDate LAST_UPDATED = LocalDate.of(2025, 1, 1);

    private static final Map<String, LoanRate> RATES = new LinkedHashMap<>();

    static {
        RATES.put("HOME_LOAN", new LoanRate(
                "HOME_LOAN", "Home Loan",
                8.5, 8.0, 9.5,
                "SBI/HDFC/ICICI benchmark MCLR + spread",
                LAST_UPDATED,
                "Tax deduction available under Section 24(b) and 80C on interest and principal"
        ));
        RATES.put("AUTO_LOAN", new LoanRate(
                "AUTO_LOAN", "Auto Loan (Car)",
                9.5, 8.5, 11.0,
                "SBI Car Loan / HDFC Auto",
                LAST_UPDATED,
                "Depreciation reduces asset value from day 1 — budget for total cost of ownership"
        ));
        RATES.put("EDUCATION_LOAN", new LoanRate(
                "EDUCATION_LOAN", "Education Loan",
                8.5, 8.0, 12.0,
                "SBI Scholar Loan / Vidya Lakshmi Portal",
                LAST_UPDATED,
                "Interest is tax-deductible under Section 80E for 8 years; moratorium available during study"
        ));
        RATES.put("PERSONAL_LOAN", new LoanRate(
                "PERSONAL_LOAN", "Personal Loan",
                12.0, 10.5, 18.0,
                "Major bank average for salaried borrowers",
                LAST_UPDATED,
                "Unsecured — high cost. Use only for emergencies or debt consolidation"
        ));
        RATES.put("GOLD_LOAN", new LoanRate(
                "GOLD_LOAN", "Gold Loan",
                9.0, 7.0, 12.0,
                "Muthoot Finance / Manappuram / SBI Gold Loan",
                LAST_UPDATED,
                "Secured against gold jewellery; quick disbursement; repossession risk on default"
        ));
        RATES.put("CREDIT_CARD", new LoanRate(
                "CREDIT_CARD", "Credit Card Revolving Balance",
                36.0, 24.0, 42.0,
                "RBI Annual Statement of Credit Card Charges",
                LAST_UPDATED,
                "Never carry a revolving balance on credit cards — equivalent APR destroys wealth"
        ));
    }

    /**
     * Returns the loan rate for a given loan type key (e.g. "HOME_LOAN").
     *
     * @param loanType uppercase key matching a registered loan type
     * @return Optional containing the LoanRate, empty if not found
     */
    public Optional<LoanRate> getLoanRate(String loanType) {
        return Optional.ofNullable(RATES.get(loanType.toUpperCase()));
    }

    /**
     * Returns all registered loan rates.
     */
    public List<LoanRate> getAllRates() {
        return List.copyOf(RATES.values());
    }

    /**
     * Returns a LoanRate with a custom rate substituted, keeping all other metadata.
     * Useful when the user has a specific rate quote from their lender.
     *
     * @param loanType   the loan type key
     * @param customRate the user's actual quoted rate in percent
     * @return a LoanRate with the custom rate as defaultRatePercent
     */
    public LoanRate withCustomRate(String loanType, double customRate) {
        LoanRate base = RATES.get(loanType.toUpperCase());
        if (base == null) {
            return new LoanRate(loanType, loanType, customRate, customRate, customRate,
                    "User-provided", LocalDate.now(), "Custom rate entered by user");
        }
        return new LoanRate(
                base.loanType(), base.displayName(),
                customRate,           // override
                base.marketMinPercent(),
                base.marketMaxPercent(),
                base.source() + " (custom override)",
                base.lastUpdated(),
                base.notes()
        );
    }
}
