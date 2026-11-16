import 'package:material_ui/material_ui.dart';

import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/records_page.dart';
import 'theme.dart';

void main() => runApp(const FoodKaKaApp());

class FoodKaKaApp extends StatelessWidget {
  const FoodKaKaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '饭咔咔',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _selectedIndex,
        children: const [HomePage(), RecordsPage(), ProfilePage()],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          selectedIcon: Icon(Icons.wb_sunny_rounded),
          label: '今日',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: '记录',
        ),
        NavigationDestination(
          icon: Icon(Icons.face_outlined),
          selectedIcon: Icon(Icons.face_rounded),
          label: '我的',
        ),
      ],
    ),
  );
}
