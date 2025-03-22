import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/settings_service.dart';

class EventStatsPage extends StatefulWidget {
  final Event event;
  final EventService eventService;

  const EventStatsPage({
    super.key,
    required this.event,
    required this.eventService,
  });

  @override
  State<EventStatsPage> createState() => _EventStatsPageState();
}

class _EventStatsPageState extends State<EventStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedDateRange = 'daily';

  // 日期范围选择
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // 统计数据
  Map<DateTime, int> _dailyStats = {};
  Map<int, int> _weeklyStats = {};
  Map<String, int> _monthlyStats = {};

  // 阈值设置
  double _dailyThreshold = 5.0;
  double _weeklyThreshold = 20.0;
  double _monthlyThreshold = 50.0;
  bool _showDailyThreshold = false;
  bool _showWeeklyThreshold = false;
  bool _showMonthlyThreshold = false;

  late SettingsService _settingsService;
  int _statsEntryLimit = 6; // 默认值

  // 实现临时的国际化字符串，直到生成的文件更新
  final Map<String, Map<String, String>> _tempLocalizations = {
    'en': {
      'statsReport': 'Stats Report',
      'dailyStats': 'Daily Stats',
      'weeklyStats': 'Weekly Stats',
      'monthlyStats': 'Monthly Stats',
      'totalClicks': 'Total Clicks',
      'noData': 'No Data',
      'dateRange': 'Date Range',
      'from': 'From',
      'to': 'To',
      'resetFilter': 'Reset',
      'applyFilter': 'Apply Filter',
      'exportData': 'Export Data',
      'threshold': 'Threshold',
      'setThreshold': 'Set Threshold',
      'thresholdValue': 'Threshold Value',
      'apply': 'Apply',
      'cancel': 'Cancel',
    },
    'zh': {
      'statsReport': '统计报表',
      'dailyStats': '日统计',
      'weeklyStats': '周统计',
      'monthlyStats': '月统计',
      'totalClicks': '总点击次数',
      'noData': '暂无数据',
      'dateRange': '日期范围',
      'from': '从',
      'to': '至',
      'resetFilter': '重置',
      'applyFilter': '应用过滤',
      'exportData': '导出数据',
      'threshold': '阈值',
      'setThreshold': '设置阈值',
      'thresholdValue': '阈值数值',
      'apply': '应用',
      'cancel': '取消',
    }
  };

  // 获取本地化字符串
  String _getLocalText(String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _tempLocalizations[locale]?[key] ?? _tempLocalizations['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadStats(); // 初始加载统计数据
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _statsEntryLimit = _settingsService.statsEntryLimit;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadStats(); // 切换Tab时重新加载数据
    }
  }

  // 加载统计数据
  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 根据当前选项卡加载相应的统计数据
      switch (_tabController.index) {
        case 0: // 日统计
          _dailyStats = await widget.eventService.getEventStatsByDay(
            widget.event.id,
            start: _startDate,
            end: _endDate,
          );
          break;
        case 1: // 周统计
          _weeklyStats = await widget.eventService.getEventStatsByWeek(
            widget.event.id,
            start: _startDate,
            end: _endDate,
          );
          break;
        case 2: // 月统计
          _monthlyStats = await widget.eventService.getEventStatsByMonth(
            widget.event.id,
            start: _startDate,
            end: _endDate,
          );
          break;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载统计数据时出错: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载统计数据失败: $e')),
        );
      }
    }
  }

  // 应用日期筛选
  void _applyDateFilter() async {
    await _loadStats();
  }

  // 重置日期筛选
  void _resetDateFilter() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
    _loadStats();
  }

  // 选择开始日期
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // 选择结束日期
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // 导出数据
  void _exportData() {
    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能即将推出')),
    );
  }

  // 设置阈值对话框
  Future<void> _showThresholdDialog(int tabIndex) async {
    final TextEditingController thresholdController = TextEditingController(
        text: tabIndex == 0
            ? _dailyThreshold.toString()
            : tabIndex == 1
                ? _weeklyThreshold.toString()
                : _monthlyThreshold.toString());

    bool showThreshold = tabIndex == 0
        ? _showDailyThreshold
        : tabIndex == 1
            ? _showWeeklyThreshold
            : _showMonthlyThreshold;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_getLocalText('setThreshold')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _getLocalText('thresholdValue'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: showThreshold,
                      onChanged: (value) {
                        setDialogState(() {
                          showThreshold = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(_getLocalText('threshold')),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(_getLocalText('cancel')),
              ),
              TextButton(
                onPressed: () {
                  // 解析阈值
                  final double threshold =
                      double.tryParse(thresholdController.text) ?? 0;

                  // 更新对应的阈值
                  setState(() {
                    if (tabIndex == 0) {
                      _dailyThreshold = threshold;
                      _showDailyThreshold = showThreshold;
                    } else if (tabIndex == 1) {
                      _weeklyThreshold = threshold;
                      _showWeeklyThreshold = showThreshold;
                    } else {
                      _monthlyThreshold = threshold;
                      _showMonthlyThreshold = showThreshold;
                    }
                  });

                  Navigator.of(dialogContext).pop();
                },
                child: Text(_getLocalText('apply')),
              ),
            ],
          );
        });
      },
    );
  }

  // 构建日期筛选UI
  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalText('dateRange'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${_getLocalText('from')}: ${DateFormat('yyyy-MM-dd').format(_startDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _selectStartDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${_getLocalText('to')}: ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _selectEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(_getLocalText('resetFilter')),
                onPressed: _resetDateFilter,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: Text(_getLocalText('applyFilter')),
                onPressed: _applyDateFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建日统计UI
  Widget _buildDailyStats() {
    if (_dailyStats.isEmpty) {
      return Center(
        child: Text(_getLocalText('noData')),
      );
    }

    // 按日期倒序排序，最近的日期排在前面
    List<MapEntry<DateTime, int>> sortedEntries = _dailyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // 限制显示的记录数量
    if (sortedEntries.length > _statsEntryLimit) {
      sortedEntries = sortedEntries.sublist(0, _statsEntryLimit);
    }

    // 计算总点击次数
    int totalClicks = sortedEntries.fold(0, (sum, entry) => sum + entry.value);

    // 准备图表数据
    final spots = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final count = entry.value.value.toDouble();
      return FlSpot(index, count);
    }).toList();

    // 计算最大值，确保图表有足够的高度
    final maxY = spots.isEmpty
        ? 1.0
        : spots.fold(1.0, (max, spot) => spot.y > max ? spot.y : max);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getLocalText('totalClicks')}: $totalClicks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            // 添加折线图
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 == 0 && value < sortedEntries.length) {
                            final date = sortedEntries[value.toInt()].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM-dd').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY + 1,
                  // 添加阈值水平线
                  extraLinesData: _showDailyThreshold
                      ? ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: _dailyThreshold,
                            color: Colors.red,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding:
                                  const EdgeInsets.only(right: 8, bottom: 4),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              labelResolver: (line) =>
                                  '${_getLocalText('threshold')}: ${_dailyThreshold.toStringAsFixed(1)}',
                            ),
                          )
                        ])
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 使用ListView显示每天的统计数据
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final date = entry.key;
                final count = entry.value;

                return ListTile(
                  title: Text(DateFormat('yyyy-MM-dd').format(date)),
                  trailing: Text('$count'),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建周统计UI
  Widget _buildWeeklyStats() {
    if (_weeklyStats.isEmpty) {
      return Center(
        child: Text(_getLocalText('noData')),
      );
    }

    // 按周数倒序排序，最近的周排在前面
    List<MapEntry<int, int>> sortedEntries = _weeklyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // 限制显示的记录数量
    if (sortedEntries.length > _statsEntryLimit) {
      sortedEntries = sortedEntries.sublist(0, _statsEntryLimit);
    }

    // 计算总点击次数
    int totalClicks = sortedEntries.fold(0, (sum, entry) => sum + entry.value);

    // 准备图表数据
    final spots = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final count = entry.value.value.toDouble();
      return FlSpot(index, count);
    }).toList();

    // 计算最大值，确保图表有足够的高度
    final maxY = spots.isEmpty
        ? 1.0
        : spots.fold(1.0, (max, spot) => spot.y > max ? spot.y : max);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getLocalText('totalClicks')}: $totalClicks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            // 添加条形图
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sortedEntries.length) {
                            final weekNumber = sortedEntries[value.toInt()].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .week
                                    .replaceFirst('%d', weekNumber.toString()),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final weekNumber = entry.value.key;
                    final count = entry.value.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: Theme.of(context).primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  minY: 0,
                  maxY: maxY + 1,
                  // 添加阈值水平线
                  extraLinesData: _showWeeklyThreshold
                      ? ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: _weeklyThreshold,
                            color: Colors.red,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding:
                                  const EdgeInsets.only(right: 8, bottom: 4),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              labelResolver: (line) =>
                                  '${_getLocalText('threshold')}: ${_weeklyThreshold.toStringAsFixed(1)}',
                            ),
                          )
                        ])
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 使用ListView显示每周的统计数据
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final weekNumber = entry.key;
                final count = entry.value;

                // 计算该周的开始日期和结束日期
                final currentYear = DateTime.now().year;
                final startDate = DateTime(currentYear, 1, 1)
                    .add(Duration(days: (weekNumber - 1) * 7));
                final endDate = startDate.add(const Duration(days: 6));

                return ListTile(
                  title: Text(
                      '${AppLocalizations.of(context)!.week.replaceFirst('%d', weekNumber.toString())} (${DateFormat('MM-dd').format(startDate)} - ${DateFormat('MM-dd').format(endDate)})'),
                  trailing: Text('$count'),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建月统计UI
  Widget _buildMonthlyStats() {
    if (_monthlyStats.isEmpty) {
      return Center(
        child: Text(_getLocalText('noData')),
      );
    }

    // 按月份倒序排序，最近的月份排在前面
    List<MapEntry<String, int>> sortedEntries = _monthlyStats.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // 限制显示的记录数量
    if (sortedEntries.length > _statsEntryLimit) {
      sortedEntries = sortedEntries.sublist(0, _statsEntryLimit);
    }

    // 计算总点击次数
    int totalClicks = sortedEntries.fold(0, (sum, entry) => sum + entry.value);

    // 准备图表数据
    final spots = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final count = entry.value.value.toDouble();
      return FlSpot(index, count);
    }).toList();

    // 计算最大值，确保图表有足够的高度
    final maxY = spots.isEmpty
        ? 1.0
        : spots.fold(1.0, (max, spot) => spot.y > max ? spot.y : max);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getLocalText('totalClicks')}: $totalClicks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            // 添加柱状图
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sortedEntries.length) {
                            final monthKey = sortedEntries[value.toInt()].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthKey,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: sortedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final count = entry.value.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: Theme.of(context).primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  minY: 0,
                  maxY: maxY + 1,
                  // 添加阈值水平线
                  extraLinesData: _showMonthlyThreshold
                      ? ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: _monthlyThreshold,
                            color: Colors.red,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding:
                                  const EdgeInsets.only(right: 8, bottom: 4),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              labelResolver: (line) =>
                                  '${_getLocalText('threshold')}: ${_monthlyThreshold.toStringAsFixed(1)}',
                            ),
                          )
                        ])
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 使用ListView显示每月的统计数据
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final month = entry.key;
                final count = entry.value;

                return ListTile(
                  title: Text(month),
                  trailing: Text('$count'),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.name} - ${_getLocalText('statsReport')}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.linear_scale),
            onPressed: () => _showThresholdDialog(_tabController.index),
            tooltip: _getLocalText('setThreshold'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _getLocalText('dailyStats')),
            Tab(text: _getLocalText('weeklyStats')),
            Tab(text: _getLocalText('monthlyStats')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateFilter(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDailyStats(),
                      _buildWeeklyStats(),
                      _buildMonthlyStats(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
