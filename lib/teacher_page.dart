import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherPage extends StatefulWidget {
  final String teacherId;

  const TeacherPage({super.key, required this.teacherId});

  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  List<Map<String, dynamic>> activePasses = [];

  @override
  void initState() {
    super.initState();
    _loadActivePasses();
  }

  Future<void> _loadActivePasses() async {
    final response = await http.get(Uri.parse(
        'http://127.0.0.1:5000/active_passes_for_teacher/${widget.teacherId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        activePasses = data
            .map((pass) => {
                  'direction': pass['from_location'] == pass['to_location']
                      ? 'Incoming'
                      : 'Outgoing',
                  'studentName': pass[
                      'student_id'], // Assuming student_id is the name for simplicity
                  'from': pass['from_location'],
                  'to': pass['to_location'],
                  'timeLeft': pass['remaining_time'],
                  'eventId': pass['event_id'],
                })
            .toList();
      });
    } else {
      // Handle error
      print('Failed to load active passes');
    }
  }

  Future<void> _cancelPass(String eventId) async {
    final response = await http
        .delete(Uri.parse('http://127.0.0.1:5000/cancel_pass/$eventId'));

    if (response.statusCode == 200) {
      setState(() {
        activePasses.removeWhere((pass) => pass['eventId'] == eventId);
      });
    } else {
      // Handle error
      print('Failed to cancel pass');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard - ${widget.teacherId}'),
      ),
      body: ListView.builder(
        itemCount: activePasses.length,
        itemBuilder: (context, index) {
          final pass = activePasses[index];
          return Card(
            child: ListTile(
              title: Text('${pass['studentName']} - ${pass['direction']}'),
              subtitle: Text('From: ${pass['from']} To: ${pass['to']}'),
              trailing: Text('Time left: ${pass['timeLeft']}'),
              onLongPress: () => _cancelPass(pass['eventId']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadActivePasses,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
