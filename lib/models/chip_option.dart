/// A selectable chip's id + label key, used for plan filters, report
/// targets, and report condition types — all rendered by [ChipSelector].
class ChipOption {
  const ChipOption({required this.id, required this.labelKey});

  final String id;
  final String labelKey;
}
