// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

enum KeyAction {
  press(1),
  release(0);

  const KeyAction(this.value);
  final int value;
}

enum ControllerButton {
  A(0),
  B(1),
  Y(2),
  X(3),
  LB(4),
  RB(5),
  BL(6),
  BR(7),
  Start(8),
  Back(9),
  Guide(10);

  const ControllerButton(this.value);
  final int value;
}

enum ControllerTrigger {
  Left(0),
  Right(1);

  const ControllerTrigger(this.value);
  final int value;
}

enum ControllerDpad {
  Up(0, 1),
  Down(0, -1),
  Left(1, -1),
  Right(1, 1);

  const ControllerDpad(this.value, this.direction);
  final int value;
  final int direction;
}

enum ControllerJoystick {
  Left(0),
  Right(1);

  const ControllerJoystick(this.value);
  final int value;
}

class ClientProvider extends ChangeNotifier {
  bool authorized = false;
  bool connection = false;
  late RawSocket tcpClient;
  int ping = 0;
  int start = DateTime.now().millisecondsSinceEpoch;
  late InternetAddress destinationIp;
  late int destinationPort;

  connect(String ip, int port) async {
    destinationIp = InternetAddress(ip);
    destinationPort = port;

    connection = true;
    authorized = false;

    tcpClient = await RawSocket.connect(destinationIp, port);
    tcpClient.setOption(SocketOption.tcpNoDelay, true);

    authorizedEvent() {
      authorized = true;
      Timer.run(() => notifyListeners());

      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!connection || !authorized) {
          timer.cancel();
          return;
        }
        start = DateTime.now().millisecondsSinceEpoch;
        tcpClient.write([6]);
      });
    }

    pingPongEvent() {
      ping = DateTime.now().millisecondsSinceEpoch - start;
      Timer.run(() => notifyListeners());
    }

    vibrationEvent() {
      final data = tcpClient.read(3);
      if (data == null || data[0] == 0) {
        Vibration.cancel();
        return;
      }

      final duration =
          ByteData.sublistView(data, 1, 3).getUint16(0, Endian.big);

      Vibration.vibrate(duration: duration, amplitude: data[0]);
    }

    tcpClient.listen(
      (event) {
        if (!(event == RawSocketEvent.read)) return;

        final flag = tcpClient.read(1);
        if (flag == null) return;

        switch (flag[0]) {
          case 0:
            disconnect();
          case 1:
            authorizedEvent();
          case 2:
            vibrationEvent();
          case 6:
            pingPongEvent();
        }
      },
      onError: (error) {
        disconnect();
      },
      onDone: () {
        disconnect();
      },
      cancelOnError: true,
    );
  }

  authorize(int code) {
    if (!connection) return;
    tcpClient.write([1] + _int16ToUint8List(code));
  }

  sendKey(ControllerButton key, KeyAction action) {
    tcpClient.write([2, key.value, action.value]);
  }

  sendTrigger(ControllerTrigger trigger, int power) {
    if (!connection) return;
    tcpClient.write([3, trigger.value, power]);
  }

  sendDpad(ControllerDpad dpad, KeyAction action) {
    if (!connection) return;
    tcpClient.write(
        [4, dpad.value, action == KeyAction.release ? 0 : dpad.direction]);
  }

  sendJoystick(ControllerJoystick joystick, int x, int y) {
    if (!connection) return;
    tcpClient.write(
      [5, joystick.value] + _int16ToUint8List(x) + _int16ToUint8List(y),
    );
  }

  disconnect() {
    connection = false;
    authorized = false;
    tcpClient.close();
    Timer.run(() => notifyListeners());
  }

  Uint8List _int16ToUint8List(int value) {
    ByteData byteData = ByteData(2);
    byteData.setInt16(0, value, Endian.big);

    return byteData.buffer.asUint8List();
  }
}
