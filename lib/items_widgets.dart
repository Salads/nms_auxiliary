import 'package:flutter/material.dart';
import 'data_types/nms_wiki_parser.dart';

class ItemsWidget extends StatefulWidget {
  const ItemsWidget({super.key});

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  final NMSWikiParser _nmsWikiParser = NMSWikiParser();
  bool _testComplete = false;

  @override
  Widget build(BuildContext context) {
    if (!_testComplete) {
      _nmsWikiParser.getWikiItems();
      _testComplete = true;
    }
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                leading: const Icon(Icons.search),
                hintText: "Search for Items...",
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
              return List<ListTile>.generate(5, (int index) {
                final String item = 'item $index';
                return ListTile(
                  title: Text(item),
                );
              });
            },
          ),
        )
      ],
    ));
  }
}
