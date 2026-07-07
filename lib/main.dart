import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'src/app_state.dart';
import 'src/models/panchang_data.dart';
import 'src/services/panchang_repository.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/app_chrome.dart';
import 'src/widgets/app_icon_mark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanchangCalendarApp());
}

class PanchangCalendarApp extends StatefulWidget {
  const PanchangCalendarApp({super.key});

  @override
  State<PanchangCalendarApp> createState() => _PanchangCalendarAppState();
}

class _PanchangCalendarAppState extends State<PanchangCalendarApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final theme = PanchangTheme.fromSettings(_appState.settings);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Panchang Calendar',
          theme: theme.toThemeData(),
          home: _appState.hasSeenWelcome
              ? HomeShell(appState: _appState)
              : WelcomeScreen(appState: _appState),
        );
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIconMark(size: 72),
                const SizedBox(height: 52),
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border.withValues(alpha: .5)),
                        ),
                      ),
                      ...List.generate(8, (index) {
                        return Transform.rotate(
                          angle: index * .785398,
                          child: Container(width: 1, color: colors.border.withValues(alpha: .28)),
                        );
                      }),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PANCHANG CALENDAR',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .4,
                                ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Guided by the cosmic rhythms of\nancient temporal wisdom.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  height: 1.55,
                                  color: colors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: appState.completeWelcome,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Enter Presence'),
                ),
                const SizedBox(height: 30),
                Text(
                  'VIKRAM SAMVAT 2080',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textMuted.withValues(alpha: .5),
                        letterSpacing: 4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({required this.appState, super.key});

  final AppState appState;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final PanchangRepository _repository;
  late Future<PanchangDataset> _future;

  @override
  void initState() {
    super.initState();
    _repository = PanchangRepository();
    _future = _repository.loadDataset();
  }

  void _refresh() {
    setState(() => _future = _repository.loadDataset(forceRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PanchangDataset>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? PanchangDataset.sample();
        final screens = [
          CalendarTab(dataset: data),
          TodayTab(dataset: data, onRefresh: _refresh),
          PanchangTab(dataset: data),
          SettingsTab(appState: widget.appState),
        ];
        return AppChrome(
          currentIndex: _index,
          onIndexChanged: (value) => setState(() => _index = value),
          child: screens[_index],
        );
      },
    );
  }
}

class CalendarTab extends StatelessWidget {
  const CalendarTab({required this.dataset, super.key});

  final PanchangDataset dataset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    final today = DateTime.now();
    final monthDays = dataset.monthDays;
    final highlighted = dataset.events.take(2).toList();
    return AppPage(
      trailing: const Icon(Icons.search_rounded),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMMM yyyy').format(today), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('ASHWIN • KARTIKA', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 2)),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(28)),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(children: [Icon(Icons.chevron_left), SizedBox(width: 16), Icon(Icons.chevron_right)]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CalendarCard(today: today, monthDays: monthDays),
          const SizedBox(height: 48),
          const SectionHeader(title: 'Spiritual Events', action: 'See All'),
          const SizedBox(height: 18),
          for (final event in highlighted) EventTile(event: event),
          const SizedBox(height: 28),
          const DarshanCard(),
        ],
      ),
    );
  }
}

class TodayTab extends StatelessWidget {
  const TodayTab({required this.dataset, required this.onRefresh, super.key});

