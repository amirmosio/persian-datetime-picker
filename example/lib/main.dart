import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

final ThemeData androidTheme = new ThemeData(
  fontFamily: 'SG-Main',
);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: androidTheme,
      home: new MyHomePage(key: super.key, title: 'دیت تایم پیکر فارسی'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String label = '';

  String selectedDate = Jalali.now().toJalaliDateTime();

  @override
  void initState() {
    super.initState();
    label = 'انتخاب تاریخ زمان';
  }

  @override
  Widget build(BuildContext context) {
    return new Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Wrap(
          children: [
            TextButton(
                onPressed: () async {
                  await showPersianDatePicker(
                    context: context,
                    initialDate: Jalali.now(),
                    firstDate: Jalali(1385, 8),
                    lastDate: Jalali(1450, 9),
                  );
                },
                child: Text("Date Picker")),
            Container(
              width: 333,
              color: Colors.greenAccent,
              child: PCalendarDatePicker(
                initialDate: Jalali.now(),
                firstDate: Jalali(1385, 8),
                lastDate: Jalali(1450, 9),
                primaryButtonText: "apply",
                secondaryButtonText: "go to now",
                onPrimaryTap: (p1) {},
                onSecondaryTap: (p1) {
                  int page = (Jalali.now().year - Jalali(1385, 8).year) * 12 +
                      Jalali.now().month -
                      Jalali(1385, 8).month;
                  p1.jumpToPage(page);
                },
                initialCalendarMode: PDatePickerMode.day,
                onDateChanged: (value) {
                  print(value);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
