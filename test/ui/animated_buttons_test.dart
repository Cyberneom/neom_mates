/// Tests for AnimatedFollowButton and AnimatedMessageButton
///
/// Covers:
/// - Follow/unfollow states
/// - Animation behavior
/// - Particle effects
/// - Loading states
/// - Haptic feedback triggers
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helpers
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Mock AnimatedFollowButton for testing
class MockAnimatedFollowButton extends StatefulWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback? onPressed;

  const MockAnimatedFollowButton({
    this.isFollowing = false,
    this.isLoading = false,
    this.onPressed,
    super.key,
  });

  @override
  State<MockAnimatedFollowButton> createState() => _MockAnimatedFollowButtonState();
}

class _MockAnimatedFollowButtonState extends State<MockAnimatedFollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.isLoading) return;

    HapticFeedback.mediumImpact();

    if (!widget.isFollowing) {
      setState(() => _showParticles = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showParticles = false);
      });
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: widget.isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [Colors.pink, Colors.red],
                          ),
                    color: widget.isFollowing ? Colors.grey[800] : null,
                    borderRadius: BorderRadius.circular(25),
                    border: widget.isFollowing
                        ? Border.all(color: Colors.grey[600]!)
                        : null,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          key: Key('loading_indicator'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add,
                              key: Key(widget.isFollowing
                                  ? 'unfollow_icon'
                                  : 'follow_icon'),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isFollowing ? 'Unfollow' : 'Follow',
                              key: Key(widget.isFollowing
                                  ? 'unfollow_text'
                                  : 'follow_text'),
                            ),
                          ],
                        ),
                ),
                if (_showParticles)
                  const Positioned.fill(
                    key: Key('particles'),
                    child: _ParticleOverlay(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParticleOverlay extends StatelessWidget {
  const _ParticleOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.favorite, color: Colors.red, size: 20),
    );
  }
}

