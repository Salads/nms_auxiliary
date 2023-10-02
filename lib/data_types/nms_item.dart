import 'package:nms_auxiliary/data_types/nms_recipe.dart';

class NMSItem {
  late String name;
  late List<NMSRecipe> craftingRecipes = <NMSRecipe>[];
  late List<NMSRecipe> cookingRecipes = <NMSRecipe>[];
  late List<NMSRecipe> refiningRecipes = <NMSRecipe>[];

  NMSItem(
    String newName,
    this.craftingRecipes,
    this.cookingRecipes,
    this.refiningRecipes,
  ) {
    name = newName;
  }

  @override
  String toString() {
    StringBuffer result = StringBuffer();
    result.writeln("Item$name");
    result.writeAll(craftingRecipes, "\n\n");
    result.writeAll(cookingRecipes, "\n\n");
    result.writeAll(refiningRecipes, "\n\n");
    return result.toString();
  }
}
