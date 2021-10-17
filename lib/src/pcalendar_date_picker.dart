// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:persian_datetime_picker/src/date/shamsi_date.dart';

import './pdate_utils.dart';
import 'pdate_picker_common.dart';
import 'pdate_utils.dart' as utils;

const Duration _monthScrollDuration = Duration(milliseconds: 200);

const double _dayPickerRowHeight = 40.0;
const int _maxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// One extra row for the day-of-week header.
const double _maxDayPickerHeight =
    _dayPickerRowHeight * (_maxDayPickerRowCount + 1);
const double _maxDayPickerWidth = 320;
const double _monthPickerHorizontalPadding = 16.0;

const double _subHeaderHeight = 30.0;

/// Displays a grid of days for a given month and allows the user to select a date.
///
/// Days are arranged in a rectangular grid with one column for each day of the
/// week. Controls are provided to change the year and month that the grid is
/// showing.
///
/// The calendar picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which will create a dialog that uses this as well as provides
/// a text entry option.
///
/// See also:
///
///  * [showDatePicker], which creates a Dialog that contains a [CalendarDatePicker]
///    and provides an optional compact view where the user can enter a date as
///    a line of text.
///  * [showTimePicker], which shows a dialog that contains a material design
///    time picker.
///
class PCalendarDatePicker extends StatefulWidget {
  /// Creates a calender date picker
  ///
  /// It will display a grid of days for the [initialDate]'s month. The day
  /// indicated by [initialDate] will be selected.
  ///
  /// The optional [onDisplayedMonthChanged] callback can be used to track
  /// the currently displayed month.
  ///
  /// The user interface provides a way to change the year of the month being
  /// displayed. By default it will show the day grid, but this can be changed
  /// to start in the year selection interface with [initialCalendarMode] set
  /// to [PDatePickerMode.year].
  ///
  /// The [initialDate], [firstDate], [lastDate], [onDateChanged], and
  /// [initialCalendarMode] must be non-null.
  ///
  /// [lastDate] must be after or equal to [firstDate].
  ///
  /// [initialDate] must be between [firstDate] and [lastDate] or equal to
  /// one of them.
  ///
  /// If [selectableDayPredicate] is non-null, it must return `true` for the
  /// [initialDate].
  PCalendarDatePicker({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.pageController,
    this.onDisplayedMonthChanged,
    this.selectableDayPredicate,
  }) : super(key: key) {
    assert(!this.lastDate.isBefore(this.firstDate),
        'lastDate ${this.lastDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isBefore(this.firstDate),
        'initialDate ${this.initialDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isAfter(this.lastDate),
        'initialDate ${this.initialDate} must be on or before lastDate ${this.lastDate}.');
    assert(
        selectableDayPredicate == null ||
            selectableDayPredicate!(this.initialDate),
        'Provided initialDate ${this.initialDate} must satisfy provided selectableDayPredicate.');
  }

  /// month page view controller
  final PageController pageController;

  /// The initially selected [Jalali] that the picker should display.
  final Jalali initialDate;

  /// The earliest allowable [Jalali] that the user can select.
  final Jalali firstDate;

  /// The latest allowable [Jalali] that the user can select.
  final Jalali lastDate;

  /// Called when the user selects a date in the picker.
  final ValueChanged<Jalali?> onDateChanged;

  /// Called when the user navigates to a new month/year in the picker.
  final ValueChanged<Jalali?>? onDisplayedMonthChanged;

  /// Function to provide full control over which dates in the calendar can be selected.
  final PSelectableDayPredicate? selectableDayPredicate;

  @override
  _CalendarDatePickerState createState() => _CalendarDatePickerState();
}

