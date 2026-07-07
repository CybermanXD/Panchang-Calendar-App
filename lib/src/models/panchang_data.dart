import 'package:intl/intl.dart';

class PanchangDataset {
  const PanchangDataset({
    required this.generatedAt,
    required this.sourceUrls,
    required this.today,
    required this.monthDays,
    required this.events,
  });

  final DateTime generatedAt;
  final List<String> sourceUrls;
  final PanchangDay today;
  final List<PanchangDay> monthDays;
  final List<PanchangEvent> events;

  factory PanchangDataset.fromJson(Map<String, dynamic> json) {
    return PanchangDataset(
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      sourceUrls: List<String>.from(json['sourceUrls'] ?? const []),
      today: PanchangDay.fromJson(json['today'] as Map<String, dynamic>),
      monthDays: (json['monthDays'] as List? ?? const []).map((value) => PanchangDay.fromJson(value as Map<String, dynamic>)).toList(),
      events: (json['events'] as List? ?? const []).map((value) => PanchangEvent.fromJson(value as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'sourceUrls': sourceUrls,
        'today': today.toJson(),
        'monthDays': monthDays.map((day) => day.toJson()).toList(),
        'events': events.map((event) => event.toJson()).toList(),
      };

  factory PanchangDataset.sample() {
    final now = DateTime.now();
    final today = PanchangDay.sample(now);
    final events = [
      PanchangEvent(date: DateTime(now.year, now.month, 3), title: 'Sharad Navratri Begins', detail: 'Pratipada Tithi', type: 'Festival'),
      PanchangEvent(date: DateTime(now.year, now.month, 11), title: 'Maha Ashtami', detail: 'Ashtami Tithi', type: 'Vrat'),
      PanchangEvent(date: DateTime(now.year, now.month, 12), title: 'Dussehra / Vijayadashami', detail: 'Dashami Tithi', type: 'Festival'),
      PanchangEvent(date: DateTime(now.year, now.month, 20), title: 'Karwa Chauth', detail: 'Chaturthi Tithi', type: 'Vrat'),
      PanchangEvent(date: DateTime(now.year, now.month, 29), title: 'Dhanteras', detail: 'Trayodashi Tithi', type: 'Festival'),
      PanchangEvent(date: DateTime(now.year, now.month, 31), title: 'Naraka Chaturdashi', detail: 'Chaturdashi Tithi', type: 'Festival'),
    ];
    return PanchangDataset(
      generatedAt: DateTime.now(),
      sourceUrls: const [
        'https://www.drikpanchang.com/panchang/month-panchang.html',
        'https://www.drikpanchang.com/panchang/day-panchang.html',
        'https://www.drikpanchang.com/calendars/hindu/hinducalendar.html',
      ],
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
      return PanchangValue(name: json['name']?.toString() ?? '', detail: json['detail']?.toString() ?? '');
    }
    return PanchangValue(name: json?.toString() ?? '', detail: '');
  }

  Map<String, dynamic> toJson() => {'name': name, 'detail': detail};
}

class PanchangEvent {
  const PanchangEvent({required this.date, required this.title, required this.detail, required this.type});

  final DateTime date;
  final String title;
  final String detail;
  final String type;

  factory PanchangEvent.fromJson(Map<String, dynamic> json) => PanchangEvent(
        date: DateTime.parse(json['date'].toString()),
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Festival',
      );

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'title': title,
        'detail': detail,
        'type': type,
      };
}
