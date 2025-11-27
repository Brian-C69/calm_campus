enum SupportContactType { phone, whatsapp, email, other }

class SupportContact {
  const SupportContact({
    this.id,
    required this.name,
    required this.relationship,
    required this.contactType,
    required this.contactValue,
    this.priority = 1,
  });

  final int? id;
  final String name;
  final String relationship;
  final SupportContactType contactType;
  final String contactValue;
  final int priority;

  SupportContact copyWith({
    int? id,
    String? name,
    String? relationship,
    SupportContactType? contactType,
    String? contactValue,
    int? priority,
  }) {
    return SupportContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      contactType: contactType ?? this.contactType,
      contactValue: contactValue ?? this.contactValue,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'contactType': contactType.name,
      'contactValue': contactValue,
      'priority': priority,
    };
  }

  factory SupportContact.fromMap(Map<String, dynamic> map) {
    return SupportContact(
      id: map['id'] as int?,
      name: map['name'] as String,
      relationship: map['relationship'] as String,
      contactType: SupportContactType.values.byName(map['contactType'] as String),
      contactValue: map['contactValue'] as String,
      priority: map['priority'] as int,
    );
  }
}
