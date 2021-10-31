import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BankId {

  static Map<String, String> userMessages = <String, String> {
    'RFA1' : 'Starta BankID-appen',
    'RFA2' : 'Du har inte BankID-appen installerad. Kontakta din internetbank.',
    'RFA3' : 'Åtgärden avbruten. Försök igen.',
    'RFA4' : 'En identifiering eller underskrift för det här personnumret är '
        'redan påbörjad. Försök igen.',
    'RFA5' : 'Internt tekniskt fel. Försök igen.',
    'RFA6' : 'Åtgärden avbruten.',
    'RFA8' : 'BankID-appen svarar inte. Kontrollera att den är startad och att '
        'du har internetanslutning. Om du inte har något giltigt BankID kan du '
        'hämta ett hos din Bank. Försök sedan igen.',
    'RFA9' : 'Skriv in din säkerhetskod i BankID- appen och välj Identifiera '
        'eller Skriv under.',
    'RFA13' : 'Försöker starta BankID-appen.',
    'RFA14A' : 'Söker efter BankID, det kan ta en liten stund... Om det har gått '
        'några sekunder och inget BankID har hittats har du sannolikt inget BankID '
        'som går att använda för den aktuella identifieringen/underskriften i den '
        'här datorn. Om du har ett BankID- kort, sätt in det i kortläsaren. Om du '
        'inte har något BankID kan du hämta ett hos din internetbank. Om du har ett '
        'BankID på en annan enhet kan du starta din BankID-app där.',
    'RFA14B' : 'Söker efter BankID, det kan ta en liten stund... Om det har gått '
        'några sekunder och inget BankID har hittats har du sannolikt inget BankID '
        'som går att använda för den aktuella identifieringen/underskriften i den här '
        'enheten. Om du inte har något BankID kan du hämta ett hos din internetbank. '
        'Om du har ett BankID på en annan enhet kan du starta din BankID-app där.',
    'RFA15A' : 'Söker efter BankID, det kan ta en liten stund... Om det har gått '
        'några sekunder och inget BankID har hittats har du sannolikt inget BankID '
        'som går att använda för den aktuella identifieringen/underskriften i den '
        'här datorn. Om du har ett BankID- kort, sätt in det i kortläsaren. Om du '
        'inte har något BankID kan du hämta ett hos din internetbank.',
    'RFA15B' : 'Söker efter BankID, det kan ta en liten stund... Om det har gått '
        'några sekunder och inget BankID har hittats har du sannolikt inget BankID '
        'som går att använda för den aktuella identifieringen/underskriften i den '
        'här enheten. Om du inte har något BankID kan du hämta ett hos din internetbank.',
    'RFA16' : 'Det BankID du försöker använda är för gammalt eller spärrat. Använd '
        'ett annat BankID eller hämta ett nytt hos din internetbank.',
    'RFA17A' : 'BankID-appen verkar inte finnas i din dator eller telefon. '
        'Installera den och hämta ett BankID hos din internetbank. Installera '
        'appen från din appbutik eller https://install.bankid.com.',
    'RFA17B' : 'Misslyckades att läsa av QR koden. Starta BankID-appen och läs av '
        'QR koden. Kontrollera att BankID-appen är uppdaterad. Om du inte har '
        'BankID-appen måste du installera den och hämta ett BankID hos din internetbank. '
        'Installera appen från din appbutik eller https://install.bankid.com.',
    'RFA18' : 'Starta BankID-appen',
    'RFA19' : 'Vill du identifiera dig eller skriva under med BankID på den här '
        'datorn eller med ett Mobilt BankID?',
    'RFA20' : 'Vill du identifiera dig eller skriva under med ett BankID på den här '
        'enheten eller med ett BankID på en annan enhet?',
    'RFA21' : 'Identifiering eller underskrift pågår.',
    'RFA22' : 'Okänt fel. Försök igen.',
  };

  static const String _fpCertificatePath = 'assets/fp_cert.crt';
  static const String _keyPath = 'assets/pkey.key';
  static const String _trustedCA = 'assets/test.pem';
  static const String _password = 'qwerty123';
  static const String _defaultContentType = 'application/json';

  final SecurityContext _context = SecurityContext.defaultContext;

  Future<bool> setup() async {
    print('setting up!!!');
    try {
      final ByteData certificate = await rootBundle.load(_fpCertificatePath);
      _context.useCertificateChainBytes(
          certificate.buffer.asUint8List()
      );

      final ByteData key = await rootBundle.load(_keyPath);
      _context.usePrivateKeyBytes(
          key.buffer.asUint8List(),
          password: _password
      );

      return true;

    } catch (e) {
      print('Exception caught when setting up certificates: $e');
      return false;
    }
  }

  Future<HttpClientResponse?> _callBankIDApi(String requestBody, String type) async {
    try {
      final HttpClient client = HttpClient(context: _context);
      final String uri = 'https://appapi2.test.bankid.com/rp/v5.1/$type';
      const String method = 'POST';
      final HttpClientRequest request = await client.openUrl(
          method, Uri.parse(uri)
      );

      request.headers.set(HttpHeaders.contentTypeHeader, _defaultContentType);
      request.write(requestBody);

      final HttpClientResponse response = await request.close();
      return response;

    } catch (e) {
      return null;
    }
  }

  Future<bool> launchBankIdApp(String autoStartToken) async {
    print("launching app with token: $autoStartToken");
    String url =
        'https://app.bankid.com/?autostarttoken=$autoStartToken&redirect=null';

    if (await canLaunch(url)) {
      return await launch(url);
    } else {
      return false;
    }
  }

  Future<dynamic> callApi(Map<String, String> requestBody,
                          String methodType) async {
    final String body = json.encode(requestBody);
    final HttpClientResponse? httpResponse = await _callBankIDApi(body, methodType);
    final String? response = await _readResponse(httpResponse);
    if (response == null) {
      return null;
    }

    final dynamic parsedResponse = jsonDecode(response);
    return parsedResponse;
  }

  Future<String?> _readResponse(HttpClientResponse? response) async {
    if (response == null) {
      return null;
    }

    final completer = Completer<String>();
    final contents = StringBuffer();
    response.transform(utf8.decoder).listen((data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }

  static Future<bool> addTrustedCertificate() async {
    ByteData trustedCertificate = await rootBundle.load(_trustedCA);
    SecurityContext context = SecurityContext.defaultContext;
    context.setTrustedCertificatesBytes(trustedCertificate.buffer.asUint8List());
    return true;
  }

  static String mapHintCodeToString(String hintCode) {
    String? mappedValue = 'Identifiering eller underskrift pågår.';
    switch(hintCode) {
      case 'outstandingTransaction':
        mappedValue = userMessages['RFA13'];
        break;

      case 'noClient':
        mappedValue = userMessages['RFA1'];
        break;

      case 'started':
        // we require token
        mappedValue = userMessages['RFA15'];
        break;

      case 'userSign':
        mappedValue = userMessages['RFA9'];
        break;

      case 'expiredTransaction':
        mappedValue = userMessages['RFA8'];;
        break;

      case 'certificateErr':
        mappedValue = userMessages['RFA16'];;
        break;

      case 'userCancel':
        mappedValue = userMessages['RFA6'];
        break;

      case 'cancelled':
        mappedValue = userMessages['RFA3'];
        break;

      case 'startFailed':
        mappedValue = userMessages['RFA17'];;
        break;

      default:
        mappedValue = "Okänt fel.";
        break;
    }

    return mappedValue ?? "Okänt fel.";
  }
}