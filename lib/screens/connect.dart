import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import '../client_provider.dart';
import 'manual_connect.dart';
import 'enter_pin.dart';

class Connect extends StatefulWidget {
  const Connect({super.key});

  @override
  State<StatefulWidget> createState() => _ConnectState();
}

class _ConnectState extends State<Connect> {
  late ClientProvider clientProvider;
  ServersMulticast serverSearch = ServersMulticast();

  @override
  void initState() {
    try {
      clientProvider.disconnect();
    } catch (_) {}
    serverSearch.bind();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    clientProvider = Provider.of<ClientProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    serverSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("xPalm Client"),
        actions: [
          IconButton(
              onPressed: () => showModalBottomSheet(
                    isScrollControlled: true,
                    showDragHandle: true,
                    isDismissible: false,
                    enableDrag: false,
                    context: context,
                    builder: (context) => const PopScope(
                      canPop: false,
                      child: ManualConnect(),
                    ),
                  ),
              icon: const Icon(Icons.sync_alt))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          serverSearch.dispose();
          serverSearch.bind();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ValueListenableBuilder(
          builder: (context, sv, __) => ListView.builder(
            itemBuilder: (context, index) => InkWell(
              onTap: () => showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => PopScope(
                  canPop: false,
                  child: EnterPin(
                    ip: sv[index].ip.address,
                    port: sv[index].port,
                    name: sv[index].name,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.laptop_windows),
                title: Text(sv[index].name),
                subtitle: Text("${sv[index].ip.address}:${sv[index].port}"),
                trailing: const Icon(Icons.link),
              ),
            ),
            itemCount: sv.length,
          ),
          valueListenable: serverSearch.serversList,
        ),
      ),
    );
  }
}

class ServersMulticast {
  late RawDatagramSocket socket;
  InternetAddress multicastGroup = InternetAddress("224.3.29.115");
  int port = 45783;

  ListNotifier serversList = ListNotifier();
  late Timer sendTask;

  MethodChannel mutlcastLock =
      const MethodChannel("com.kemolumi.xpalm_client/multicast_lock");

  bind() async {
    if (Platform.isAndroid) {
      await mutlcastLock.invokeMethod<bool>("acquire");
    }

    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    socket.joinMulticast(multicastGroup);
    socket.readEventsEnabled = true;

    socket.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null && socket.address != datagram.address) {
            final message = datagram.data;
            if (message.first == 1) {
              final serverName = String.fromCharCodes(message.sublist(3));
              final serverInfo = ServerInfo(
                name: serverName,
                ip: datagram.address,
                port: ByteData.sublistView(message.sublist(1, 3)).getUint16(0),
              );
              if (serversList.value.firstWhereOrNull((element) =>
                      element.ip.address == serverInfo.ip.address) ==
                  null) {
                serversList.add(
                  ServerInfo(
                    name: serverName,
                    ip: datagram.address,
                    port: ByteData.sublistView(message.sublist(1, 3))
                        .getUint16(0),
                  ),
                );
              }
            }
          }
        }
      },
    );

    socket.send([0], multicastGroup, port);
    sendTask = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        socket.send([0], multicastGroup, port);
      },
    );
  }

  dispose() async {
    sendTask.cancel();
    serversList.clear();

    if (Platform.isAndroid) {
      await mutlcastLock.invokeMethod<bool>("release");
    }
    socket.close();
  }
}

class ServerInfo {
  final String name;
  final InternetAddress ip;
  final int port;

  ServerInfo({required this.name, required this.ip, required this.port});
}

class ListNotifier extends ValueNotifier<List<ServerInfo>> {
  ListNotifier() : super([]);

  void add(ServerInfo listItem) {
    value.add(listItem);
    notifyListeners();
  }

  void clear() {
    value.clear();
    notifyListeners();
  }
}
