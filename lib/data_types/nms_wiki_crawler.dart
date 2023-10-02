import 'dart:collection';

import 'package:nms_auxiliary/data_types/nms_item.dart';
import 'package:nms_auxiliary/data_types/nms_wiki_request_result.dart';

import 'nms_wiki_request.dart';
import 'package:http/http.dart' as http;

const int kMaxSimulatenousRequests = 2;
const String kURLSeed = 'https://nomanssky.fandom.com/wiki/Items?action=raw';
const String kTitleSeed = "Items";

class NMSWikiCrawler {
  http.Client httpClient = http.Client();
  late final Map<String, NMSItem> _items;
  final Queue<NMSWikiRequest> _requestsQueue = Queue<NMSWikiRequest>();

  Set<String> processedPageTitles = <String>{};

  int _numRunningRequests = 0;

  NMSWikiCrawler(this._items);

  bool getIsRunning() {
    return _requestsQueue.isNotEmpty && _numRunningRequests > 0;
  }

  void fullUpdate() {
    // Start with the seed page, then branch out from there.
    // We keep track of already in-progress/completed page requests via a page title set.
    _enqueuePageRequest(kTitleSeed);
  }

  void _enqueuePageRequest(String pageTitle) {
    if (processedPageTitles.contains(pageTitle)) return;

    NMSWikiRequest newWikiRequest = NMSWikiRequest(pageTitle, this);
    processedPageTitles.add(pageTitle);
    _requestsQueue.add(newWikiRequest);
    _updateQueue();
  }

  void _updateQueue() {
    while (_numRunningRequests < kMaxSimulatenousRequests && _requestsQueue.isNotEmpty) {
      NMSWikiRequest nextRequest = _requestsQueue.removeFirst();
      nextRequest.start();
      _numRunningRequests++;
    }
  }

  void onRequestComplete(NMSWikiRequestResult newItem) {
    _numRunningRequests--;
    if (newItem.item != null) {
      _items[newItem.item!.name] = newItem.item!;
      print("Completed Request for item: ${newItem.item!.name}");
    }
    for (String linkedPageTitle in newItem.linkedItems.where((element) => !processedPageTitles.contains(element))) {
      _enqueuePageRequest(linkedPageTitle);
      print("Queued Request for Page: $linkedPageTitle");
    }
    _updateQueue();
  }
}
