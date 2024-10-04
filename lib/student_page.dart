import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:nbpass/circular_countdown.dart';

class StudentPage extends StatefulWidget {
  final String studentId;

  const StudentPage({super.key, required this.studentId});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String? _selectedFromLocation;
  String? _selectedToLocation;
  int _duration = 5;
  Map<String, dynamic>? _activePass;
  List<Map<String, dynamic>> _locations = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    print('Initializing StudentPage');
    _fetchLocations();
    _fetchActivePass();
    // Set up a timer to refresh the active pass every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchActivePass();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    print('Fetching locations');
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/locations'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Locations fetched successfully: ${data.length} locations');
      setState(() {
        _locations = data
            .map((location) => {
                  'room': location['room_number'].toString(),
                  'teacher': location['teacher_name'],
                })
            .toList();
      });
    } else {
      print('Failed to load locations: ${response.statusCode}');
    }
  }

  Future<void> _fetchActivePass() async {
    print('Fetching active pass for student ID: ${widget.studentId}');
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/active_passes'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Active passes fetched successfully: ${data.length} passes');
      final activePass = data.firstWhere(
        (pass) => pass['student_id'] == widget.studentId,
        orElse: () => null,
      );
      setState(() {
        _activePass = activePass;
        if (_activePass != null) {
          print('Active pass found for the student');
          if (_activePass!['remaining_time'] != null) {
            _activePass!['remaining_time'] =
                _parseRemainingTime(_activePass!['remaining_time']);
            print('Remaining time: ${_activePass!['remaining_time']}');
          } else {
            print('Remaining time not available in the active pass data');
          }
        } else {
          print('No active pass found for the student');
          _activePass = null; // Explicitly set to null when no pass is found
        }
      });
    } else {
      print('Failed to load active pass: ${response.statusCode}');
    }
  }

  Future<void> _requestPass() async {
    print('Requesting pass');
    if (_selectedFromLocation == null || _selectedToLocation == null) {
      print('From or To location not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select both locations'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/request_pass'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'student_id': widget.studentId,
        'from_location': _selectedFromLocation,
        'to_location': _selectedToLocation,
        'duration_minutes': _duration,
      }),
    );

    if (response.statusCode == 201) {
      print('Pass requested successfully');
      await _fetchActivePass(); // Fetch the active pass immediately after creating
    } else {
      print('Failed to request pass: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to request pass'),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
  }

  Future<void> _cancelPass() async {
    print('Cancelling pass');
    if (_activePass == null || _activePass!['event_id'] == null) {
      print('No active pass to cancel');
      return;
    }

    final response = await http.delete(
      Uri.parse(
          'http://127.0.0.1:5000/cancel_pass/${_activePass!['event_id']}'),
    );

    if (response.statusCode == 200) {
      print('Pass cancelled successfully');
      setState(() {
        _activePass = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pass cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Fetch active passes again to ensure the UI is up-to-date
      await _fetchActivePass();
    } else {
      print('Failed to cancel pass: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel pass'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request a Pass',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.orange[700]),
                      ),
                      const SizedBox(height: 16),
                      _buildLocationDropdown('From', _selectedFromLocation,
                          (value) {
                        setState(() {
                          _selectedFromLocation = value;
                        });
                      }),
                      const SizedBox(height: 16),
                      _buildLocationDropdown('To', _selectedToLocation,
                          (value) {
                        setState(() {
                          _selectedToLocation = value;
                        });
                      }),
                      const SizedBox(height: 16),
                      _buildDurationDropdown(),
                      const SizedBox(height: 24),
                      _buildRequestButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_activePass != null) _buildActivePassCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown(
      String label, String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.orange[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      items: _locations.map((location) {
        return DropdownMenuItem<String>(
          value: location['room'] as String,
          child: Text('${location['room']} - ${location['teacher']}'),
        );
      }).toList(),
      onChanged: (String? value) => onChanged(value),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<int>(
      value: _duration,
      decoration: InputDecoration(
        labelText: 'Duration',
        labelStyle: TextStyle(color: Colors.orange[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      items: [5, 10, 15, 20].map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text('$value minutes'),
        );
      }).toList(),
      onChanged: (int? value) {
        setState(() {
          _duration = value!;
        });
      },
    );
  }

  Widget _buildRequestButton() {
    return ElevatedButton.icon(
      onPressed: _activePass == null ? _requestPass : null,
      icon: const Icon(Icons.send),
      label: const Text('Request Pass'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActivePassCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Pass',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.orange[700]),
            ),
            const SizedBox(height: 16),
            if (_activePass != null && _activePass!['remaining_time'] != null)
              Center(
                child: CircularCountdown(
                  duration: _activePass!['remaining_time'],
                  onComplete: () {
                    setState(() {
                      _activePass = null;
                    });
                  },
                ),
              )
            else
              Center(
                child: Text(
                  'Time not available',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ),
            const SizedBox(height: 16),
            _buildPassDetailTile('From', _activePass!['from_location']),
            _buildPassDetailTile('To', _activePass!['to_location']),
            _buildPassDetailTile('Start Time', _activePass!['start_time']),
            _buildPassDetailTile('End Time', _activePass!['end_time']),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _cancelPass,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Pass'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassDetailTile(String label, String value) {
    return InkWell(
      onTap: () {
        // You can add an action here, like copying to clipboard
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange[700])),
            Text(value, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Duration _parseRemainingTime(String remainingTime) {
    print('Parsing remaining time: $remainingTime');
    final parts = remainingTime.split(':');
    if (parts.length != 3) {
      print('Invalid remaining time format');
      return Duration.zero;
    }
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: double.parse(parts[2]).round(),
    );
  }
}
