import 'package:equatable/equatable.dart';

class ReportsPage<T> extends Equatable {
  const ReportsPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  @override
  List<Object?> get props => [
    content,
    page,
    size,
    totalElements,
    totalPages,
    first,
    last,
  ];
}
