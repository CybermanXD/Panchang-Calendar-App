import 'package:intl/intl.dart';

class PanchangDataset {
  const PanchangDataset({
    required this.year,
    required this.generatedAt,
    required this.sourceUrls,
    required this.today,
    required this.monthDays,
    required this.events,
  });

  final int year;
  final DateTime generatedAt;
  final List<String> sourceUrls;
  final PanchangDay today;
  final List<PanchangDay> monthDays;
  final List<PanchangEvent> events;

  factory PanchangDataset.fromJson(Map<String, dynamic> json) {
    if (json['days'] is Map) {
      final parsedDays = <PanchangDay>[];
      (json['days'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedDays.add(PanchangDay.fromNewJson(key.toString(), value));
        } else if (value is Map) {
          parsedDays.add(PanchangDay.fromNewJson(key.toString(), Map<String, dynamic>.from(value)));
        }
      });
      parsedDays.sort((a, b) => a.date.compareTo(b.date));
      final now = DateTime.now();
      final today = parsedDays.firstWhere(
        (day) => day.date.year == now.year && day.date.month == now.month && day.date.day == now.day,
        orElse: () => parsedDays.isNotEmpty ? parsedDays.first : PanchangDay.sample(now),
      );
      final allEvents = parsedDays.expand((day) => day.events).toList()..sort((a, b) => a.date.compareTo(b.date));
      return PanchangDataset(
        year: int.tryParse(json['year']?.toString() ?? '') ?? today.date.year,
        generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
        sourceUrls: List<String>.from(json['sourceUrls'] ?? const []),
        today: today,
        monthDays: parsedDays,
        events: allEvents,
      );
    }
    final monthDays = (json['monthDays'] as List? ?? const []).map((value) => PanchangDay.fromJson(value as Map<String, dynamic>)).toList();
    return PanchangDataset(
      year: monthDays.isNotEmpty ? monthDays.first.date.year : DateTime.now().year,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      sourceUrls: List<String>.from(json['sourceUrls'] ?? const []),
      today: PanchangDay.fromJson(json['today'] as Map<String, dynamic>),
      monthDays: monthDays,
      events: (json['events'] as List? ?? const []).map((value) => PanchangEvent.fromJson(value as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'generatedAt': generatedAt.toIso8601String(),
        'sourceUrls': sourceUrls,
        'days': {for (final day in monthDays) DateFormat('yyyy-MM-dd').format(day.date): day.toNewJson()},
      };

  factory PanchangDataset.sample() {
    final now = DateTime.now();
    final today = PanchangDay.sample(now);
    final events = [
      PanchangEvent(date: DateTime(now.year, now.month, 3), title: 'Sharad Navratri Begins', detail: 'Pratipada Tithi', type: 'Festival'),
      PanchangEvent(date: DateTime(now.year, now.month, 11), title: 'Maha Ashtami', detail: 'Ashtami Tithi', type: 'Vrat'),
    ];
    return PanchangDataset(
      year: now.year,
      generatedAt: DateTime.now(),
      sourceUrls: const ['https://www.drikpanchang.com/panchang/month-panchang.html'],
      today: today,
      monthDays: List.generate(DateTime(now.year, now.month + 1, 0).day, (index) {
        final date = DateTime(now.year, now.month, index + 1);
        return PanchangDay.sample(date).copyWith(events: events.where((event) => event.date.day == date.day).toList());
      }),
      events: events,
    );
  }
}

class PanchangDay {
  const PanchangDay({
    required this.date,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.shakaSamvat,
    required this.vikramSamvat,
    required this.gujaratiSamvat,
    required this.amantaMonth,
    required this.purnimantaMonth,
    required this.weekday,
    required this.paksha,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.pravishte,
    required this.sunsign,
    required this.moonsign,
    required this.rahuKalam,
    required this.gulikaiKalam,
    required this.yamaganda,
    required this.abhijit,
    required this.durMuhurtam,
    required this.amritKalam,
    required this.events,
  });

  final DateTime date;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String shakaSamvat;
  final String vikramSamvat;
  final String gujaratiSamvat;
  final String amantaMonth;
  final String purnimantaMonth;
  final String weekday;
  final String paksha;
  final PanchangValue tithi;
  final PanchangValue nakshatra;
  final PanchangValue yoga;
  final PanchangValue karana;
  final String pravishte;
  final String sunsign;
  final String moonsign;
  final String rahuKalam;
  final String gulikaiKalam;
  final String yamaganda;
  final String abhijit;
  final String durMuhurtam;
  final String amritKalam;
  final List<PanchangEvent> events;

  PanchangDay copyWith({List<PanchangEvent>? events}) => PanchangDay(
        date: date,
        sunrise: sunrise,
        sunset: sunset,
        moonrise: moonrise,
        moonset: moonset,
        shakaSamvat: shakaSamvat,
        vikramSamvat: vikramSamvat,
        gujaratiSamvat: gujaratiSamvat,
        amantaMonth: amantaMonth,
        purnimantaMonth: purnimantaMonth,
        weekday: weekday,
        paksha: paksha,
        tithi: tithi,
        nakshatra: nakshatra,
        yoga: yoga,
        karana: karana,
        pravishte: pravishte,
        sunsign: sunsign,
        moonsign: moonsign,
        rahuKalam: rahuKalam,
        gulikaiKalam: gulikaiKalam,
        yamaganda: yamaganda,
        abhijit: abhijit,
        durMuhurtam: durMuhurtam,
        amritKalam: amritKalam,
        events: events ?? this.events,
      );

  factory PanchangDay.fromNewJson(String isoDate, Map<String, dynamic> json) {
    final date = DateTime.parse(isoDate);
    final panchang = (json['panchang'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final sun = (panchang['sun'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final moon = (panchang['moon'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final calendar = (panchang['calendar'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final zodiac = (panchang['zodiac'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final timings = (panchang['timings'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final karanas = (panchang['karana'] as List? ?? const []).map(PanchangValue.fromJson).toList();
    return PanchangDay(
      date: date,
      sunrise: sun['sunrise']?.toString() ?? '',
      sunset: sun['sunset']?.toString() ?? '',
      moonrise: moon['moonrise']?.toString() ?? '',
      moonset: moon['moonset']?.toString() ?? '',
      shakaSamvat: _samvatText(calendar['shakaSamvat']),
      vikramSamvat: _samvatText(calendar['vikramSamvat']),
      gujaratiSamvat: _samvatText(calendar['gujaratiSamvat']),
      amantaMonth: calendar['amantaMonth']?.toString() ?? '',
      purnimantaMonth: calendar['purnimantaMonth']?.toString() ?? '',
      weekday: json['weekday']?.toString() ?? DateFormat('EEEE').format(date),
      paksha: calendar['paksha']?.toString() ?? '',
      tithi: PanchangValue.fromJson(panchang['tithi']),
      nakshatra: PanchangValue.fromJson(panchang['nakshatra']),
      yoga: PanchangValue.fromJson(panchang['yoga']),
      karana: karanas.isNotEmpty ? karanas.first : const PanchangValue(name: '', detail: ''),
      pravishte: calendar['pravishte']?.toString() ?? '',
      sunsign: _zodiacText(zodiac['sunSign']),
      moonsign: _zodiacText(zodiac['moonSign']),
      rahuKalam: _rangeText(timings['rahuKalam']),
      gulikaiKalam: _rangeText(timings['gulikaiKalam']),
      yamaganda: _rangeText(timings['yamaganda']),
      abhijit: _rangeText(timings['abhijit'], fallback: 'None'),
      durMuhurtam: _rangeText(timings['durMuhurtam']),
      amritKalam: _rangeText(timings['amritKalam']),
      events: (json['events'] as List? ?? const []).map((value) => PanchangEvent.fromNewJson(date, value as Map<String, dynamic>)).toList(),
    );
  }

  factory PanchangDay.fromJson(Map<String, dynamic> json) => PanchangDay(
        date: DateTime.parse(json['date'].toString()),
        sunrise: json['sunrise']?.toString() ?? '',
        sunset: json['sunset']?.toString() ?? '',
        moonrise: json['moonrise']?.toString() ?? '',
        moonset: json['moonset']?.toString() ?? '',
        shakaSamvat: json['shakaSamvat']?.toString() ?? '',
        vikramSamvat: json['vikramSamvat']?.toString() ?? '',
        gujaratiSamvat: json['gujaratiSamvat']?.toString() ?? '',
        amantaMonth: json['amantaMonth']?.toString() ?? '',
        purnimantaMonth: json['purnimantaMonth']?.toString() ?? '',
        weekday: json['weekday']?.toString() ?? '',
        paksha: json['paksha']?.toString() ?? '',
        tithi: PanchangValue.fromJson(json['tithi']),
        nakshatra: PanchangValue.fromJson(json['nakshatra']),
        yoga: PanchangValue.fromJson(json['yoga']),
        karana: PanchangValue.fromJson(json['karana']),
        pravishte: json['pravishte']?.toString() ?? '',
        sunsign: json['sunsign']?.toString() ?? '',
        moonsign: json['moonsign']?.toString() ?? '',
        rahuKalam: json['rahuKalam']?.toString() ?? '',
        gulikaiKalam: json['gulikaiKalam']?.toString() ?? '',
        yamaganda: json['yamaganda']?.toString() ?? '',
        abhijit: json['abhijit']?.toString() ?? 'None',
        durMuhurtam: json['durMuhurtam']?.toString() ?? '',
        amritKalam: json['amritKalam']?.toString() ?? '',
        events: (json['events'] as List? ?? const []).map((value) => PanchangEvent.fromJson(value as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toNewJson() => {
        'month': date.month,
        'monthName': DateFormat('MMMM').format(date),
        'day': date.day,
        'weekday': weekday,
        'panchang': {
          'sun': {'sunrise': sunrise, 'sunset': sunset},
          'moon': {'moonrise': moonrise, 'moonset': moonset},
          'calendar': {'amantaMonth': amantaMonth, 'purnimantaMonth': purnimantaMonth, 'paksha': paksha, 'pravishte': pravishte},
          'tithi': tithi.toJson(),
          'nakshatra': nakshatra.toJson(),
          'yoga': yoga.toJson(),
          'karana': [karana.toJson()],
          'zodiac': {'sunSign': {'name': sunsign}, 'moonSign': {'name': moonsign}},
          'timings': {
            'rahuKalam': _rangeJson(rahuKalam),
            'gulikaiKalam': _rangeJson(gulikaiKalam),
            'yamaganda': _rangeJson(yamaganda),
            'abhijit': _rangeJson(abhijit),
            'durMuhurtam': _rangeJson(durMuhurtam),
            'amritKalam': _rangeJson(amritKalam),
          },
        },
        'events': events.map((event) => event.toNewJson()).toList(),
      };

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'sunrise': sunrise,
        'sunset': sunset,
        'moonrise': moonrise,
        'moonset': moonset,
        'shakaSamvat': shakaSamvat,
        'vikramSamvat': vikramSamvat,
        'gujaratiSamvat': gujaratiSamvat,
        'amantaMonth': amantaMonth,
        'purnimantaMonth': purnimantaMonth,
        'weekday': weekday,
        'paksha': paksha,
        'tithi': tithi.toJson(),
        'nakshatra': nakshatra.toJson(),
        'yoga': yoga.toJson(),
        'karana': karana.toJson(),
        'pravishte': pravishte,
        'sunsign': sunsign,
        'moonsign': moonsign,
        'rahuKalam': rahuKalam,
        'gulikaiKalam': gulikaiKalam,
        'yamaganda': yamaganda,
        'abhijit': abhijit,
        'durMuhurtam': durMuhurtam,
        'amritKalam': amritKalam,
        'events': events.map((event) => event.toJson()).toList(),
      };

  factory PanchangDay.sample(DateTime date) => PanchangDay(
        date: date,
        sunrise: '06:24 AM',
        sunset: '05:58 PM',
        moonrise: '12:30 AM',
        moonset: '01:11 PM',
        shakaSamvat: '1948 Parabhava',
        vikramSamvat: '2083 Siddharthi',
        gujaratiSamvat: '2082 Pingala',
        amantaMonth: 'Ashwin',
        purnimantaMonth: 'Kartika',
        weekday: DateFormat('EEEE').format(date),
        paksha: 'Shukla Paksha',
        tithi: const PanchangValue(name: 'Dashami', detail: 'Ends 03:14 PM'),
        nakshatra: const PanchangValue(name: 'Dhanishta', detail: 'Till 05:42 PM'),
        yoga: const PanchangValue(name: 'Vriddhi', detail: 'Till 02:30 AM'),
        karana: const PanchangValue(name: 'Gara', detail: 'Till 03:14 PM'),
        pravishte: '24',
        sunsign: 'Mithuna',
        moonsign: 'Meena upto 04:00 PM',
        rahuKalam: '03:04 PM - 04:31 PM',
        gulikaiKalam: '12:11 PM - 01:38 PM',
        yamaganda: '07:16 AM - 09:02 AM',
        abhijit: '11:43 AM - 12:28 PM',
        durMuhurtam: '12:07 PM - 01:04 PM',
        amritKalam: '01:38 PM - 03:13 PM',
        events: const [],
      );
}

class PanchangValue {
  const PanchangValue({required this.name, required this.detail});
  final String name;
  final String detail;

  factory PanchangValue.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return PanchangValue(name: json['name']?.toString() ?? '', detail: json['detail']?.toString() ?? json['endsAtText']?.toString() ?? '');
    }
    return PanchangValue(name: json?.toString() ?? '', detail: '');
  }

  Map<String, dynamic> toJson() => {'name': name, if (detail.isNotEmpty) 'endsAtText': detail};
}

class PanchangEvent {
  const PanchangEvent({required this.date, required this.title, required this.detail, required this.type});

  final DateTime date;
  final String title;
  final String detail;
  final String type;

  factory PanchangEvent.fromNewJson(DateTime date, Map<String, dynamic> json) => PanchangEvent(
        date: date,
        title: json['title']?.toString() ?? '',
        detail: json['description']?.toString() ?? '',
        type: json['category']?.toString() ?? 'Festival',
      );

  factory PanchangEvent.fromJson(Map<String, dynamic> json) => PanchangEvent(
        date: DateTime.parse(json['date'].toString()),
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? json['category']?.toString() ?? 'Festival',
      );

  Map<String, dynamic> toNewJson() => {'title': title, 'category': type, 'description': detail};

  Map<String, dynamic> toJson() => {'date': DateFormat('yyyy-MM-dd').format(date), 'title': title, 'detail': detail, 'type': type};
}

String _samvatText(dynamic value) {
  if (value is Map) {
    final year = value['year']?.toString() ?? '';
    final name = value['name']?.toString() ?? '';
    return [year, name].where((part) => part.isNotEmpty && part != 'null').join(' ');
  }
  return value?.toString() ?? '';
}

String _zodiacText(dynamic value) {
  if (value is Map) {
    final name = value['name']?.toString() ?? '';
    final until = value['untilText']?.toString() ?? '';
    return [name, until].where((part) => part.isNotEmpty && part != 'null').join(' ');
  }
  return value?.toString() ?? '';
}

String _rangeText(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is Map) {
    final start = value['start']?.toString() ?? '';
    final end = value['end']?.toString() ?? '';
    return start.isNotEmpty && end.isNotEmpty ? '$start - $end' : fallback;
  }
  return value.toString();
}

Map<String, String>? _rangeJson(String value) {
  final parts = value.split(' - ');
  return parts.length == 2 ? {'start': parts.first, 'end': parts.last} : null;
}
