import 'package:flutter/material.dart';
import 'package:nms_auxiliary/data_types/nms_data_client.dart';
import 'package:nms_auxiliary/data_types/nms_item.dart';

class ItemsWidget extends StatefulWidget {
  final Map<String, NMSItem> itemsMap;
  late NMSDataClient nmsDataClient;

  ItemsWidget({super.key, required this.itemsMap}) {
    nmsDataClient = NMSDataClient(itemsMap);
  }

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SearchAnchor(
                builder: (BuildContext context, SearchController controller) {
                  return SearchBar(
                    controller: controller,
                    leading: const Icon(Icons.search),
                    hintText: "Search for Items...",
                  );
                },
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  return List<ListTile>.generate(5, (int index) {
                    final String item = 'item $index';
                    return ListTile(
                      title: Text(item),
                    );
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  widget.nmsDataClient.loadFromWiki();
                },
                child: const Text("Update"),
              ),
            ],
          ),
        )
      ],
    ));
  }
}
