import 'package:construction_estimator_app/models/quotation_item.dart';
import 'package:construction_estimator_app/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard shows overview metrics', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Business overview'), findsOneWidget);
    expect(find.text('Total quotations'), findsOneWidget);
  });

  test('quotation item totals account for quantity', () {
    final item = QuotationItem(
      id: 'item-1',
      name: 'Kitchen cabinets',
      description: 'Base units',
      unit: 'm',
      quantity: 3,
      materialCost: 40,
      labourCost: 20,
      markupPercent: 10,
      discount: 5,
      taxPercent: 15,
    );

    expect(item.directCost, 180);
    expect(item.subtotal, 193);
    expect(item.taxAmount, closeTo(28.95, 0.01));
    expect(item.total, closeTo(221.95, 0.01));
  });
}
