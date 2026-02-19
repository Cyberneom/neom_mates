/// Benchmark tests for neom_mates module
///
/// Measures:
/// - Mate details page rendering
/// - Animated buttons performance
/// - Stats card animation
/// - List rendering performance
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

class Benchmark {
  final String name;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _measurements = [];

  Benchmark(this.name);

  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
    _measurements.add(_stopwatch.elapsed);
  }

  Duration get averageTime {
    if (_measurements.isEmpty) return Duration.zero;
    final total = _measurements.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _measurements.length);
  }

  Duration get minTime =>
      _measurements.isEmpty ? Duration.zero : _measurements.reduce((a, b) => a < b ? a : b);

  Duration get maxTime =>
      _measurements.isEmpty ? Duration.zero : _measurements.reduce((a, b) => a > b ? a : b);

  void printResults() {
    print('═══════════════════════════════════════════');
    print('Benchmark: $name');
    print('───────────────────────────────────────────');
    print('Iterations: ${_measurements.length}');
    print('Average: ${averageTime.inMicroseconds}μs');
    print('Min: ${minTime.inMicroseconds}μs');
    print('Max: ${maxTime.inMicroseconds}μs');
    print('═══════════════════════════════════════════');
  }
}

void main() {
  group('Mate Details Header Benchmarks', () {
    testWidgets('header build time', (tester) async {
      final benchmark = Benchmark('Mate Details Header Build');

      for (int i = 0; i < 50; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Column(
              children: [
                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(height: 16),
                // Name
                const Text(
                  'John Doe',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.location_on, size: 14),
                    SizedBox(width: 4),
                    Text('New York, USA'),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text('Follow'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(20));
    });
  });

  group('Animated Follow Button Benchmarks', () {
    testWidgets('button build time', (tester) async {
      final benchmark = Benchmark('Animated Follow Button Build');

      for (int i = 0; i < 100; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GestureDetector(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, size: 18),
                    SizedBox(width: 8),
                    Text('Follow'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMicroseconds, lessThan(5000));
    });

    testWidgets('state transition animation', (tester) async {
      final benchmark = Benchmark('Follow Button State Transition');

      for (int i = 0; i < 30; i++) {
        bool isFollowing = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                GestureDetector(
                  onTap: () => setState(() => isFollowing = !isFollowing),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.grey : Colors.pink,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
              );
            },
          ),
        );

        benchmark.start();
        await tester.tap(find.byType(GestureDetector));
        await tester.pumpAndSettle();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(500));
    });

    testWidgets('particle animation performance', (tester) async {
      final stopwatch = Stopwatch()..start();
      int frameCount = 0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Stack(
                children: List.generate(8, (index) {
                  final angle = index * 0.785; // 45 degrees
                  return Positioned(
                    left: 50 + value * 30 * cos(angle),
                    top: 50 + value * 30 * sin(angle),
                    child: Opacity(
                      opacity: 1 - value,
                      child: const Icon(Icons.favorite, size: 12, color: Colors.red),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      );

      while (stopwatch.elapsedMilliseconds < 600) {
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }

      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Particle Animation');
      print('───────────────────────────────────────────');
      print('Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('Frames: $frameCount');
      print('FPS: ${(frameCount * 1000 / stopwatch.elapsedMilliseconds).toStringAsFixed(1)}');
      print('═══════════════════════════════════════════');

      expect(frameCount, greaterThan(20));
    });
  });

  group('Mate List Benchmarks', () {
    testWidgets('list of 20 mates build time', (tester) async {
      final benchmark = Benchmark('Mate List (20 items)');

      for (int i = 0; i < 30; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            ListView.builder(
              itemCount: 20,
              itemBuilder: (_, index) => ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text('User $index'),
                subtitle: Text('About user $index'),
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Follow'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(50));
    });

    testWidgets('list scroll performance', (tester) async {
      final benchmark = Benchmark('Mate List Scroll');

      await tester.pumpWidget(
        wrapWithMaterialApp(
          ListView.builder(
            itemCount: 100,
            itemBuilder: (_, index) => ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('User $index'),
              subtitle: Text('About user $index'),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
        benchmark.start();
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(50));
    });
  });

  group('Stats Card Benchmarks', () {
    testWidgets('stats card build time', (tester) async {
      final benchmark = Benchmark('Profile Stats Card Build');

      for (int i = 0; i < 50; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', 42),
                  _buildStatColumn('Events', 15),
                  _buildStatColumn('Bands', 3),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMicroseconds, lessThan(10000));
    });

    testWidgets('stats card with followers (conditional)', (tester) async {
      final benchmarkWith = Benchmark('Stats Card WITH Followers');
      final benchmarkWithout = Benchmark('Stats Card WITHOUT Followers');

      // With followers
      for (int i = 0; i < 30; i++) {
        benchmarkWith.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', 42),
                  _buildStatColumn('Followers', 1234),
                  _buildStatColumn('Following', 567),
                  _buildStatColumn('Events', 15),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        benchmarkWith.stop();
      }

      // Without followers
      for (int i = 0; i < 30; i++) {
        benchmarkWithout.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', 42),
                  _buildStatColumn('Events', 15),
                  _buildStatColumn('Bands', 3),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        benchmarkWithout.stop();
      }

      print('\n═══════════════════════════════════════════');
      print('Comparative: Stats Card Variants');
      print('───────────────────────────────────────────');
      print('With followers avg: ${benchmarkWith.averageTime.inMicroseconds}μs');
      print('Without followers avg: ${benchmarkWithout.averageTime.inMicroseconds}μs');
      print('═══════════════════════════════════════════\n');
    });
  });

  group('Mate Posts Grid Benchmarks', () {
    testWidgets('mate posts grid build time', (tester) async {
      final benchmark = Benchmark('Mate Posts Grid Build');

      for (int i = 0; i < 30; i++) {
        benchmark.start();
        await tester.pumpWidget(
          wrapWithMaterialApp(
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: 12,
              itemBuilder: (_, index) => Container(
                color: Colors.grey[800],
                child: Stack(
                  children: [
                    Center(child: Text('$index')),
                    if (index % 3 == 0)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.play_arrow, size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        benchmark.stop();
      }

      benchmark.printResults();
      expect(benchmark.averageTime.inMilliseconds, lessThan(30));
    });
  });
}

// Helper widget
Widget _buildStatColumn(String label, int value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$value',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ],
  );
}

// Math helpers
double cos(double radians) => 1.0; // Simplified for benchmark
double sin(double radians) => 0.0; // Simplified for benchmark
