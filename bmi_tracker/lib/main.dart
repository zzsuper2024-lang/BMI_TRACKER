import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'util/target_weight_service.dart';
import 'add_record_page.dart';
import 'db/record_db.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI 追踪仪',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const RootPage(),
    );
  }
}

//RootPage

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _index = 0;

  final _recordListKey = GlobalKey<_RecordListPageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      RecordListPage(key: _recordListKey),
      const ChartPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      floatingActionButton: _index == 1
          ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRecordPage()),
          );
          if (changed == true) {
            _recordListKey.currentState?.refresh();
          }
        },
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '概览'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '记录'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '趋势'),
        ],
      ),
    );
  }
}

//HomePage
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /* ---------------- 辅助函数 ---------------- */
  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 28) return Colors.orange;
    return Colors.red;
  }

  String _bmiStatus(double bmi) {
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '超重';
    return '肥胖';
  }

  Future<Map<String, double>> _recentStats() async {
    final rows = await RecordDB().fetchRecent(7);
    if (rows.isEmpty) return {};
    final ws = rows.map((e) => (e['weight'] as num).toDouble()).toList();
    final avg = ws.reduce((a, b) => a + b) / ws.length;
    return {
      'avg': avg,
      'max': ws.reduce((a, b) => a > b ? a : b),
      'min': ws.reduce((a, b) => a < b ? a : b),
    };
  }

  Widget _statItem(String label, double value) => Column(
    children: [
      Text(value.toStringAsFixed(1),
          style:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  /* ----------------  UI  ---------------- */
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: TargetWeightService.get(),   // 读取目标体重
      builder: (_, targetSnap) {
        if (!targetSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final targetWeight = targetSnap.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: RecordDB().fetchRecent(1), // 最近一次记录
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.data!.isEmpty) {
              return const Center(child: Text('暂无记录，请点击“记录”页右下角 + 添加'));
            }

            final e = snap.data!.first;
            final weight = (e['weight'] as num).toDouble();
            final height = (e['height'] as num).toDouble();
            final bmi = weight / ((height / 100) * (height / 100));
            final date = e['date'] as String;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /* 顶部欢迎 + 编辑按钮 */
                        Row(
                          children: [
                            Expanded(
                              child: Text('Hi，欢迎回来 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                      fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final ctl = TextEditingController(
                                    text: targetWeight.toStringAsFixed(1));
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('设置目标体重 (kg)'),
                                    content: TextField(
                                      controller: ctl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('取消')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('确定')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  final v =
                                  double.tryParse(ctl.text.trim());
                                  if (v != null && v > 0) {
                                    await TargetWeightService.set(v);
                                    if (context.mounted) setState(() {});
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        /* 最近记录卡片 */
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6BD6CF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.calendar_today,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('yyyy.MM.dd')
                                        .format(DateTime.parse(date))),
                                    const SizedBox(height: 4),
                                    Text('体重  ${weight.toStringAsFixed(1)} kg'),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        text: 'BMI ${bmi.toStringAsFixed(1)} ',
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .copyWith(fontSize: 16),
                                        children: [
                                          TextSpan(
                                            text: _bmiStatus(bmi),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _bmiColor(bmi)),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        /* 目标体重进度卡片 */
                        const SizedBox(height: 24),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('距离目标体重'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (weight > targetWeight)
                                      ? (targetWeight / weight).clamp(0, 1)
                                      : (weight / targetWeight).clamp(0, 1),
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation(Colors.teal),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                      () {
                                    final diff = weight - targetWeight;
                                    if (diff.abs() < 0.1) return '已达到目标 🎉';
                                    return diff > 0
                                        ? '${diff.toStringAsFixed(1)} kg 需减重'
                                        : '${diff.abs().toStringAsFixed(1)} kg 需增重';
                                  }(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        /* 最近 7 天统计 */
                        const SizedBox(height: 24),
                        FutureBuilder(
                          future: _recentStats(),
                          builder: (_, statsSnap) {
                            if (!statsSnap.hasData ||
                                statsSnap.data!.isEmpty) {
                              return const SizedBox();
                            }
                            final d = statsSnap.data!;
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                                  children: [
                                    _statItem('7日均重', d['avg']!),
                                    _statItem('7日最高', d['max']!),
                                    _statItem('7日最低', d['min']!),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


//RecordListPage

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});
  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = RecordDB().fetchAll();
  }

  void refresh() {
    setState(() {
      _future = RecordDB().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('暂无记录'));
        }

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final e = list[i];
            final w = (e['weight'] as num).toDouble();
            final h = (e['height'] as num).toDouble();
            final bmi = w / ((h / 100) * (h / 100));
            return ListTile(
              leading: Text(e['date']),
              title: Text('体重 ${w.toStringAsFixed(1)} kg'),
              subtitle: Text('BMI ${bmi.toStringAsFixed(1)}'),
            );
          },
        );
      },
    );
  }
}

//ChartPage
class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: RecordDB().fetchRecent(30),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final raw = snap.data!;
        if (raw.length < 2) return const Center(child: Text('至少需要 2 条记录才能绘制趋势'));

        // 同一天取最后一次
        final map = <String, Map<String, dynamic>>{};
        for (final e in raw) map[e['date']] = e;
        final dedup = map.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        // 生成两条折线
        final weightSpots = <FlSpot>[];
        final heightSpots = <FlSpot>[];
        final labels = <int, String>{};
        for (int i = 0; i < dedup.length; i++) {
          final w = (dedup[i].value['weight'] as num).toDouble();
          final h = (dedup[i].value['height'] as num).toDouble();
          weightSpots.add(FlSpot(i.toDouble(), w));          // 体重
          heightSpots.add(FlSpot(i.toDouble(), h / 1.5));    // 身高映射
          labels[i] = dedup[i].key.substring(5);             // MM-dd
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _Legend(color: Colors.teal, text: '体重 kg'),
                    SizedBox(width: 12),
                    _Legend(color: Colors.purple, text: '身高 cm ÷1.5'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 150,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          getTitlesWidget: (v, _) =>
                              Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (v, _) => Text(
                            labels[v.toInt()] ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weightSpots,
                        isCurved: true,
                        color: Colors.teal,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: heightSpots,
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 图例小条
class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text, super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 4, color: color),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}
