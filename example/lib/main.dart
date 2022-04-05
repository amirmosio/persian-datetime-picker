import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      home: new MyHomePage(title: 'دیت تایم پیکر فارسی'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ""}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? label;

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
        body: Row(
          children: [
            Icon(Icons.calendar_today),
            DatePickerWidget(
              initialDate: Jalali.now(),
              firstDate: Jalali(1395, 8),
              lastDate: Jalali(1445, 8, 30),
              secondaryButtonText: "11111",
              primaryButtonText: "22222",
              showHeaderWidget: false,
              onSelectedDateChanged: (Jalali? j, PageController controller) {
                print(j);
              },
              onPrimaryTap: (Jalali? j, PageController controller) {
                print(j);
              },
              onSecondaryTap: (Jalali? j, PageController controller) {
                int page = (Jalali.now().year - Jalali(1395, 8).year) * 12 +
                    Jalali.now().month -
                    Jalali(1395, 8).month;
                controller.jumpToPage(page);
              },
            ),
          ],
        ),
      ),
    );
  }
}
