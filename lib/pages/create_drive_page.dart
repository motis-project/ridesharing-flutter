import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/util/submit_button.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateDrivePage extends StatefulWidget {
  const CreateDrivePage({super.key});

  @override
  State<CreateDrivePage> createState() => _CreateDrivePageState();
}

class _CreateDrivePageState extends State<CreateDrivePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _seatController = TextEditingController();

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  late final DateTime _firstDate;
  late DateTime _selectedDate;

  // show time picker method
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute}';
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

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      //todo: add check if user has no other drive or ride at this time
      try {
        await supabaseClient.from('drives').insert({
          //todo: take real user id not auth_id
          //todo: add end_time
          'driver_id': 1,
          'start': _startController.text,
          'end': _destinationController.text,
          'seats': _seatController.text,
          'start_time': _selectedDate.toIso8601String(),
        });
      } on AuthException {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Something went wrong"),
        ));
      }
    }
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

  @override
  initState() {
    super.initState();
    _firstDate = DateTime.now();
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate);
    _timeController.text = _formatTime(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              children: [
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
                          //todo: add dropdown
                          child: TextFormField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Seats",
                              hintText: "Enter the number of seats",
                            ),
                            controller: _seatController,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter the number of seats'
                                : null,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SubmitButton(text: "Create", onPressed: _onSubmit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
