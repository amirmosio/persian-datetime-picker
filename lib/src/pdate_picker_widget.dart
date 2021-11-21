// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:persian_datetime_picker/src/date/shamsi_date.dart';

import 'pcalendar_date_picker.dart';
import 'pdate_picker_common.dart';
import 'pdate_picker_header.dart';
import 'pdate_utils.dart' as utils;

const Size _calendarLandscapeDialogSize = Size(344.0, 332.0);

/// Shows a dialog containing a Material Design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user confirms the dialog. If the user cancels the dialog, null is returned.
///
/// When the date picker is first displayed, it will show the month of
/// [initialDate], with [initialDate] selected.
///
/// The [firstDate] is the earliest allowable date. The [lastDate] is the latest
/// allowable date. [initialDate] must either fall between these dates,
/// or be equal to one of them. For each of these [Jalali] parameters, only
/// their dates are considered. Their time fields are ignored. They must all
/// be non-null.
///
/// An optional [initialEntryMode] argument can be used to display the date
/// picker in the [DatePickerEntryMode.calendar] (a calendar month grid)
/// or [DatePickerEntryMode.input] (a text input field) mode.
/// It defaults to [DatePickerEntryMode.calendar] and must be non-null.
///
/// An optional [selectableDayPredicate] function can be passed in to only allow
/// certain days for selection. If provided, only the days that
/// [selectableDayPredicate] returns true for will be selectable. For example,
/// this can be used to only allow weekdays for selection. If provided, it must
/// return true for [initialDate].
///
/// Optional strings for the [secondaryButtonText], [primaryButtonText], [errorFormatText],
/// [errorInvalidText], [fieldHintText], [fieldLabelText], and [helpText] allow
/// you to override the default text used for various parts of the dialog:
///
///   * [secondaryButtonText], label on the cancel button.
///   * [primaryButtonText], label on the ok button.
///   * [errorFormatText], message used when the input text isn't in a proper date format.
///   * [errorInvalidText], message used when the input text isn't a selectable date.
///   * [fieldHintText], text used to prompt the user when no text has been entered in the field.
///   * [fieldLabelText], label for the date text input field.
///   * [helpText], label on the top of the dialog.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// ([TextDirection.ltr] or [TextDirection.rtl]) for the date picker. It
/// defaults to the ambient text direction provided by [Directionality]. If both
/// [locale] and [textDirection] are non-null, [textDirection] overrides the
/// direction chosen for the [locale].
///
/// The [context], [useRootNavigator] and [routeSettings] arguments are passed to
/// [showDialog], the documentation for which discusses how it is used. [context]
/// and [useRootNavigator] must be non-null.
///
/// The [builder] parameter can be used to wrap the dialog widget
/// to add inherited widgets like [Theme].
///
/// An optional [initialDatePickerMode] argument can be used to have the
/// calendar date picker initially appear in the [DatePickerMode.year] or
/// [DatePickerMode.day] mode. It defaults to [DatePickerMode.day], and
/// must be non-null.

class DatePickerWidget extends StatefulWidget {
  DatePickerWidget({
    Key? key,
    required Jalali initialDate,
    required Jalali firstDate,
    required Jalali lastDate,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    this.selectableDayPredicate,
    this.secondaryButtonText,
    this.onSelectedDateChanged,
    this.onSecondaryTap,
    this.primaryButtonText,
    this.onPrimaryTap,
    this.showHeaderWidget = true,
    this.helpText,
    this.errorFormatText,
    this.errorInvalidText,
    this.fieldHintText,
    this.fieldLabelText,
  })  : initialDate = utils.dateOnly(initialDate),
        firstDate = utils.dateOnly(firstDate),
        lastDate = utils.dateOnly(lastDate),
        super(key: key) {
    assert(!this.lastDate.isBefore(this.firstDate),
        'lastDate ${this.lastDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isBefore(this.firstDate),
        'initialDate ${this.initialDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isAfter(this.lastDate),
        'initialDate ${this.initialDate} must be on or before lastDate ${this.lastDate}.');
    assert(
        selectableDayPredicate == null ||
            selectableDayPredicate!(this.initialDate),
        'Provided initialDate ${this.initialDate} must satisfy provided selectableDayPredicate');
  }

  /// selected date changed callback
  final void Function(Jalali?, PageController)? onSelectedDateChanged;

