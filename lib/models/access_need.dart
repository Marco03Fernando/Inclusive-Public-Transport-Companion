class AccessNeed {
  const AccessNeed({required this.id, required this.labelKey, required this.checked});

  final String id;
  final String labelKey;
  final bool checked;

  AccessNeed copyWith({bool? checked}) =>
      AccessNeed(id: id, labelKey: labelKey, checked: checked ?? this.checked);
}
