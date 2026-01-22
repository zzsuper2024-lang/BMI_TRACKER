import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/record_db.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _weightCtl = TextEditingController();
  final _heightCtl = TextEditingController();
  DateTime _date = DateTime.now();

  Future<void> _save() async {
    if (_weightCtl.text.isEmpty || _heightCtl.text.isEmpty) return;
    await RecordDB().insert({
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'weight': double.parse(_weightCtl.text),
      'height': double.parse(_heightCtl.text),
    });
    if (mounted) Navigator.pop(context, true); // 返回时带 true 触发表格刷新
  }

  @override
  void dispose() {
    _weightCtl.dispose();
    _heightCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增记录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _weightCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '体重 (kg)'),
            ),
            TextField(
              controller: _heightCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '身高 (cm)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(DateFormat('yyyy-MM-dd').format(_date)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('选日期'),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}