  /// button tap handle
  final void Function(Jalali?, PageController)? onPrimaryTap;
  final void Function(Jalali?, PageController)? onSecondaryTap;

  /// Decides if it has to show header widget or not. Default True
  final bool showHeaderWidget;

  /// The initially selected [Jalali] that the picker should display.
  final Jalali initialDate;

  /// The earliest allowable [Jalali] that the user can select.
  final Jalali firstDate;

  /// The latest allowable [Jalali] that the user can select.
  final Jalali lastDate;

  final DatePickerEntryMode initialEntryMode;

  /// Function to provide full control over which [Jalali] can be selected.
  final PSelectableDayPredicate? selectableDayPredicate;

  /// The text that is displayed on the cancel button.
  final String? secondaryButtonText;

  /// The text that is displayed on the confirm button.
  final String? primaryButtonText;

  /// The text that is displayed at the top of the header.
  ///
  /// This is used to indicate to the user what they are selecting a date for.
  final String? helpText;

  final String? errorFormatText;

  final String? errorInvalidText;

  final String? fieldHintText;

  final String? fieldLabelText;

  @override
  _DatePickerWidgetState createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late final PageController monthPageViewController;
  Jalali? _selectedDate;
  final GlobalKey _calendarPickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    monthPageViewController = PageController(
        initialPage: utils.monthDelta(widget.firstDate,
            Jalali(widget.initialDate.year, widget.initialDate.month)));
    _selectedDate = widget.initialDate;
  }

  void _handleOnPrimaryTap() {
    widget.onPrimaryTap?.call(_selectedDate, monthPageViewController);
  }

  void _handleSecondaryTap() {
    widget.onSecondaryTap?.call(_selectedDate, monthPageViewController);
  }

  void _handleDateChanged(Jalali? date) {
    setState(() => _selectedDate = date);
    widget.onSelectedDateChanged?.call(_selectedDate, monthPageViewController);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Orientation orientation = MediaQuery.of(context).orientation;
    final TextTheme textTheme = theme.textTheme;
    // Constrain the textScaleFactor to the largest supported value to prevent
    // layout issues.
    final double textScaleFactor =
        math.min(MediaQuery.of(context).textScaleFactor, 1.3);

    final String dateText = _selectedDate != null
        ? _selectedDate!.formatMediumDate()
        // TODO(darrenaustin): localize 'Date'
        : 'Date';
    final Color dateColor = colorScheme.brightness == Brightness.light
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final TextStyle? dateStyle = orientation == Orientation.landscape
        ? textTheme.headline5?.copyWith(color: dateColor)
        : textTheme.headline4?.copyWith(color: dateColor);

    final Widget actions = widget.secondaryButtonText != null ||
            widget.primaryButtonText != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                widget.secondaryButtonText != null
                    ? TextButton(
                        child: Text(widget.secondaryButtonText!),
                        onPressed: _handleSecondaryTap,
                      )
                    : SizedBox(),
                widget.primaryButtonText != null
                    ? TextButton(
                        child: Text(widget.primaryButtonText!),
                        onPressed: _handleOnPrimaryTap,
                      )
                    : SizedBox(),
              ],
            ),
          )
        : SizedBox();

    late Widget picker = PCalendarDatePicker(
      key: _calendarPickerKey,
      initialDate: _selectedDate!,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      pageController: monthPageViewController,
      onDateChanged: _handleDateChanged,
      selectableDayPredicate: widget.selectableDayPredicate,
    );

    final Widget header = PDatePickerHeader(
      helpText: widget.helpText ?? "",
      titleText: dateText,
      titleStyle: dateStyle,
      orientation: orientation,
      isShort: orientation == Orientation.landscape,
      icon: Icons.calendar_today,
      iconTooltip: "",
      onIconPressed: () {},
    );

    return GestureDetector(
      onTap: () {
        // override, do nothing
      },
      child: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(-1, 1),
              color: Colors.grey)
        ], color: Colors.white),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: textScaleFactor,
            ),
            child: Builder(builder: (BuildContext context) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: (widget.showHeaderWidget ? [header] : <Widget>[]) +
                    <Widget>[
                      IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            picker,
                            Divider(
                              thickness: 1,
                              height: 1,
                            ),
                            actions
                          ],
                        ),
                      ),
                    ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
