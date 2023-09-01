import 'dart:io';
import 'package:http/http.dart' as http;

class NMSWikiParser {
  final String _kBaseURL = 'https://nomanssky.fandom.com/api.php';

  void getWikiItems() async {
    String requestURL = "$_kBaseURL?action=query";

    requestURL =
        '$requestURL&list=categorymembers&cmtitle=Category:Products&format=json&formatversion=2';

    sendGetRequest(requestURL);
  }

  Future<http.Response> sendGetRequest(String apiPath) async {
    print("Sending Get Request...");
    http.Response response = await http.get(Uri.parse(apiPath));
    if (response.statusCode == HttpStatus.ok) {
      print("Response: ${response.body}");
      return response;
    } else {
      print("Error!");
      throw Exception(
          'Get Request failed! Code: ${response.statusCode}, apiPath: $apiPath');
    }
  }
}
