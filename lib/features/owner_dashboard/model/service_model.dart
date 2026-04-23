class Service {
  final String id;
  final String name;
  final double price;

  Service({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Service.fromMap(String id, Map<String, dynamic> map) {
    final rawPrice = map['price'];

    return Service(
      id: id,
      name: map['name']?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}