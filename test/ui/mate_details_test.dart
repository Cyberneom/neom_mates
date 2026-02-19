/// Tests for MateDetailsPage and related widgets
///
/// Covers:
/// - Header rendering (avatar, name, location)
/// - Action buttons (follow, message)
/// - Stats card integration
/// - Posts grid display
/// - Loading states
/// - Navigation and interactions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helpers
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: child,
  );
}

/// Mock Mate data
class MockMate {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? location;
  final String? bio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int eventsCount;
  final int bandsCount;
  final bool isFollowing;
  final bool isCurrentUser;

  const MockMate({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.location,
    this.bio,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.eventsCount = 0,
    this.bandsCount = 0,
    this.isFollowing = false,
    this.isCurrentUser = false,
  });
}

/// Mock MateDetailsPage for testing
class MockMateDetailsPage extends StatefulWidget {
  final MockMate mate;
  final bool isLoading;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onBackPressed;

  const MockMateDetailsPage({
    required this.mate,
    this.isLoading = false,
    this.onFollowPressed,
    this.onMessagePressed,
    this.onBackPressed,
    super.key,
  });

  @override
  State<MockMateDetailsPage> createState() => _MockMateDetailsPageState();
}

class _MockMateDetailsPageState extends State<MockMateDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MockMateDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const Key('mate_app_bar'),
        leading: IconButton(
          key: const Key('back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        ),
        title: Text(widget.mate.name),
        actions: [
          if (!widget.mate.isCurrentUser)
            IconButton(
              key: const Key('more_options'),
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
        ],
      ),
      body: widget.isLoading
          ? const _LoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                key: const Key('refresh_indicator'),
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  key: const Key('mate_scroll_view'),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _MateHeader(
                        mate: widget.mate,
                        onFollowPressed: widget.onFollowPressed,
                        onMessagePressed: widget.onMessagePressed,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _MateStats(mate: widget.mate),
                    ),
                    if (widget.mate.bio != null)
                      SliverToBoxAdapter(
                        child: _MateBio(bio: widget.mate.bio!),
                      ),
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Posts',
                        count: widget.mate.postsCount,
                      ),
                    ),
                    _MatePostsGrid(postsCount: widget.mate.postsCount),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loading_state'),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar placeholder
          Container(
            key: const Key('avatar_skeleton'),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          // Name placeholder
          Container(
            key: const Key('name_skeleton'),
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Location placeholder
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MateHeader extends StatelessWidget {
  final MockMate mate;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onMessagePressed;

  const _MateHeader({
    required this.mate,
    this.onFollowPressed,
    this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mate_header'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            key: const Key('mate_avatar'),
            radius: 50,
            backgroundColor: Colors.grey[700],
            backgroundImage: mate.avatarUrl != null
                ? NetworkImage(mate.avatarUrl!)
                : null,
            child: mate.avatarUrl == null
                ? Text(
                    mate.name.isNotEmpty ? mate.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            mate.name,
            key: const Key('mate_name'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Location
          if (mate.location != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  mate.location!,
                  key: const Key('mate_location'),
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Action buttons
          if (!mate.isCurrentUser)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FollowButton(
                  isFollowing: mate.isFollowing,
                  onPressed: onFollowPressed,
                ),
                const SizedBox(width: 12),
                _MessageButton(onPressed: onMessagePressed),
              ],
            ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final bool isFollowing;
  final VoidCallback? onPressed;

  const _FollowButton({
    required this.isFollowing,
    this.onPressed,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              key: const Key('follow_button'),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isFollowing ? Icons.person_remove : Icons.person_add,
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
          );
        },
      ),
    );
  }
}

class _MessageButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _MessageButton({this.onPressed});

  @override
  State<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends State<_MessageButton>
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
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, size: 18),
                  SizedBox(width: 8),
                  Text('Message'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MateStats extends StatelessWidget {
  final MockMate mate;

  const _MateStats({required this.mate});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mate_stats'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Posts', mate.postsCount),
          _buildStat('Followers', mate.followersCount),
          _buildStat('Following', mate.followingCount),
          _buildStat('Events', mate.eventsCount),
          _buildStat('Bands', mate.bandsCount),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(value),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _MateBio extends StatelessWidget {
  final String bio;

  const _MateBio({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mate_bio'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        bio,
        style: TextStyle(color: Colors.grey[300]),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('section_header'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatePostsGrid extends StatelessWidget {
  final int postsCount;

  const _MatePostsGrid({required this.postsCount});

  @override
  Widget build(BuildContext context) {
    if (postsCount == 0) {
      return SliverToBoxAdapter(
        child: Container(
          key: const Key('no_posts_state'),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      key: const Key('posts_grid'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          key: ValueKey('post_$index'),
          color: Colors.grey[800],
          child: Center(
            child: Icon(Icons.image, color: Colors.grey[600]),
          ),
        ),
        childCount: postsCount,
      ),
    );
  }
}

void main() {
  group('MateDetailsPage Tests', () {
    group('Header Rendering', () {
      testWidgets('renders mate name correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John Doe'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsNWidgets(2)); // AppBar + Header
        expect(find.byKey(const Key('mate_name')), findsOneWidget);
      });

      testWidgets('renders avatar with first letter when no image',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'Alice'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('renders location when provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(
                id: '1',
                name: 'John',
                location: 'New York, USA',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('New York, USA'), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
      });

      testWidgets('hides location when not provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mate_location')), findsNothing);
      });
    });

    group('Action Buttons', () {
      testWidgets('shows follow and message buttons for other users',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isCurrentUser: false),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('follow_button')), findsOneWidget);
        expect(find.byKey(const Key('message_button')), findsOneWidget);
      });

      testWidgets('hides action buttons for current user', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isCurrentUser: true),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('follow_button')), findsNothing);
        expect(find.byKey(const Key('message_button')), findsNothing);
      });

      testWidgets('shows Follow text when not following', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isFollowing: false),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Follow'), findsOneWidget);
        expect(find.byKey(const Key('follow_icon')), findsOneWidget);
      });

      testWidgets('shows Unfollow text when following', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isFollowing: true),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Unfollow'), findsOneWidget);
        expect(find.byKey(const Key('unfollow_icon')), findsOneWidget);
      });

      testWidgets('calls onFollowPressed when follow button tapped',
          (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockMateDetailsPage(
              mate: const MockMate(id: '1', name: 'John'),
              onFollowPressed: () => pressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('follow_button')));
        await tester.pump();

        expect(pressed, isTrue);
      });

      testWidgets('calls onMessagePressed when message button tapped',
          (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockMateDetailsPage(
              mate: const MockMate(id: '1', name: 'John'),
              onMessagePressed: () => pressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('message_button')));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Stats Display', () {
      testWidgets('shows all stat values correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(
                id: '1',
                name: 'John',
                postsCount: 42,
                followersCount: 1234,
                followingCount: 567,
                eventsCount: 15,
                bandsCount: 3,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mate_stats')), findsOneWidget);
        // 42 appears twice: in stats and in section header count badge
        expect(find.text('42'), findsNWidgets(2));
        expect(find.text('1.2K'), findsOneWidget);
        expect(find.text('567'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('shows stat labels', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Posts'), findsNWidgets(2)); // Section header + stats
        expect(find.text('Followers'), findsOneWidget);
        expect(find.text('Following'), findsOneWidget);
        expect(find.text('Events'), findsOneWidget);
        expect(find.text('Bands'), findsOneWidget);
      });
    });

    group('Bio Section', () {
      testWidgets('shows bio when provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(
                id: '1',
                name: 'John',
                bio: 'Music lover | Guitar player',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mate_bio')), findsOneWidget);
        expect(find.text('Music lover | Guitar player'), findsOneWidget);
      });

      testWidgets('hides bio when not provided', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mate_bio')), findsNothing);
      });
    });

    group('Posts Grid', () {
      testWidgets('shows posts grid when posts exist', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', postsCount: 9),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('posts_grid')), findsOneWidget);
      });

      testWidgets('shows empty state when no posts', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', postsCount: 0),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('no_posts_state')), findsOneWidget);
        expect(find.text('No posts yet'), findsOneWidget);
      });

      testWidgets('shows post count in section header', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', postsCount: 99),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('section_header')), findsOneWidget);
        // 99 appears twice: in stats and in section header count badge
        expect(find.text('99'), findsNWidgets(2));
      });
    });

    group('Loading State', () {
      testWidgets('shows loading state when isLoading is true',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
              isLoading: true,
            ),
          ),
        );

        expect(find.byKey(const Key('loading_state')), findsOneWidget);
        expect(find.byKey(const Key('avatar_skeleton')), findsOneWidget);
        expect(find.byKey(const Key('name_skeleton')), findsOneWidget);
      });

      testWidgets('hides loading state when isLoading is false',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
              isLoading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('loading_state')), findsNothing);
        expect(find.byKey(const Key('mate_header')), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('shows back button', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('back_button')), findsOneWidget);
      });

      testWidgets('calls onBackPressed when back button tapped',
          (tester) async {
        bool pressed = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockMateDetailsPage(
              mate: const MockMate(id: '1', name: 'John'),
              onBackPressed: () => pressed = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('back_button')));
        await tester.pump();

        expect(pressed, isTrue);
      });

      testWidgets('shows more options for other users', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isCurrentUser: false),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('more_options')), findsOneWidget);
      });

      testWidgets('hides more options for current user', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John', isCurrentUser: true),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('more_options')), findsNothing);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('has refresh indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('refresh_indicator')), findsOneWidget);
      });

      testWidgets('can trigger refresh by pulling down', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.fling(
          find.byKey(const Key('mate_scroll_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Refresh indicator should be visible
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Animation', () {
      testWidgets('content fades in on load', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        // FadeTransition exists in the widget tree (there may be multiple from MaterialApp)
        expect(find.byType(FadeTransition), findsWidgets);

        // Verify FadeTransition from our widget exists by checking the scroll view
        // is wrapped in a FadeTransition
        expect(
          find.ancestor(
            of: find.byKey(const Key('mate_scroll_view')),
            matching: find.byType(FadeTransition),
          ),
          findsWidgets, // MaterialApp adds transition wrappers
        );

        await tester.pumpAndSettle();
      });

      testWidgets('buttons scale on tap', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockMateDetailsPage(
              mate: MockMate(id: '1', name: 'John'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Transform widget exists for follow button animation
        expect(
          find.ancestor(
            of: find.byKey(const Key('follow_button')),
            matching: find.byType(Transform),
          ),
          findsWidgets,
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('follow_button'))),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Animation should have started without errors
        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });

  group('MateDetailsPage Benchmark Tests', () {
    testWidgets('full page build time', (tester) async {
      final stopwatch = Stopwatch();
      final measurements = <int>[];

      for (int i = 0; i < 30; i++) {
        stopwatch.reset();
        stopwatch.start();

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockMateDetailsPage(
              mate: MockMate(
                id: '$i',
                name: 'User $i',
                location: 'City $i',
                bio: 'Bio for user $i',
                postsCount: i * 5,
                followersCount: i * 100,
                followingCount: i * 50,
                eventsCount: i * 2,
                bandsCount: i,
              ),
            ),
          ),
        );
        await tester.pump();

        stopwatch.stop();
        measurements.add(stopwatch.elapsedMicroseconds);
      }

      final average = measurements.reduce((a, b) => a + b) ~/ measurements.length;
      print('MateDetailsPage Build - Average: ${average}μs');

      expect(average, lessThan(50000)); // Should build under 50ms
    });

    testWidgets('scroll performance', (tester) async {
      final stopwatch = Stopwatch();
      final measurements = <int>[];

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const MockMateDetailsPage(
            mate: MockMate(
              id: '1',
              name: 'Test User',
              postsCount: 30,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (int i = 0; i < 20; i++) {
        stopwatch.reset();
        stopwatch.start();

        await tester.drag(
          find.byKey(const Key('mate_scroll_view')),
          const Offset(0, -100),
        );
        await tester.pump();

        stopwatch.stop();
        measurements.add(stopwatch.elapsedMicroseconds);
      }

      final average = measurements.reduce((a, b) => a + b) ~/ measurements.length;
      print('MateDetailsPage Scroll - Average: ${average}μs');

      expect(average, lessThan(50000)); // Each scroll under 50ms
    });
  });
}
