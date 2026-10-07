enum PreflightSeverity { error, warning }

/// A single problem found by a pre-flight check.
class PreflightIssue {
  final PreflightSeverity severity;

  /// Stable machine-readable identifier, e.g. `hashtag.duplicate`.
  final String code;
  final String message;

  const PreflightIssue(this.severity, this.code, this.message);

  const PreflightIssue.error(String code, String message)
      : this(PreflightSeverity.error, code, message);

  const PreflightIssue.warning(String code, String message)
      : this(PreflightSeverity.warning, code, message);

  @override
  String toString() => '${severity.name}: [$code] $message';
}

/// Outcome of a pre-flight run. Errors block scheduling; warnings do not.
class PreflightResult {
  final List<PreflightIssue> issues;

  /// Cleaned-up hashtags (normalized, de-duplicated, invalid ones dropped,
  /// trimmed to the platform maximum). Safe to use as a suggested fix.
  final List<String> cleanedHashtags;

  /// Caption with surrounding/repeated whitespace tidied.
  final String cleanedCaption;

  const PreflightResult({
    required this.issues,
    required this.cleanedHashtags,
    required this.cleanedCaption,
  });

  List<PreflightIssue> get errors =>
      issues.where((i) => i.severity == PreflightSeverity.error).toList();

  List<PreflightIssue> get warnings =>
      issues.where((i) => i.severity == PreflightSeverity.warning).toList();

  bool get hasErrors => issues.any((i) => i.severity == PreflightSeverity.error);

  /// True when the post may be scheduled (warnings are allowed).
  bool get canSchedule => !hasErrors;
}
