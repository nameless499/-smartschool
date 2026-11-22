class DocumentType {
  final String id;
  final String name;
  final String category;
  final double basePrice;
  final double additionalCopyPrice;
  final bool isActive;
  final String? description;
  final List<String> requiredDocuments; // 👈 NEW FIELD
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentType({
    required this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.additionalCopyPrice,
    required this.isActive,
    this.description,
    this.requiredDocuments = const [], // 👈 Default empty list
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentType.fromJson(Map<String, dynamic> json) {
    final rawRequired = json['required_documents'];
    return DocumentType(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Academic',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      additionalCopyPrice:
          (json['additional_copy_price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      // 👇 Parse required_documents safely
      requiredDocuments: rawRequired != null
          ? List<String>.from(rawRequired as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'base_price': basePrice,
      'additional_copy_price': additionalCopyPrice,
      'is_active': isActive,
      'description': description,
      'required_documents': requiredDocuments, // 👈 Include in payload
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String get formattedPrice => '₱${basePrice.toStringAsFixed(2)}';

  // 👇 Convenience getters
  bool get hasRequirements => requiredDocuments.isNotEmpty;
  int get requirementCount => requiredDocuments.length;
}
