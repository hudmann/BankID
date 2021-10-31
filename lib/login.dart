import 'dart:async';

import 'package:flutter/material.dart';

import 'bank_id.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          primary: Colors.blue,
          onSurface: Colors.red,
        ),
        onPressed: _login,
        child: Text('Logga in'),
      )
    );
  }

  Future<void> _login() async {
    final BankId bankId = BankId();
    String? dialogContent = 'Okänt fel';

    if (!(await bankId.setup())) {
      dialogContent = BankId.userMessages['RFA5'];
      return;
    }

    Map<String, String> body = {'endUserIp': '192.168.1.143'};
    String methodType = 'auth';
    final dynamic authResponse = await bankId.callApi(body, methodType);
    print('Auth response: $authResponse');
    if (authResponse == null) {
      dialogContent = BankId.userMessages['RFA5'];
      return;
    }

    final String token = authResponse['autoStartToken'];
    if (!(await bankId.launchBankIdApp(token))) {
      dialogContent = BankId.userMessages['RFA2'];
      return;
    }

    //TODO::should show a dialog for some sec with progress while BankID
    //app launching
    dynamic collectResponse;
    String status;
    final String orderRef = authResponse['orderRef'];
    const Duration duration = Duration(seconds:2);
    Timer.periodic(duration, (Timer timer) async => {
      body = {'orderRef': orderRef},
      collectResponse = await bankId.callApi(body, 'collect'),
      print('collectResponse: $collectResponse'),
      if (collectResponse == null) {
        dialogContent = 'Okänt fel. Försök igen.',
        timer.cancel(),
      } else {
        // if (pending) :: cancel dialog if exists, showNewDialog(hintCode)
        status = collectResponse['status'] as String,
        if (status == 'pending') {
          print('Pending 1 2 3.'),
          dialogContent = BankId.mapHintCodeToString(
              collectResponse['hintCode']
          ),

        } else if (status == 'failed') {
          print('Failed.'),
          dialogContent = BankId.mapHintCodeToString(
              collectResponse['hintCode']
          ),
          timer.cancel(),

        } else if (status == 'complete') {
          print('am i cancelleD!!??'),
          timer.cancel(),
        }
      }
    });
  }
}
