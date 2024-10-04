import 'dart:async';
import 'package:flutter/material.dart';

class CircularCountdown extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;

  const CircularCountdown({
    Key? key,
    required this.duration,
    required this.onComplete,
  }) : super(key: key);

  @override
  _CircularCountdownState createState() => _CircularCountdownState();
}

class _CircularCountdownState extends State<CircularCountdown> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timer.cancel();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: _remainingTime.inSeconds / widget.duration.inSeconds,
            strokeWidth: 8,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
          ),
        ),
        Text(
          '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }
}
