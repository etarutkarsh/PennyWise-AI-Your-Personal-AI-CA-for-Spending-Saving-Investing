// Defines FinancialInstrument enum for the partner matching and recommendation engines.

import '../value_objects/risk_level.dart';

/// Financial instruments that can be recommended and linked to partner programs.
enum FinancialInstrument {
  recurringDeposit,
  liquidFund,
  indexFundSip,
  elssSip,
  digitalGold,
  creditCardCashback,
  ppf,
  nps,
  termInsurance,
  healthInsurance;

  String get label => switch (this) {
        FinancialInstrument.recurringDeposit => 'Recurring Deposit',
        FinancialInstrument.liquidFund => 'Liquid Fund',
        FinancialInstrument.indexFundSip => 'Index Fund SIP',
        FinancialInstrument.elssSip => 'ELSS SIP',
        FinancialInstrument.digitalGold => 'Digital Gold',
        FinancialInstrument.creditCardCashback => 'Credit Card Cashback',
        FinancialInstrument.ppf => 'Public Provident Fund (PPF)',
        FinancialInstrument.nps => 'National Pension System (NPS)',
        FinancialInstrument.termInsurance => 'Term Insurance',
        FinancialInstrument.healthInsurance => 'Health Insurance',
      };

  RiskLevel get riskLevel => switch (this) {
        FinancialInstrument.recurringDeposit => RiskLevel.low,
        FinancialInstrument.liquidFund => RiskLevel.low,
        FinancialInstrument.indexFundSip => RiskLevel.medium,
        FinancialInstrument.elssSip => RiskLevel.medium,
        FinancialInstrument.digitalGold => RiskLevel.medium,
        FinancialInstrument.creditCardCashback => RiskLevel.low,
        FinancialInstrument.ppf => RiskLevel.low,
        FinancialInstrument.nps => RiskLevel.medium,
        FinancialInstrument.termInsurance => RiskLevel.low,
        FinancialInstrument.healthInsurance => RiskLevel.low,
      };

  /// Liquidity level: low/medium/high.
  String get liquidityLevel => switch (this) {
        FinancialInstrument.recurringDeposit => 'Low',
        FinancialInstrument.liquidFund => 'High',
        FinancialInstrument.indexFundSip => 'Medium',
        FinancialInstrument.elssSip => 'Low',   // 3-year lock-in
        FinancialInstrument.digitalGold => 'High',
        FinancialInstrument.creditCardCashback => 'High',
        FinancialInstrument.ppf => 'Low',       // 15-year lock-in
        FinancialInstrument.nps => 'Low',       // lock-in until 60
        FinancialInstrument.termInsurance => 'N/A',
        FinancialInstrument.healthInsurance => 'N/A',
      };
}
