class Contact {
  const Contact({
    this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });

  final String? id;
  final String name;
  final String relation;
  final String phone;

  String get initial => name.isNotEmpty ? name[0] : '?';

  Contact copyWith({String? id, String? name, String? relation, String? phone}) => Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        phone: phone ?? this.phone,
      );

  Map<String, dynamic> toMap() => {'name': name, 'relation': relation, 'phone': phone};

  factory Contact.fromMap(String id, Map<String, dynamic> map) => Contact(
        id: id,
        name: map['name'] as String? ?? '',
        relation: map['relation'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
      );
}
