import 'service_model.dart';

class SalonModel {
  final String title;
  final String description;
  final List<ServiceModel> services;

  const SalonModel({
    required this.title,
    required this.description,
    required this.services,
});

}