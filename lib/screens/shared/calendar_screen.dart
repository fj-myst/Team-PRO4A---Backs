import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import '../shared/view_announcement_screen.dart';

// ── Calendar type enum ──
enum CalendarType { unit, techAdmin, viewerAdmin }

// ── Filter enum (Tech Admin only) ──
enum _CalendarFilter { all, tagged, techAssistance }

// ── Category enum ──
enum _AnnouncementCategory { none, tagged, techAssistance, both }

class CalendarScreen extends StatefulWidget {
  final CalendarType calendarType;
  const CalendarScreen({super.key, required this.calendarType});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = AnnouncementService();
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  final DateTime _today = DateTime.now();
  late DateTime _currentMonth;
  DateTime? _selectedDay;

  Map<int, List<Map<String, dynamic>>> _announcementsByDay = {};

  _CalendarFilter _activeFilter = _CalendarFilter.all;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_today.year, _today.month);
    _selectedDay = _today;
    if (widget.calendarType == CalendarType.techAdmin) {
      _currentUid = FirebaseAuth.instance.currentUser?.uid;
    }
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> data = [];

      switch (widget.calendarType) {
        case CalendarType.unit:
          data = await _service.getNewsFeed();
          break;
        case CalendarType.techAdmin:
          data = await _service.getTechAdminFeed();
          break;
        case CalendarType.viewerAdmin:
          final snapshot = await _firestore
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .get();
          data = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          break;
      }

      if (!mounted) return;

      final Map<int, List<Map<String, dynamic>>> byDay = {};
      for (final a in data) {
        if (a['dateTime'] == null) continue;
        final dt = (a['dateTime'] as Timestamp).toDate();
        if (dt.year == _currentMonth.year &&
            dt.month == _currentMonth.month) {
          byDay.putIfAbsent(dt.day, () => []).add(a);
        }
      }

      setState(() {
        _announcements = data;
        _announcementsByDay = byDay;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading announcements: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  _AnnouncementCategory _getCategory(Map<String, dynamic> a) {
    if (widget.calendarType != CalendarType.techAdmin) {
      return _AnnouncementCategory.none;
    }
    final visibleTo = List<String>.from(a['visibleTo'] ?? []);
    final needsTech = a['needsTechAssist'] == true;
    final isTagged =
        _currentUid != null && visibleTo.contains(_currentUid);

    if (isTagged && needsTech) return _AnnouncementCategory.both;
    if (isTagged) return _AnnouncementCategory.tagged;
    if (needsTech) return _AnnouncementCategory.techAssistance;
    return _AnnouncementCategory.none;
  }

  bool _matchesFilter(Map<String, dynamic> a) {
    if (widget.calendarType != CalendarType.techAdmin) return true;
    if (_activeFilter == _CalendarFilter.all) return true;

    final category = _getCategory(a);
    if (_activeFilter == _CalendarFilter.tagged) {
      return category == _AnnouncementCategory.tagged ||
          category == _AnnouncementCategory.both;
    }
    if (_activeFilter == _CalendarFilter.techAssistance) {
      return category == _AnnouncementCategory.techAssistance ||
          category == _AnnouncementCategory.both;
    }
    return true;
  }

  Map<int, List<Map<String, dynamic>>> get _filteredByDay {
    if (widget.calendarType != CalendarType.techAdmin ||
        _activeFilter == _CalendarFilter.all) {
      return _announcementsByDay;
    }
    final Map<int, List<Map<String, dynamic>>> result = {};
    _announcementsByDay.forEach((day, list) {
      final filtered = list.where(_matchesFilter).toList();
      if (filtered.isNotEmpty) result[day] = filtered;
    });
    return result;
  }

  String get _monthName {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  int get _daysInMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  int get _firstWeekday {
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    return firstDay.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleText,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadAnnouncements,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),

            // ── FILTER CHIPS (Tech Admin only) ──
            if (widget.calendarType == CalendarType.techAdmin) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _filterChip(
                    label: 'All',
                    filter: _CalendarFilter.all,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Tagged',
                    filter: _CalendarFilter.tagged,
                    color: Colors.blue,
                    icon: Icons.label,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Tech Assistance',
                    filter: _CalendarFilter.techAssistance,
                    color: Colors.green,
                    icon: Icons.build_circle,
                  ),
                  const SizedBox(width: 16),
                  _legendDot(Colors.blue, 'Tagged'),
                  const SizedBox(width: 10),
                  _legendDot(Colors.green, 'Tech Assist'),
                ],
              ),
            ],

            const SizedBox(height: 24),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── CALENDAR CARD ──
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [

                              // Month title
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_month,
                                      color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _monthName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Day of week headers
                              Row(
                                children: [
                                  'Sun', 'Mon', 'Tue', 'Wed',
                                  'Thu', 'Fri', 'Sat'
                                ]
                                    .map((d) => Expanded(
                                          child: Center(
                                            child: Text(
                                              d,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: d == 'Sun' ||
                                                        d == 'Sat'
                                                    ? Colors.grey.shade400
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 8),

                              _buildDayGrid(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── SELECTED DAY SECTION ──
                      if (_selectedDay != null) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDayLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((_filteredByDay[_selectedDay!.day] ?? [])
                                .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_filteredByDay[_selectedDay!.day]!.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSelectedDayList(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required _CalendarFilter filter,
    required Color color,
    IconData? icon,
  }) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13, color: isActive ? Colors.white : color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildDayGrid() {
    final filteredByDay = _filteredByDay;
    final totalCells = _firstWeekday + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final day = cellIndex - _firstWeekday + 1;

            if (day < 1 || day > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 64));
            }

            final announcements = filteredByDay[day] ?? [];
            final hasAnnouncements = announcements.isNotEmpty;
            final isToday = day == _today.day &&
                _currentMonth.month == _today.month &&
                _currentMonth.year == _today.year;
            final isSelected = _selectedDay != null &&
                day == _selectedDay!.day &&
                _currentMonth.month == _selectedDay!.month &&
                _currentMonth.year == _selectedDay!.year;
            final isWeekend = colIndex == 0 || colIndex == 6;

            Color? cellColor;
            Color? borderColor;
            if (widget.calendarType == CalendarType.techAdmin &&
                hasAnnouncements &&
                !isSelected) {
              final categories =
                  announcements.map(_getCategory).toSet();
              final hasTagged =
                  categories.contains(_AnnouncementCategory.tagged) ||
                      categories
                          .contains(_AnnouncementCategory.both);
              final hasTech = categories.contains(
                      _AnnouncementCategory.techAssistance) ||
                  categories.contains(_AnnouncementCategory.both);

              if (hasTagged) {
                cellColor = Colors.blue.withOpacity(0.07);
                borderColor = Colors.blue.withOpacity(0.3);
              } else if (hasTech) {
                cellColor = Colors.green.withOpacity(0.07);
                borderColor = Colors.green.withOpacity(0.3);
              }
            }

            return Expanded(
              child: GestureDetector(
                // ── tapping a day just selects it, no dialog ──
                onTap: () => setState(() {
                  _selectedDay = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    day,
                  );
                }),
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : isToday
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : cellColor ??
                                (hasAnnouncements
                                    ? AppTheme.primaryBlue
                                        .withOpacity(0.05)
                                    : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppTheme.primaryBlue, width: 1.5)
                        : isSelected
                            ? null
                            : hasAnnouncements
                                ? Border.all(
                                    color: borderColor ??
                                        AppTheme.primaryBlue
                                            .withOpacity(0.2))
                                : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppTheme.primaryBlue
                                  : isWeekend
                                      ? Colors.grey.shade400
                                      : null,
                        ),
                      ),
                      if (hasAnnouncements) ...[
                        const SizedBox(height: 2),
                        if (widget.calendarType ==
                                CalendarType.techAdmin &&
                            !isSelected)
                          _buildCategoryDots(announcements)
                        else if (announcements.length == 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2),
                            child: Text(
                              announcements.first['title'] ?? '',
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${announcements.length}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildCategoryDots(List<Map<String, dynamic>> announcements) {
    final categories = announcements.map(_getCategory).toSet();
    final hasTagged =
        categories.contains(_AnnouncementCategory.tagged) ||
            categories.contains(_AnnouncementCategory.both);
    final hasTech =
        categories.contains(_AnnouncementCategory.techAssistance) ||
            categories.contains(_AnnouncementCategory.both);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasTagged)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        if (hasTech)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        if (!hasTagged && !hasTech)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _dialogBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildSelectedDayList() {
    final announcements = _filteredByDay[_selectedDay!.day] ?? [];

    if (announcements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'No announcements on this day',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = announcements[index];
        final dateTime = a['dateTime'] != null
            ? (a['dateTime'] as Timestamp).toDate()
            : null;
        final category = _getCategory(a);
        final isTechAdmin =
            widget.calendarType == CalendarType.techAdmin;

        Color borderColor = Colors.grey.shade200;
        if (isTechAdmin) {
          if (category == _AnnouncementCategory.tagged) {
            borderColor = Colors.blue;
          } else if (category ==
              _AnnouncementCategory.techAssistance) {
            borderColor = Colors.green;
          } else if (category == _AnnouncementCategory.both) {
            borderColor = Colors.blue;
          }
        }

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.campaign,
                      color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (dateTime != null) ...[
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if ((a['venueName'] ?? '').isNotEmpty) ...[
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a['venueName'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isTechAdmin)
                        Wrap(
                          spacing: 4,
                          children: [
                            if (category ==
                                    _AnnouncementCategory.tagged ||
                                category ==
                                    _AnnouncementCategory.both)
                              _dialogBadge(
                                  'Tagged', Icons.label, Colors.blue),
                            if (category ==
                                    _AnnouncementCategory
                                        .techAssistance ||
                                category ==
                                    _AnnouncementCategory.both)
                              _dialogBadge('Tech Assist',
                                  Icons.build_circle, Colors.green),
                          ],
                        )
                      else if (a['needsTechAssist'] == true)
                        _dialogBadge('Tech Required',
                            Icons.build_circle, Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () =>
                      ViewAnnouncementScreen.show(context, a),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                        color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  child: const Text('View',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _subtitleText {
    switch (widget.calendarType) {
      case CalendarType.unit:
        return 'Your scheduled announcements this month';
      case CalendarType.techAdmin:
        return 'Announcements you\'re involved in this month';
      case CalendarType.viewerAdmin:
        return 'All scheduled announcements this month';
    }
  }

  String get _selectedDayLabel {
    if (_selectedDay == null) return '';
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    final isToday = _selectedDay!.day == _today.day &&
        _selectedDay!.month == _today.month &&
        _selectedDay!.year == _today.year;
    return isToday
        ? 'Today — ${months[_selectedDay!.month - 1]} ${_selectedDay!.day}'
        : '${months[_selectedDay!.month - 1]} ${_selectedDay!.day}';
  }
}