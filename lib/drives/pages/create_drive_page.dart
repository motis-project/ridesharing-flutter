import 'package:flutter/material.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/util/submit_button.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../rides/models/ride.dart';
import '../../account/models/profile.dart';
import '../pages/drive_detail_page.dart';

class CreateDrivePage extends StatefulWidget {
  const CreateDrivePage({super.key});

  @override
  State<CreateDrivePage> createState() => _CreateDrivePageState();
}

class _CreateDrivePageState extends State<CreateDrivePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Drive'),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: SingleChildScrollView(child: CreateDriveForm()),
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
  final TextEditingController _destinationController = TextEditingController();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;
  late int _dropdownValue;

  final List<int> list = List.generate(10, (index) => index + 1);

  void _showTimePicker() {
    showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      builder: (context, childWidget) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: childWidget!);
      },
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month,
              _selectedDate.day, value.hour, value.minute);
          _timeController.text = _formatTime(_selectedDate);
        }
      });
    });
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _firstDate,
      lastDate: _firstDate.add(const Duration(days: 30)),
    ).then((value) {
      setState(() {
        if (value != null) {
          _selectedDate = DateTime(value.year, value.month, value.day,
              _selectedDate.hour, _selectedDate.minute);
          _dateController.text = _formatDate(_selectedDate);
        }
      });
    });
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        //todo: get user from auth when login is implemented
        // User authUser = supabaseClient.auth.currentUser!;
        //todo: add right end_time from algorithm
        DateTime endTime = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, _selectedDate.hour + 2, _selectedDate.minute);
        final Profile driver = SupabaseManager.getCurrentProfile()!;
        //check if the user already has a drive at this time
        Drive? overlappingDrive = await Drive.driveOfUserAtTime(
            _selectedDate.toUtc(), endTime.toUtc(), driver.id!);
        if (overlappingDrive != null && mounted) {
          //todo: show view with overlapping drive when implemented
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'You already have a drive on ${_formatDate(overlappingDrive.startTime)} at ${_formatTime(overlappingDrive.startTime)} from ${overlappingDrive.start} to ${overlappingDrive.end}'),
            ),
          );
          return;
        }
        //check if the user already has a ride at this time
        Ride? overlappingRide = await Ride.rideOfUserAtTime(
            _selectedDate.toUtc(), endTime.toUtc(), driver.id!);
        if (overlappingRide != null && mounted) {
          //todo: show view with overlapping ride when implemented
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'You already have a ride on ${_formatDate(overlappingRide.startTime)} at ${_formatTime(overlappingRide.startTime)} from ${overlappingRide.start} to ${overlappingRide.end}'),
            ),
          );
          return;
        }

        Drive drive = Drive(
          userId: driver.id!,
          start: _startController.text,
          end: _destinationController.text,
          seats: _dropdownValue,
          startTime: _selectedDate,
          endTime: endTime,
        );
        //add Drive to database an Navigate to DriveDetailPage
        await supabaseClient
            .from('drives')
            .insert(drive.toJson())
            .then(((value) => Navigator.pushReplacement<void, void>(
                  context,
                  MaterialPageRoute<void>(
                    //todo: call DriveDetailPage with id of created drive when implemented
                    builder: (BuildContext context) => const DriveDetailPage(),
                  ),
                )));
      } on AuthException {
        //todo: change error message when login is implemented
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong"),
        ));
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  String? _timeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a time';
    }
    if (_selectedDate.isBefore(_firstDate)) {
      return 'Please enter a valid time';
    }
    return null;
  }

  @override
  initState() {
    super.initState();
    _firstDate = DateTime.now();
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate);
    _timeController.text = _formatTime(_selectedDate);
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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          //todo: add search for start and destination
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Start",
              hintText: "Enter your starting Location",
            ),
            controller: _startController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a starting location';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Destination",
              hintText: "Enter your destination",
            ),
            controller: _destinationController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a destination';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Date",
                    ),
                    readOnly: true,
                    onTap: _showDatePicker,
                    controller: _dateController,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Time",
                    ),
                    readOnly: true,
                    onTap: _showTimePicker,
                    controller: _timeController,
                    validator: _timeValidator,
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
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Seats",
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
          SubmitButton(
            text: "Create",
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
