import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'for_you_feed_screen.dart';
import 'my_trips_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tapController;

  final List<Widget> _screens = const [
    HomeScreen(),
    ForYouFeedScreen(),
    ExploreScreen(),
    ChatListScreen(),
    MyTripsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'For You'),
    _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chats'),
    _NavItem(icon: Icons.card_travel_outlined, activeIcon: Icons.card_travel_rounded, label: 'Trips'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) => _buildNavItem(i, isDark)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int i, bool isDark) {
    final item = _navItems[i];
    final selected = _currentIndex == i;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = i);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    const Color(0xFFFF8C00).withValues(alpha: isDark ? 0.22 : 0.14),
                    const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.10 : 0.06),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: selected
                      ? const Color(0xFFFF8C00)
                      : (isDark ? Colors.white30 : const Color(0xFFAAAAAA)),
                  size: 22,
                ),
                // Active dot indicator
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF8C00),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF8C00),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                color: selected
                    ? const Color(0xFFFF8C00)
                    : (isDark ? Colors.white30 : const Color(0xFFAAAAAA)),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
