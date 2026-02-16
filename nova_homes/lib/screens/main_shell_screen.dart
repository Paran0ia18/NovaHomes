import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/nova_homes_state.dart';
import '../theme/theme.dart';
import 'home_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';
import 'trips_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final NovaHomesState state = NovaHomesScope.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (int value) => setState(() => _currentIndex = value),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: const Color(0xFF98A2B3),
            selectedLabelStyle: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Saved',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.flight_outlined),
                activeIcon: Icon(Icons.flight),
                label: 'Trips',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    const Icon(Icons.chat_bubble_outline),
                    if (state.unreadInboxCount > 0)
                      Positioned(
                        right: -6,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDB2727),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            state.unreadInboxCount > 9
                                ? '9+'
                                : '${state.unreadInboxCount}',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Inbox',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return SavedScreen(
          onExploreTap: () => setState(() => _currentIndex = 0),
        );
      case 2:
        return TripsScreen(
          onExploreTap: () => setState(() => _currentIndex = 0),
        );
      case 3:
        return const InboxScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
}
