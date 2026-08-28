import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../client_provider.dart';
import '../screens/interact.dart';
import 'package:provider/provider.dart';

class EnterPin extends StatefulWidget {
  final String ip, name;
  final int port;
  const EnterPin(
      {super.key, required this.ip, required this.name, required this.port});

  @override
  State<StatefulWidget> createState() => _EnterPinState();
}

class _EnterPinState extends State<EnterPin> {
  TextEditingController code = TextEditingController();
  ClientProvider? _clientProvider;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    Provider.of<ClientProvider>(context, listen: false)
        .connect(widget.ip, widget.port);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ClientProvider>();
    if (_clientProvider != provider) {
      _clientProvider?.removeListener(_onConnectionChange);
      _clientProvider = provider;
      _clientProvider!.addListener(_onConnectionChange);
    }
  }

  void _onConnectionChange() {
    if (_handled || !mounted) return;

    if (!_clientProvider!.connection) {
      _handled = true;
      Fluttertoast.showToast(
        msg: "The server closed your connection.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Theme.of(context).cardColor,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (_clientProvider!.authorized) {
      _handled = true;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => Interact(name: widget.name)),
      );
    }
  }

  @override
  void dispose() {
    _clientProvider?.removeListener(_onConnectionChange);
    if (!_clientProvider!.authorized) {
      _clientProvider!.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, _) {
        return AlertDialog(
          title: Text("Connect to ${widget.name}"),
          content: TextField(
            controller: code,
            textAlign: TextAlign.center,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Authorize code",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              child: const Text('Authorize'),
              onPressed: () {
                clientProvider.authorize(int.parse(code.text));
              },
            ),
          ],
        );
      },
    );
  }
}
