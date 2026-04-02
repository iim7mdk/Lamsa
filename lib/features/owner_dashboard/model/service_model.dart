class Service {
  final String name;
  final String price;

  Service({
    required this.name,
    required this.price,
  });

  // دالة ثابتة لتحويل خريطة إلى كائن Service
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      name: map['name'] ?? '',
      price: map['price'] ?? '',
    );
  }

  // دالة لتحويل الكائن إلى خريطة
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}