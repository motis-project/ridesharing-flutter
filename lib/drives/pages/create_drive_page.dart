import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/buttons/button.dart';
import '../../util/fields/increment_field.dart';
import '../../util/locale_manager.dart';
import '../../util/search/address_suggestion.dart';
import '../../util/search/start_destination_timeline.dart';
import '../../util/supabase.dart';
import '../../util/trip/trip.dart';
import '../models/drive.dart';
import '../pages/drive_detail_page.dart';

class CreateDrivePage extends StatefulWidget {
  const CreateDrivePage({super.key});

  @override
  State<CreateDrivePage> createState() => _CreateDrivePageState();
}

class _CreateDrivePageState extends State<CreateDrivePage> {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'DriveFAB',
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).pageCreateDriveTitle),
        ),
        body: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: SingleChildScrollView(child: CreateDriveForm()),
        ),
      ),
    );
  }
}

class CreateDriveForm extends StatefulWidget {
  const CreateDriveForm({super.key});

  @override
  State<CreateDriveForm> createState() => _CreateDriveFormState();
}

class _CreateDriveFormState extends State<CreateDriveForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startController = TextEditingController();
  late AddressSuggestion _startSuggestion;
  final TextEditingController _destinationController = TextEditingController();
  late AddressSuggestion _destinationSuggestion;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _seats;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _seats = 1;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (BuildContext context, Widget? childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((TimeOfDay? value) {
      setState(() {
        if (value != null) {
          _selectedDate =
              DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.hour, value.minute);
          _timeController.text = localeManager.formatTime(_selectedDate);
        }
      });
    });
  }

  void _showDatePicker() {
    final DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((DateTime? value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
          _dateController.text = localeManager.formatDate(_selectedDate);
        }
      });
    });
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        //todo: add right end_time from algorithm
        final DateTime endTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedDate.hour + 2,
          _selectedDate.minute,
        );
        final Profile driver = SupabaseManager.getCurrentProfile()!;

        final bool hasDrive =
            await Drive.userHasDriveAtTimeRange(DateTimeRange(start: _selectedDate, end: endTime), driver.id!);
        if (hasDrive && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).pageCreateDriveYouAlreadyHaveDrive)),
          );
          return;
        }

        final bool hasRide =
            await Ride.userHasRideAtTimeRange(DateTimeRange(start: _selectedDate, end: endTime), driver.id!);
        if (hasRide && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).pageCreateDriveYouAlreadyHaveRide)),
          );
          return;
        }

        final Drive drive = Drive(
          driverId: driver.id!,
          start: _startSuggestion.name,
          startPosition: _startSuggestion.position,
          end: _destinationSuggestion.name,
          endPosition: _destinationSuggestion.position,
          seats: _seats,
          startTime: _selectedDate,
          endTime: endTime,
        );

        await SupabaseManager.supabaseClient
            .from('drives')
            .insert(drive.toJson())
            .select<Map<String, dynamic>>()
            .single()
            .then(
          (Map<String, dynamic> data) {
            final Drive drive = Drive.fromJson(data);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => DriveDetailPage.fromDrive(drive),
              ),
            );
          },
        );
      } on AuthException {
        //todo: change error message when login is implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).failureSnackBar),
          ),
        );
      }
    }
  }

  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).formTimeValidateEmpty;
    }
    if (_selectedDate.isBefore(DateTime.now())) {
      return S.of(context).formTimeValidateFuture;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // This needs to happen on rebuild to make sure we pick up locale changes
    _dateController.text = localeManager.formatDate(_selectedDate);
    _timeController.text = localeManager.formatTime(_selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StartDestinationTimeline(
              startController: _startController,
              destinationController: _destinationController,
              onStartSelected: (AddressSuggestion suggestion) => _startSuggestion = suggestion,
              onDestinationSelected: (AddressSuggestion suggestion) => _destinationSuggestion = suggestion,
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  button: true,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: S.of(context).formDate,
                    ),
                    readOnly: true,
                    onTap: _showDatePicker,
                    controller: _dateController,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: S.of(context).formTime,
                    ),
                    readOnly: true,
                    onTap: _showTimePicker,
                    controller: _timeController,
                    validator: _timeValidator,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          SizedBox(
            width: 150,
            child: IncrementField(
              initialValue: _seats,
              maxValue: Trip.maxSelectableSeats,
              icon: Icon(
                Icons.chair,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              onChanged: (int? value) {
                setState(() {
                  _seats = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Button.submit(
            S.of(context).pageCreateDriveButtonCreate,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
