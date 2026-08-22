class Contact {
  const Contact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  final String name;
  final String relation;
  final String phone;

  String get initial => name.isNotEmpty ? name[0] : '?';
}