  final PanchangDataset dataset;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final today = dataset.today;
    return AppPage(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
          children: [
            Center(child: Text('VIKRAM SAMVAT ${today.vikramSamvat}', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2))),
            const SizedBox(height: 10),
            Center(child: Text(DateFormat('EEEE, dd\nMMM').format(today.date), textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall)),
            const SizedBox(height: 20),
            Center(child: Text('${today.amantaMonth}, ${today.paksha}, ${today.tithi.name}', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 54),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: .95,
              children: [
                PanchangMetric(icon: Icons.brightness_5_outlined, title: 'Tithi', value: today.tithi.name, note: today.tithi.detail),
                PanchangMetric(icon: Icons.auto_awesome, title: 'Nakshatra', value: today.nakshatra.name, note: today.nakshatra.detail),
                PanchangMetric(icon: Icons.self_improvement, title: 'Yoga', value: today.yoga.name, note: today.yoga.detail),
                PanchangMetric(icon: Icons.waves_rounded, title: 'Karana', value: today.karana.name, note: today.karana.detail),
              ],
            ),
            const SizedBox(height: 34),
            SunMoonCard(day: today),
            const SizedBox(height: 28),
            Text('Auspicious & Inauspicious Times', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TimeQualityTile(icon: Icons.verified_outlined, title: 'Abhijit Muhurta', time: today.abhijit, quality: 'Auspicious'),
            TimeQualityTile(icon: Icons.error_outline, title: 'Rahu Kalam', time: today.rahuKalam, quality: 'Inauspicious'),
            TimeQualityTile(icon: Icons.schedule, title: 'Gulika Kalam', time: today.gulikaiKalam, quality: 'Neutral'),
            const TempleMistCard(),
          ],
        ),
      ),
    );
  }
}

class PanchangTab extends StatefulWidget {
  const PanchangTab({required this.dataset, super.key});

  final PanchangDataset dataset;

  @override
  State<PanchangTab> createState() => _PanchangTabState();
}

class _PanchangTabState extends State<PanchangTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Festivals', 'Vrats', 'Jayanti'];
    final events = widget.dataset.events.where((event) => _filter == 'All' || event.type.toLowerCase().contains(_filter.toLowerCase().replaceAll('s', ''))).toList();
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 120),
        children: [
          Row(
            children: [
              const Icon(Icons.chevron_left_rounded),
              const SizedBox(width: 8),
              Expanded(child: Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: Theme.of(context).textTheme.headlineSmall)),
              FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.calendar_month), label: const Text('Today')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text('ASHWIN - KARTIK', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 2)),
          ),
          const SizedBox(height: 30),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(filter), selected: _filter == filter, onSelected: (_) => setState(() => _filter = filter)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < events.length; i++) ...[
            if (i == 3) const UpcomingEventCard(),
            EventTile(event: events[i], largeDate: true),
          ],
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({required this.appState, super.key});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          const Text('Theme controls are stored locally and update the full app immediately. Language support is reserved for a future Hindi release.'),
          const SizedBox(height: 28),
          Text('Text Color', style: Theme.of(context).textTheme.titleMedium),
          ColorChoices(current: appState.settings.textColor, onChanged: appState.setTextColor),
          const SizedBox(height: 20),
          Text('Background Color', style: Theme.of(context).textTheme.titleMedium),
          ColorChoices(current: appState.settings.backgroundColor, onChanged: appState.setBackgroundColor),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: appState.settings.language == 'hi',
            onChanged: null,
            title: const Text('Hindi language'),
            subtitle: const Text('Coming later'),
          ),
        ],
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  const CalendarCard({required this.today, required this.monthDays, super.key});
  final DateTime today;
  final List<PanchangDay> monthDays;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    final first = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leading = first.weekday % 7;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(30), boxShadow: PanchangTheme.softShadow),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) => Text(d, style: Theme.of(context).textTheme.labelSmall)).toList()),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: 42,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 8),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final isToday = isCurrentMonth && dayNumber == today.day;
              final hasEvent = monthDays.any((day) => day.date.day == dayNumber && day.events.isNotEmpty);
              return CalendarDayCell(day: isCurrentMonth ? dayNumber : null, isToday: isToday, hasEvent: hasEvent);
            },
          ),
        ],
      ),
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({required this.day, required this.isToday, required this.hasEvent, super.key});
  final int? day;
  final bool isToday;
  final bool hasEvent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    if (day == null) return const SizedBox.shrink();
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isToday) Container(decoration: BoxDecoration(shape: BoxShape.circle, color: colors.accent)),
        Text('$day', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: isToday ? FontWeight.w800 : FontWeight.w500)),
        if (hasEvent) Positioned(bottom: 2, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle))),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.action, super.key});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), Text(action, style: TextStyle(color: Theme.of(context).extension<PanchangColors>()!.primary, fontWeight: FontWeight.w700))]);
}

