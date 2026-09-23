import 'package:flutter/material.dart';

/// หน้าแสดงรายชื่อและรหัสนักศึกษาของสมาชิกกลุ่มที่พัฒนาแอปนี้
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  static const _members = [
    _TeamMember(id: '6721652692', name: 'นายศิวะเนศ กิจก้องขจร'),
    _TeamMember(id: '6721652650', name: 'นายวุฒิศักดิ์ กำลังยิ่ง'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมาชิกกลุ่ม')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.groups, size: 56),
              const SizedBox(height: 16),
              Text(
                'Webtoon App',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'รายชื่อสมาชิกกลุ่ม',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              ..._members.map(
                (member) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member.name),
                    subtitle: Text('รหัสนักศึกษา ${member.id}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMember {
  final String id;
  final String name;

  const _TeamMember({required this.id, required this.name});
}
