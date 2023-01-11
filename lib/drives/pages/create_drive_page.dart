import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/models/ride.dart';
import '../../account/models/profile.dart';
import '../../util/buttons/button.dart';
import '../../util/search/address_search_field.dart';
import '../../util/search/address_suggestion.dart';
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
  // ignore: unused_field
  AddressSuggestion? _startSuggestion;
  final TextEditingController _destinationController = TextEditingController();
  // ignore: unused_field
  AddressSuggestion? _destinationSuggestion;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (context, childWidget) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: childWidget!);
      },
    ).then((value) {
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
    DateTime firstDate = DateTime.now();

    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 30)),
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day, _selectedDate.hour, _selectedDate.minute);
          _dateController.text = localeManager.formatDate(_selectedDate);
        }
      });
    });
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        //todo: add right end_time from algorithm
        DateTime endTime = DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedDate.hour + 2, _selectedDate.minute);
        final Profile driver = SupabaseManager.getCurrentProfile()!;

        bool hasDrive =
            await Drive.userHasDriveAtTimeRange(DateTimeRange(start: _selectedDate, end: endTime), driver.id!);
        if (hasDrive && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).pageCreateDriveYouAlreadyHaveDrive)),
          );
          return;
        }

        bool hasRide = await Ride.userHasRideAtTimeRange(DateTimeRange(start: _selectedDate, end: endTime), driver.id!);
        if (hasRide && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).pageCreateDriveYouAlreadyHaveRide)),
          );
          return;
        }

        Drive drive = Drive(
          driverId: driver.id!,
          start: _startSuggestion!.name,
          startPosition: _startSuggestion!.position,
          end: _destinationSuggestion!.name,
          endPosition: _destinationSuggestion!.position,
          seats: _dropdownValue,
          startTime: _selectedDate,
          endTime: endTime,
        );

        await supabaseClient.from('drives').insert(drive.toJson()).select<Map<String, dynamic>>().single().then(
          (data) {
            Drive drive = Drive.fromJson(data);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => DriveDetailPage.fromDrive(drive),
              ),
            );
          },
        );
      } on AuthException {
        //todo: change error message when login is implemented
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).failureSnackBar),
        ));
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
  initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dropdownValue = list.first;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This needs to happen on rebuild to make sure we pick up locale changes
    _dateController.text = localeManager.formatDate(_selectedDate);
    _timeController.text = localeManager.formatTime(_selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AddressSearchField.start(
            controller: _startController,
            onSelected: (suggestion) => _startSuggestion = suggestion,
          ),
          const SizedBox(height: 15),
          AddressSearchField.destination(
            controller: _destinationController,
            onSelected: (suggestion) => _destinationSuggestion = suggestion,
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                const SizedBox(width: 50),
                Expanded(
                  child: SizedBox(
                    //todo: add same height as time&date.
                    height: 60,
                    child: DropdownButtonFormField<int>(
                      value: _dropdownValue,
                      icon: const Icon(Icons.arrow_downward),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: S.of(context).seats,
                      ),
                      onChanged: (int? value) {
                        setState(() {
                          _dropdownValue = value!;
                        });
                      },
                      items: list.map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Button.submit(
            S.of(context).pageCreateDriveButtonCreate,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
