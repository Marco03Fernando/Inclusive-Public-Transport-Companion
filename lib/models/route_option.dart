enum AccessScore { high, medium }

class RouteOption {
  const RouteOption({
    required this.mode,
    required this.duration,
    required this.transfers,
    required this.accessScore,
    required this.crowding,
  });

  final String mode;
  final String duration;
  final int transfers;
  final AccessScore accessScore;
  final String crowding;
}

class RouteStep {
  const RouteStep({required this.n, required this.text, required this.detail});

  final int n;
  final String text;
  final String detail;
}
