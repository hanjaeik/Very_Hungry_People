import 'package:flutter/material.dart';

class EventExistenceChecker extends StatefulWidget {
  final Stream<bool> eventExistenceStream;
  final Widget Function(bool) builder;

  const EventExistenceChecker({
    Key? key,
    required this.eventExistenceStream,
    required this.builder,
  }) : super(key: key);

  @override
  _EventExistenceCheckerState createState() => _EventExistenceCheckerState();
}

class _EventExistenceCheckerState extends State<EventExistenceChecker> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.eventExistenceStream,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          bool hasEvent = snapshot.data ?? false;
          return widget.builder(hasEvent);
        }
      },
    );
  }
}