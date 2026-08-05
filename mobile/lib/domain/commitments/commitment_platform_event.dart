import 'package:flutter/foundation.dart';

/// Base class for all commitment domain events.
/// These events feed Digital Twin, Behavioral Engine, Notifications, Monthly Digest.
@immutable
abstract class CommitmentPlatformEvent {
  const CommitmentPlatformEvent({
    required this.occurredAt,
    required this.description,
  });

  final DateTime occurredAt;
  final String description;
}

class CommitmentForecastUpdatedEvent extends CommitmentPlatformEvent {
  const CommitmentForecastUpdatedEvent({
    required super.occurredAt,
    required super.description,
    required this.annualProjection,
    required this.peakMonth,
  });

  final double annualProjection;
  final String peakMonth;
}

class LargeRenewalDetectedEvent extends CommitmentPlatformEvent {
  const LargeRenewalDetectedEvent({
    required super.occurredAt,
    required super.description,
    required this.merchantName,
    required this.amount,
    required this.expectedDate,
    required this.daysUntil,
  });

  final String merchantName;
  final double amount;
  final DateTime expectedDate;
  final int daysUntil;
}

class DuplicateSubscriptionDetectedEvent extends CommitmentPlatformEvent {
  const DuplicateSubscriptionDetectedEvent({
    required super.occurredAt,
    required super.description,
    required this.category,
    required this.count,
    required this.monthlyWastePotential,
  });

  final String category;
  final int count;
  final double monthlyWastePotential;
}

class CommitmentHealthChangedEvent extends CommitmentPlatformEvent {
  const CommitmentHealthChangedEvent({
    required super.occurredAt,
    required super.description,
    required this.fromGrade,
    required this.toGrade,
    required this.scoreDelta,
  });

  final String fromGrade;
  final String toGrade;
  final double scoreDelta;
}

class IncomeStressDetectedEvent extends CommitmentPlatformEvent {
  const IncomeStressDetectedEvent({
    required super.occurredAt,
    required super.description,
    required this.scenarioLabel,
    required this.affordabilityLabel,
  });

  final String scenarioLabel;
  final String affordabilityLabel;
}

class MonthlyReviewGeneratedEvent extends CommitmentPlatformEvent {
  const MonthlyReviewGeneratedEvent({
    required super.occurredAt,
    required super.description,
    required this.monthLabel,
    required this.healthGrade,
  });

  final String monthLabel;
  final String healthGrade;
}
