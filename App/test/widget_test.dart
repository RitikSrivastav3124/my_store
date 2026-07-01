import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_store/presentation/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard renders title and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Total Customers',
            value: '24',
            icon: Icons.groups,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Total Customers'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });
}