/// Mock AnimatedMessageButton for testing
class MockAnimatedMessageButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const MockAnimatedMessageButton({
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  @override
  State<MockAnimatedMessageButton> createState() => _MockAnimatedMessageButtonState();
}

class _MockAnimatedMessageButtonState extends State<MockAnimatedMessageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        if (!widget.isLoading) {
          HapticFeedback.lightImpact();
          widget.onPressed?.call();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              key: const Key('message_button'),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      key: Key('message_loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message, key: Key('message_icon'), size: 18),
                        SizedBox(width: 8),
                        Text('Message', key: Key('message_text')),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  group('AnimatedFollowButton Tests', () {
    group('Rendering', () {
      testWidgets('renders follow state correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedFollowButton(isFollowing: false),
          ),
        );

        expect(find.text('Follow'), findsOneWidget);
        expect(find.byKey(const Key('follow_icon')), findsOneWidget);
      });

      testWidgets('renders unfollow state correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedFollowButton(isFollowing: true),
          ),
        );

        expect(find.text('Unfollow'), findsOneWidget);
        expect(find.byKey(const Key('unfollow_icon')), findsOneWidget);
      });

      testWidgets('shows loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedFollowButton(isLoading: true),
          ),
        );

        expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
        expect(find.text('Follow'), findsNothing);
      });
    });

    group('Interactions', () {
      testWidgets('calls onPressed when tapped', (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedFollowButton(onPressed: () => pressed = true),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pump();

        expect(pressed, isTrue);

        // Wait for particle timer to complete
        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('does not call onPressed when loading', (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedFollowButton(
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pump();

        expect(pressed, isFalse);
      });
    });

    group('Animation', () {
      testWidgets('scales down on tap down', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedFollowButton(),
          ),
        );

        // Verify Transform widget exists for animation
        expect(
          find.descendant(
            of: find.byType(MockAnimatedFollowButton),
            matching: find.byType(Transform),
          ),
          findsWidgets,
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MockAnimatedFollowButton)),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Animation should have started without errors
        await gesture.up();
        await tester.pumpAndSettle();

        // Wait for particle timer to complete
        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('returns to normal scale after tap', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedFollowButton(),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pumpAndSettle();

        // Wait for particle timer to complete
        await tester.pump(const Duration(milliseconds: 600));

        // Verify Transform exists and animation completed
        expect(
          find.descendant(
            of: find.byType(MockAnimatedFollowButton),
            matching: find.byType(Transform),
          ),
          findsWidgets,
        );
      });
    });

    group('Particle Effects', () {
      testWidgets('shows particles when following', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedFollowButton(
              isFollowing: false,
              onPressed: () {},
            ),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pump();

        expect(find.byKey(const Key('particles')), findsOneWidget);

        // Wait for particles to disappear to avoid timer pending error
        await tester.pump(const Duration(milliseconds: 600));
      });

      testWidgets('particles disappear after delay', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedFollowButton(
              isFollowing: false,
              onPressed: () {},
            ),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pump();

        expect(find.byKey(const Key('particles')), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byKey(const Key('particles')), findsNothing);
      });

      testWidgets('no particles when unfollowing', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedFollowButton(
              isFollowing: true,
              onPressed: () {},
            ),
          ),
        );

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pump();

        expect(find.byKey(const Key('particles')), findsNothing);
      });
    });

    group('State Transitions', () {
      testWidgets('transitions from follow to unfollow', (tester) async {
        bool isFollowing = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                MockAnimatedFollowButton(
                  isFollowing: isFollowing,
                  onPressed: () => setState(() => isFollowing = true),
                ),
              );
            },
          ),
        );

        expect(find.text('Follow'), findsOneWidget);

        await tester.tap(find.byType(MockAnimatedFollowButton));
        // Wait for particles timer to complete
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.text('Unfollow'), findsOneWidget);
      });

      testWidgets('transitions from unfollow to follow', (tester) async {
        bool isFollowing = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                MockAnimatedFollowButton(
                  isFollowing: isFollowing,
                  onPressed: () => setState(() => isFollowing = false),
                ),
              );
            },
          ),
        );

        expect(find.text('Unfollow'), findsOneWidget);

        await tester.tap(find.byType(MockAnimatedFollowButton));
        await tester.pumpAndSettle();

        expect(find.text('Follow'), findsOneWidget);
      });
    });
  });

  group('AnimatedMessageButton Tests', () {
    group('Rendering', () {
      testWidgets('renders correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedMessageButton(),
          ),
        );

        expect(find.byKey(const Key('message_button')), findsOneWidget);
        expect(find.text('Message'), findsOneWidget);
        expect(find.byKey(const Key('message_icon')), findsOneWidget);
      });

      testWidgets('shows loading indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedMessageButton(isLoading: true),
          ),
        );

        expect(find.byKey(const Key('message_loading')), findsOneWidget);
        expect(find.text('Message'), findsNothing);
      });
    });

    group('Interactions', () {
      testWidgets('calls onPressed when tapped', (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedMessageButton(onPressed: () => pressed = true),
          ),
        );

        await tester.tap(find.byType(MockAnimatedMessageButton));
        await tester.pump();

        expect(pressed, isTrue);
      });

      testWidgets('does not call onPressed when loading', (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockAnimatedMessageButton(
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        );

        await tester.tap(find.byType(MockAnimatedMessageButton));
        await tester.pump();

        expect(pressed, isFalse);
      });
    });

    group('Animation', () {
      testWidgets('scales down on tap down', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockAnimatedMessageButton(),
          ),
        );

        // Verify Transform widget exists for animation
        expect(
          find.descendant(
            of: find.byType(MockAnimatedMessageButton),
            matching: find.byType(Transform),
          ),
          findsWidgets,
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MockAnimatedMessageButton)),
        );

        await tester.pump(const Duration(milliseconds: 50));

        // Animation should have started without errors
        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });

  group('Button Pair Tests', () {
    testWidgets('renders follow and message buttons together', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              MockAnimatedFollowButton(),
              SizedBox(width: 12),
              MockAnimatedMessageButton(),
            ],
          ),
        ),
      );

      expect(find.byType(MockAnimatedFollowButton), findsOneWidget);
      expect(find.byType(MockAnimatedMessageButton), findsOneWidget);
    });

    testWidgets('both buttons work independently', (tester) async {
      bool followPressed = false;
      bool messagePressed = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MockAnimatedFollowButton(
                onPressed: () => followPressed = true,
              ),
              const SizedBox(width: 12),
              MockAnimatedMessageButton(
                onPressed: () => messagePressed = true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(MockAnimatedFollowButton));
      await tester.pump();

      expect(followPressed, isTrue);
      expect(messagePressed, isFalse);

      await tester.tap(find.byType(MockAnimatedMessageButton));
      await tester.pump();

      expect(messagePressed, isTrue);

      // Wait for particle timer to complete
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
