import 'package:equatable/equatable.dart';

class ItemTrend extends Equatable {
  final DateTime? date;
  final String? name;
  final int? totalSales;

  const ItemTrend({
    this.date,
    this.name,
    this.totalSales,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date?.toIso8601String(),
      'name': name,
      'total_sales': totalSales,
    };
  }

  factory ItemTrend.fromJson(Map<String, dynamic> map) {
    return ItemTrend(
      date: map['date'] as DateTime?,
      name: map['name'] as String?,
      totalSales: map['total_sales'] as int?,
    );
  }

  @override
  List<Object?> get props => [date, name, totalSales];
}
