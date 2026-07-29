import 'package:equatable/equatable.dart';

class ReportCategory extends Equatable {
  const ReportCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
  });

  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, description, icon, isActive];
}
