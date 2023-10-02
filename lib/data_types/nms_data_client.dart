import 'package:nms_auxiliary/data_types/nms_item.dart';
import 'package:nms_auxiliary/data_types/nms_wiki_crawler.dart';

const kSaveFileLocation = "";

class NMSDataClient {
  Map<String, NMSItem> items = <String, NMSItem>{};
  late NMSWikiCrawler nmsWikiCrawler;

  NMSDataClient(this.items) {
    nmsWikiCrawler = NMSWikiCrawler(items);
  }

  void loadFromWiki() {
    nmsWikiCrawler.fullUpdate();
  }

  void loadFromFile() {}
}
