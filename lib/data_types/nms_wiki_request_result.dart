import 'nms_item.dart';

class NMSWikiRequestResult {
  NMSItem? item; // Sometimes, the page isn't an item itself, but simply links to other item pages, or more indirection!
  List<String> linkedItems = <String>[];

  NMSWikiRequestResult(this.item, this.linkedItems);
}
