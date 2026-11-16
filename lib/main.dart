import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'data/food_store.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/records_page.dart';
import 'pages/meal_editor.dart';
import 'theme.dart';

void main() => runApp(const FoodKaKaApp());

class FoodKaKaApp extends StatelessWidget {
  const FoodKaKaApp({super.key, this.store});
  final FoodStore? store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '饭咔咔',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: AppShell(store: store),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.store});
  final FoodStore? store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  FoodStore? _store;
  Profile? _profile;
  DayLog? _today, _history;
  DateTime _historyDate = DateTime.now();
  int _selectedIndex = 0, _loadId = 0;
  Timer? _midnightTimer;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _store ??= widget.store ?? await FoodStore.open();
      await _refresh();
    } catch (_) {
      if (mounted) setState(() => _error = '本地数据暂时无法读取，请重试。不会重置已有记录。');
    }
  }

  Future<void> _refresh() async {
    final request = ++_loadId;
    try {
      final profile = await _store!.profile();
      final today = profile == null ? null : await _store!.day(_store!.now());
      final history = profile == null ? null : await _store!.day(_historyDate);
      if (!mounted || request != _loadId) return;
      setState(() {
        _profile = profile;
        _today = today;
        _history = history;
        _loaded = true;
        _error = null;
      });
      _midnightTimer?.cancel();
      final now = _store!.now();
      _midnightTimer = Timer(
        DateTime(now.year, now.month, now.day + 1).difference(now),
        _refresh,
      );
    } catch (_) {
      if (mounted && request == _loadId) {
        setState(() => _error = '读取记录失败，请重试。已有数据不会被删除。');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _store != null) _refresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.store == null) _store?.db.close();
    super.dispose();
  }

  Future<void> _edit({Meal? meal, DateTime? date}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MealEditor(store: _store!, date: date ?? _store!.now(), meal: meal),
      ),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _delete(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这一餐？'),
        content: const Text('这餐中的全部食物记录会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _store!.deleteMeal(meal.id!);
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，记录仍保留，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _initialize,
                    child: const Text('重新读取'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_loaded) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_profile == null) {
      return Scaffold(
        body: SafeArea(
          child: ProfilePage(store: _store!, profile: null, onSaved: _refresh),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomePage(
              profile: _profile!,
              log: _today!,
              onAdd: () => _edit(),
              onEdit: (meal) => _edit(meal: meal),
              onDelete: _delete,
            ),
            RecordsPage(
              log: _history!,
              onDateChanged: (date) {
                setState(() => _historyDate = date);
                _refresh();
              },
              onAdd: () => _edit(date: _historyDate),
              onEdit: (meal) => _edit(meal: meal),
              onDelete: _delete,
            ),
            ProfilePage(store: _store!, profile: _profile, onSaved: _refresh),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
}
