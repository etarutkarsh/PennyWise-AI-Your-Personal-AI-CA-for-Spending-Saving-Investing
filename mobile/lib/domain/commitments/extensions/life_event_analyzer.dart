/// Stub — blocked on Life Event domain (Phase AA).
abstract interface class LifeEventCommitmentAdvisor {
  /// Returns commitments that should be reviewed given upcoming life events.
  /// LifeEventProfile will be added when the Life Event domain is built.
  List<String> reviewCandidates();
}
