import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/widgets/graph_widget.dart';
import 'package:esp32monitoring/models/measurement_data.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  group('GraphWidget Tests', () {
    testWidgets('should display chart with temperature data',
        (WidgetTester tester) async {
      // Arrange
      final measurements = [
        MeasurementData(
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          humidity: 65.0,
          temperature: 25.0,
          type: 'data',
        ),
        MeasurementData(
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          humidity: 67.0,
          temperature: 26.0,
          type: 'data',
        ),
        MeasurementData(
          timestamp: DateTime.now(),
          humidity: 70.0,
          temperature: 27.0,
          type: 'data',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphWidget(
              data: measurements,
              title: 'Temperature Chart',
              yAxisLabel: 'Temperature (°C)',
              valueSelector: (measurement) => measurement.temperature,
              minY: 20.0,
              maxY: 30.0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Temperature Chart'), findsOneWidget);
    });

    testWidgets('should display chart with humidity data',
        (WidgetTester tester) async {
      // Arrange
      final measurements = [
        MeasurementData(
          timestamp: DateTime.now(),
          humidity: 65.0,
          temperature: 25.0,
          type: 'data',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphWidget(
              data: measurements,
              title: 'Humidity Chart',
              yAxisLabel: 'Humidity (%)',
              valueSelector: (measurement) => measurement.humidity,
              minY: 0.0,
              maxY: 100.0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Humidity Chart'), findsOneWidget);
    });

    testWidgets('should handle empty data gracefully',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphWidget(
              data: [],
              title: 'Empty Chart',
              yAxisLabel: 'Temperature (°C)',
              valueSelector: (measurement) => measurement.temperature,
              minY: 0.0,
              maxY: 50.0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Empty Chart'), findsOneWidget);
    });

    testWidgets('should handle null values in measurements',
        (WidgetTester tester) async {
      // Arrange
      final measurements = [
        MeasurementData(
          timestamp: DateTime.now(),
          humidity: null,
          temperature: null,
          type: 'temp_event',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphWidget(
              data: measurements,
              title: 'Test Chart',
              yAxisLabel: 'Temperature (°C)',
              valueSelector: (measurement) => measurement.temperature,
              minY: 0.0,
              maxY: 50.0,
            ),
          ),
        ),
      );

      // Assert - Should not crash and should show chart
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Test Chart'), findsOneWidget);
    });

    testWidgets('should display correct Y-axis bounds',
        (WidgetTester tester) async {
      // Arrange
      final measurements = [
        MeasurementData(
          timestamp: DateTime.now(),
          humidity: 50.0,
          temperature: 25.0,
          type: 'data',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphWidget(
              data: measurements,
              title: 'Bounded Chart',
              yAxisLabel: 'Value',
              valueSelector: (measurement) => measurement.humidity,
              minY: 40.0,
              maxY: 60.0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Bounded Chart'), findsOneWidget);
    });
  });
}
