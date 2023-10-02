import 'package:flutter/material.dart';
import 'package:nms_auxiliary/data_types/nms_item.dart';
import 'items_widgets.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  int _navRailIndex = 0;

  Map<String, NMSItem> itemsMap = <String, NMSItem>{};

  @override
  Widget build(BuildContext context) {
    Widget selectedPage;
    switch (_navRailIndex) {
      case 0:
        selectedPage = ItemsWidget(itemsMap: itemsMap);
        break;
      case 1:
        selectedPage = const Placeholder();
        break;
      case 2:
        selectedPage = const Placeholder();
        break;
      case 3:
        selectedPage = const Placeholder();
        break;
      case 4:
        selectedPage = const Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for $_navRailIndex');
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SafeArea(
                child: NavigationRail(
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(icon: Icon(Icons.account_tree), label: Text("Items")),
                NavigationRailDestination(icon: Icon(Icons.analytics), label: Text("Analytics")),
                NavigationRailDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: Text("Power Calculator")),
                NavigationRailDestination(icon: Icon(Icons.construction), label: Text("Building Calculator")),
                NavigationRailDestination(icon: Icon(Icons.travel_explore), label: Text("Planet Coordinates")),
              ],
              onDestinationSelected: (value) {
                setState(() {
                  _navRailIndex = value;
                });
              },
              selectedIndex: _navRailIndex,
              extended: true,
            )),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: selectedPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
