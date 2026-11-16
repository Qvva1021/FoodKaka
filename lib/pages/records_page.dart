import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/rice_ball.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      Text('饮食记录', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      SizedBox(height: 8),
      Text('把每一天的好好吃饭，留在这里', style: TextStyle(color: muted)),
      SizedBox(height: 32),
      Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              RiceBall(size: 96),
              SizedBox(height: 24),
              Text(
                '你的饮食日记，还在等第一餐',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                '第二阶段将支持按日期查看、补记和修改饮食记录。',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