class _CalendarDatePickerState extends State<PCalendarDatePicker> {
  bool _announcedInitialDate = false;
  Jalali? _currentDisplayedMonthYearDate;
  Jalali? _selectedDate;
  final GlobalKey _monthPickerKey = GlobalKey();
  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _currentDisplayedMonthYearDate =
        Jalali(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        formatFullDate(_selectedDate!),
        _textDirection,
      );
    }
  }

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleMonthChanged(Jalali? date) {
    setState(() {
      if (_currentDisplayedMonthYearDate!.year != date!.year ||
          _currentDisplayedMonthYearDate!.month != date.month) {
        _currentDisplayedMonthYearDate = Jalali(date.year, date.month);
        widget.onDisplayedMonthChanged?.call(_currentDisplayedMonthYearDate);
      }
    });
  }

  void _handleDayChanged(Jalali value) {
    _vibrate();
    setState(() {
      _selectedDate = value;
      widget.onDateChanged.call(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _maxDayPickerWidth,
      height: _maxDayPickerHeight,
      child: _MonthPicker(
        key: _monthPickerKey,
        initialMonthYear: _currentDisplayedMonthYearDate,
        currentDate: Jalali.now(),
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        selectedDate: _selectedDate!,
        onChanged: _handleDayChanged,
        onDisplayedMonthChanged: _handleMonthChanged,
        selectableDayPredicate: widget.selectableDayPredicate,
        pageController: widget.pageController,
      ),
    );
  }
}

class _MonthPicker extends StatefulWidget {
  /// Creates a month picker.
  _MonthPicker({
    Key? key,
    required this.initialMonthYear,
    required this.currentDate,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.onChanged,
    required this.onDisplayedMonthChanged,
    required this.pageController,
    this.selectableDayPredicate,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(!selectedDate.isBefore(firstDate)),
        assert(!selectedDate.isAfter(lastDate)),
        super(key: key);

  PageController pageController;

  /// The initial month to display
  final Jalali? initialMonthYear;

  /// The current date.
  ///
  /// This date is subtly highlighted in the picker.
  final Jalali currentDate;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [lastDate].
  final Jalali firstDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [firstDate].
  final Jalali lastDate;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final Jalali selectedDate;

  /// Called when the user picks a day.
  final ValueChanged<Jalali> onChanged;

  /// Called when the user navigates to a new month
  final ValueChanged<Jalali?> onDisplayedMonthChanged;

  /// Optional user supplied predicate function to customize selectable days.
  final PSelectableDayPredicate? selectableDayPredicate;

  @override
  State<StatefulWidget> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  Jalali? _currentMonthYear;

  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _currentMonthYear = widget.initialMonthYear;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleMonthPageChanged(int monthPage) {
    final Jalali monthDate =
        utils.addMonthsToMonthDate(widget.firstDate, monthPage);
    if (_currentMonthYear!.year != monthDate.year ||
        _currentMonthYear!.month != monthDate.month) {
      _currentMonthYear = Jalali(monthDate.year, monthDate.month);
      widget.onDisplayedMonthChanged.call(_currentMonthYear);
    }
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
        formatMonthYear(utils.addMonthsToMonthDate(_currentMonthYear!, 1)),
        _textDirection,
      );
      widget.pageController.nextPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handleNextYear() {
    if (!_isDisplayingLastYear) {
      SemanticsService.announce(
        formatMonthYear(utils.addMonthsToMonthDate(_currentMonthYear!, 12)),
        _textDirection,
      );
      widget.pageController.animateToPage(
          widget.pageController.page!.round() + 12,
          duration: _monthScrollDuration,
          curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
        formatMonthYear(utils.addMonthsToMonthDate(_currentMonthYear!, -1)),
        _textDirection,
      );
      widget.pageController.previousPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handlePreviousYear() {
    if (!_isDisplayingFirstYear) {
      SemanticsService.announce(
        formatMonthYear(utils.addMonthsToMonthDate(_currentMonthYear!, -12)),
        _textDirection,
      );
      widget.pageController.animateToPage(
          widget.pageController.page!.round() - 12,
          duration: _monthScrollDuration,
          curve: Curves.ease);
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentMonthYear!.isAfter(
      Jalali(widget.firstDate.year, widget.firstDate.month),
    );
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentMonthYear!.isBefore(
      Jalali(widget.lastDate.year, widget.lastDate.month),
    );
  }

  /// True if the earliest allowable year is displayed.
  bool get _isDisplayingFirstYear {
    return !_currentMonthYear!.isAfter(
      Jalali(widget.firstDate.year),
    );
  }

  /// True if the latest allowable year is displayed.
  bool get _isDisplayingLastYear {
    return !_currentMonthYear!.isBefore(
      Jalali(widget.lastDate.year),
    );
  }

  Widget _buildItems(BuildContext context, int index) {
    final Jalali month = utils.addMonthsToMonthDate(widget.firstDate, index);
    return _DayPicker(
      key: ValueKey<Jalali>(month),
      selectedDate: widget.selectedDate,
      currentDate: widget.currentDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String previousTooltipText =
        'ماه قبل ${utils.addMonthsToMonthDate(_currentMonthYear!, -1).formatMonthYear()}';
    final String nextTooltipText =
        'ماه بعد ${utils.addMonthsToMonthDate(_currentMonthYear!, 1).formatMonthYear}';
    final Color controlColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.60);

    return Semantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
            height: _subHeaderHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Image.asset(
                    "assets/images/double_chevron_left.png",
                    color: Colors.grey,
                    width: 24,
                    height: 24,
                  ),
                  color: controlColor,
                  tooltip: _isDisplayingFirstYear ? null : previousTooltipText,
                  onPressed:
                  _isDisplayingFirstYear ? null : _handlePreviousYear,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: controlColor,
                  tooltip: _isDisplayingFirstMonth ? null : previousTooltipText,
                  onPressed:
                      _isDisplayingFirstMonth ? null : _handlePreviousMonth,
                ),
                Text(
                  (_currentMonthYear?.formatter.mN.toString() ?? "") +
                      "  " +
                      (_currentMonthYear?.formatter.y.toString() ?? ""),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: controlColor,
                  tooltip: _isDisplayingLastMonth ? null : nextTooltipText,
                  onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
                ),
                IconButton(
                  icon: Row(
                    children: [
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  color: controlColor,
                  tooltip: _isDisplayingLastYear ? null : nextTooltipText,
                  onPressed: _isDisplayingLastYear ? null : _handleNextYear,
                ),
              ],
            ),
          ),
          _DayHeaders(),
          Expanded(
            child: PageView.builder(
              controller: widget.pageController,
              itemBuilder: _buildItems,
              itemCount:
                  utils.monthDelta(widget.firstDate, widget.lastDate) + 1,
              scrollDirection: Axis.horizontal,
              onPageChanged: _handleMonthPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
class _DayPicker extends StatelessWidget {
  /// Creates a day picker.
  _DayPicker({
    Key? key,
    required this.currentDate,
    required this.displayedMonth,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.onChanged,
    this.selectableDayPredicate,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(!selectedDate.isBefore(firstDate)),
        assert(!selectedDate.isAfter(lastDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final Jalali selectedDate;

  /// The current date at the time the picker is displayed.
  final Jalali currentDate;

  /// Called when the user picks a day.
  final ValueChanged<Jalali> onChanged;

  /// The earliest date the user is permitted to pick.
  ///
  /// This date must be on or before the [lastDate].
  final Jalali firstDate;

  /// The latest date the user is permitted to pick.
  ///
  /// This date must be on or after the [firstDate].
  final Jalali lastDate;

  /// The month whose days are displayed by this picker.
  final Jalali displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final PSelectableDayPredicate? selectableDayPredicate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? dayStyle = textTheme.caption;
    final Color enabledDayColor = colorScheme.onSurface.withOpacity(0.87);
    final Color disabledDayColor = colorScheme.onSurface.withOpacity(0.38);
    final Color selectedDayColor = colorScheme.onPrimary;
    final Color selectedDayBackground = colorScheme.primary;
    final Color todayColor = colorScheme.primary;

    final int year = displayedMonth.year;
    final int month = displayedMonth.month;

    final int daysInMonth = utils.getDaysInMonth(year, month);
    final int dayOffset = utils.firstDayOffset(year, month);

    final List<Widget> dayItems = <Widget>[];
    // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
    // a leap year.
    int day = -dayOffset;
    while (day < daysInMonth) {
      day++;
      if (day < 1) {
        dayItems.add(Container());
      } else {
        final Jalali dayToBuild = Jalali(year, month, day);
        final bool isDisabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));

        BoxDecoration? decoration;
        Color dayColor = enabledDayColor;
        final bool isSelectedDay = utils.isSameDay(selectedDate, dayToBuild);
        if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a
          // contrasting text color.
          dayColor = selectedDayColor;
          decoration = BoxDecoration(
              color: selectedDayBackground,
              borderRadius: BorderRadius.circular(8));
        } else if (isDisabled) {
          dayColor = disabledDayColor;
        } else if (utils.isSameDay(currentDate, dayToBuild)) {
          // The current day gets a different text color and a circle stroke
          // border.
          dayColor = todayColor;
          decoration = BoxDecoration(
            border: Border.all(color: todayColor, width: 1),
            borderRadius: BorderRadius.circular(8),
          );
        }

        Widget dayWidget = Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Container(
            decoration: decoration,
            child: Center(
              child: Text(formatDecimal(day),
                  style: dayStyle!.apply(color: dayColor)),
            ),
          ),
        );

        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        } else {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(dayToBuild),
            child: Semantics(
              // We want the day of month to be spoken first irrespective of the
              // locale-specific preferences or TextDirection. This is because
              // an accessibility user is more likely to be interested in the
              // day of month before the rest of the date, as they are looking
              // for the day of month. To do that we prepend day of month to the
              // formatted full date.
              label: '${formatDecimal(day)}, ${dayToBuild.formatFullDate}',
              selected: isSelectedDay,
              excludeSemantics: true,
              child: dayWidget,
            ),
          );
        }

        dayItems.add(dayWidget);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        physics: const ClampingScrollPhysics(),
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          dayItems,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = JalaliDate.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_dayPickerRowHeight,
        constraints.viewportMainAxisExtent / _maxDayPickerRowCount);
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _dayPickerGridDelegate = _DayPickerGridDelegate();

class _DayHeaders extends StatelessWidget {
  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  List<Widget> _getDayHeaders(
      TextStyle? headerStyle, MaterialLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    int firstDayOfWeekIndex = 0;
    for (int i = firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = narrowWeekdays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday, style: headerStyle)),
      ));
      if (i == (firstDayOfWeekIndex - 1) % 7) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextStyle? dayHeaderStyle = theme.textTheme.caption?.apply(
      color: colorScheme.onSurface.withOpacity(0.60),
    );
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> labels = _getDayHeaders(dayHeaderStyle, localizations);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        shrinkWrap: true,
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          labels,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}
