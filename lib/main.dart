import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_zoom_plugin/zoom_options.dart';
import 'package:flutter_zoom_plugin/zoom_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: MeetingWidget(
        meetingId: "3341473149",
        meetingPassword: "Y3g0WnJBb1hYZWFrN3YycmhwUlZqUT09",
      ),
    );
  }
}

class MeetingWidget extends StatefulWidget {
  final ZoomOptions zoomOptions = ZoomOptions(
    domain: "zoom.us",
    appKey: "A1WnqxuY4D86pSAHKz22R4ha1vqha9tsgYwO",
    appSecret: "4t1tvkC7nXqOzPF3D4J6F0w5DzSWJFCMS8zm",
  );
  ZoomMeetingOptions meetingOptions;

  MeetingWidget({Key key, meetingId, meetingPassword}) : super(key: key) {
    // Setting Zoom meeting options (default to false if not set)
    this.meetingOptions = new ZoomMeetingOptions(
        userId: 'example',
        meetingId: meetingId,
        meetingPassword: meetingPassword,
        disableDialIn: "true",
        disableDrive: "true",
        disableInvite: "true",
        disableShare: "true",
        noAudio: "false",
        noDisconnectAudio: "false");
  }

  @override
  _MeetingWidgetState createState() => _MeetingWidgetState();
}

class _MeetingWidgetState extends State<MeetingWidget> {
  Timer timer;

  bool _isMeetingEnded(String status) {
    var result = false;

    if (Platform.isAndroid)
      result = status == "MEETING_STATUS_DISCONNECTING" ||
          status == "MEETING_STATUS_FAILED";
    else
      result = status == "MEETING_STATUS_IDLE";

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading meeting '),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ZoomView(
          onViewCreated: (controller) {
            print("Created the view");

            controller.initZoom(this.widget.zoomOptions).then(
              (results) {
                print("initialised");
                print(results);

                if (results[0] == 0) {
                  // Listening on the Zoom status stream (1)
                  controller.zoomStatusEvents.listen((status) {
                    print("Meeting Status Stream: " +
                        status[0] +
                        " - " +
                        status[1]);

                    if (_isMeetingEnded(status[0])) {
                      Navigator.pop(context);
                      timer?.cancel();
                    }
                  });

                  print("listen on event channel");

                  controller
                      .joinMeeting(this.widget.meetingOptions)
                      .then((joinMeetingResult) {
                    // Polling the Zoom status (2)
                    timer = Timer.periodic(new Duration(seconds: 2), (timer) {
                      controller
                          .meetingStatus(this.widget.meetingOptions.meetingId)
                          .then((status) {
                        print("Meeting Status Polling: " +
                            status[0] +
                            " - " +
                            status[1]);
                      });
                    });
                  });
                }
              },
            ).catchError(
              (error) {
                print(error);
              },
            );
          },
        ),
      ),
    );
  }
}
