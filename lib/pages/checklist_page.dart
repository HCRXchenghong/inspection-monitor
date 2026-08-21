import 'package:flutter/material.dart';
import '../theme/eleme_theme.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final Map<String, bool> _checked = {};
  int _totalChecked = 0;

  static const _categories = [
    _Category(
      title: '天花板与墙面',
      icon: Icons.roofing,
      items: [
        '烟雾报警器 (最常见藏匿点)',
        '天花板圆形小孔 / 黑点',
        '空调出风口内部',
        '灯具底座',
        '墙面电源插座面板',
        '墙面螺丝钉 (针孔镜头)',
        '画框 / 装饰品背面',
        '窗帘杆 / 窗帘扣',
      ],
    ),
    _Category(
      title: '桌面与家具',
      icon: Icons.table_restaurant,
      items: [
        '闹钟 / 数字时钟',
        '收音机 / 蓝牙音箱',
        'USB 充电器 / 电源适配器',
        '纸巾盒 (底部)',
        '相框 (背面)',
        '花瓶 / 装饰品',
        '衣柜 / 保险箱内',
        '书籍 / 文件夹',
        '电视底部',
        '空调遥控器',
      ],
    ),
    _Category(
      title: '卫生间',
      icon: Icons.bathroom,
      items: [
        '浴帘杆 / 浴帘扣',
        '洗发水瓶 / 沐浴液瓶',
        '镜子 (双面镜检测)',
        '排风扇 / 排气口',
        '卫生纸盒',
        '毛巾架',
      ],
    ),
    _Category(
      title: '其他位置',
      icon: Icons.more_horiz,
      items: [
        '衣架 / 挂钩',
        '拖鞋',
        '空气净化器 / 加湿器',
        '门铃 / 门禁面板',
        '门把手 / 门铰链',
        '窗台装饰物',
      ],
    ),
  ];

  int get _totalItems => _categories.fold(0, (sum, c) => sum + c.items.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('排查清单')),
      body: Column(
        children: [
          _buildProgressCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _buildCategorySection(cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _totalItems > 0 ? _totalChecked / _totalItems : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('排查进度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ElemeTheme.textPrimary)),
              Text(
                '$_totalChecked / $_totalItems',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ElemeTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ElemeTheme.divider,
              valueColor: const AlwaysStoppedAnimation(ElemeTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(_Category cat) {
    final catChecked = cat.items.where((item) => _checked['${cat.title}-$item'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElemeTheme.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ElemeTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(cat.icon, size: 18, color: ElemeTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ElemeTheme.textPrimary),
                  ),
                ),
                Text(
                  '$catChecked/${cat.items.length}',
                  style: const TextStyle(fontSize: 13, color: ElemeTheme.textTertiary),
                ),
              ],
            ),
          ),
          ...cat.items.map((item) {
            final key = '${cat.title}-$item';
            final isChecked = _checked[key] == true;
            return InkWell(
              onTap: () => setState(() {
                _checked[key] = !isChecked;
                _totalChecked = _checked.values.where((v) => v).length;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    _checkbox(isChecked),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: isChecked ? ElemeTheme.textTertiary : ElemeTheme.textPrimary,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _checkbox(bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? ElemeTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? ElemeTheme.primary : ElemeTheme.border,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _Category {
  final String title;
  final IconData icon;
  final List<String> items;

  const _Category({required this.title, required this.icon, required this.items});
}
