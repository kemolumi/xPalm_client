import 'package:flutter/material.dart';

import 'enter_pin.dart';

class ManualConnect extends StatefulWidget {
  const ManualConnect({super.key});

  @override
  State<StatefulWidget> createState() => _ManualConnectState();
}

class _ManualConnectState extends State<ManualConnect> {
  bool connectPart = false;
  String ip = "", port = "";
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Center(
        child: Column(
          children: [
            Column(children: [
              const Text("xPalm server",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(children: [
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              onChanged: (t) => ip = t,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "IP Address",
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              onChanged: (t) => port = t,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Port",
                              ),
                            ),
                          )
                        ]),
                        const SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel")),
                              const SizedBox(width: 10),
                              FilledButton.tonal(
                                  onPressed: () => showModalBottomSheet(
                                        showDragHandle: true,
                                        isDismissible: false,
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) => PopScope(
                                          canPop: false,
                                          child: EnterPin(
                                            ip: ip,
                                            port: int.parse(port),
                                            name: "xPalm server",
                                          ),
                                        ),
                                      ),
                                  child: const Text("Connect"))
                            ])
                      ])))
            ]),
          ],
        ),
      ),
    );
  }
}