class EventTile extends StatelessWidget {
  const EventTile({required this.event, this.largeDate = false, super.key});
  final PanchangEvent event;
  final bool largeDate;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(26), boxShadow: PanchangTheme.softShadow),
      child: Row(
        children: [
          CircleAvatar(
            radius: largeDate ? 32 : 28,
            backgroundColor: Colors.white,
            child: largeDate ? Text(DateFormat('dd\nEEE').format(event.date).toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800)) : Icon(Icons.local_florist, color: colors.primary),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.primary)), const SizedBox(height: 4), Text('${DateFormat('MMM dd').format(event.date)} • ${event.detail}') ])),
          Icon(Icons.chevron_right_rounded, color: colors.border),
        ],
      ),
    );
  }
}

class PanchangMetric extends StatelessWidget {
  const PanchangMetric({required this.icon, required this.title, required this.value, required this.note, super.key});
  final IconData icon;
  final String title;
  final String value;
  final String note;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), boxShadow: PanchangTheme.softShadow),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: colors.primary), const SizedBox(height: 18), Text(title), const SizedBox(height: 8), Text(value, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), Text(note, textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted))]),
    );
  }
}

class SunMoonCard extends StatelessWidget {
  const SunMoonCard({required this.day, super.key});
  final PanchangDay day;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), boxShadow: PanchangTheme.softShadow),
      child: Row(children: [Icon(Icons.wb_twilight_rounded, color: colors.primary), const SizedBox(width: 18), Expanded(child: Text('Sunrise\n${day.sunrise}', style: Theme.of(context).textTheme.titleLarge)), Expanded(child: Text('Sunset\n${day.sunset}', textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleLarge)), const SizedBox(width: 18), Icon(Icons.nightlight_round, color: colors.primary)]),
    );
  }
}

class TimeQualityTile extends StatelessWidget {
  const TimeQualityTile({required this.icon, required this.title, required this.time, required this.quality, super.key});
  final IconData icon;
  final String title;
  final String time;
  final String quality;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PanchangColors>()!;
    final color = quality == 'Auspicious' ? Colors.cyan : quality == 'Inauspicious' ? Colors.red : Colors.brown.shade200;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), boxShadow: PanchangTheme.softShadow, border: Border(left: BorderSide(color: color, width: 4))),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(time)])), Chip(label: Text(quality), backgroundColor: color.withValues(alpha: .12))]),
    );
  }
}

class DarshanCard extends StatelessWidget {
  const DarshanCard({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 210, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.brown.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight)), alignment: Alignment.bottomLeft, padding: const EdgeInsets.all(20), child: const Text('Darshan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)));
}

class TempleMistCard extends StatelessWidget {
  const TempleMistCard({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 190, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)), child: Icon(Icons.temple_hindu_rounded, size: 110, color: Colors.brown.withValues(alpha: .16)));
}

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 168, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: [Colors.black.withValues(alpha: .72), Colors.orange.shade200], begin: Alignment.bottomLeft, end: Alignment.topRight)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text('UPCOMING MAJOR EVENT', style: TextStyle(color: Colors.white70, letterSpacing: 2)), SizedBox(height: 10), Text('Deepawali: Festival\nof Lights', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Oct 31, 2024 • Kartik Amavasya', style: TextStyle(color: Colors.white70))]));
}

class ColorChoices extends StatelessWidget {
  const ColorChoices({required this.current, required this.onChanged, super.key});
  final int current;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    const choices = [0xff9a4f00, 0xff402b25, 0xff0f766e, 0xff7c2d12, 0xfff9f4ed, 0xfffffbf5];
    return Wrap(spacing: 12, children: [for (final color in choices) GestureDetector(onTap: () => onChanged(color), child: Container(width: 42, height: 42, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle, border: Border.all(width: current == color ? 4 : 1, color: Theme.of(context).extension<PanchangColors>()!.primary))))]);
  }
}
