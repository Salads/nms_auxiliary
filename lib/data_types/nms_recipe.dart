import 'package:collection/collection.dart';
import 'package:nms_auxiliary/data_types/nms_recipe_ingredient.dart';

enum RecipeType { none, crafting, cooking, refine }

class NMSRecipe {
  late String resultName;

  RecipeType recipeType = RecipeType.none;
  List<NMSRecipeIngredient> ingredients = <NMSRecipeIngredient>[];

  int amountCreated = 0;
  double secondsPerUnit = 0;

  String? recipeName;

  NMSRecipe(String newResultName, RecipeType type, List<NMSRecipeIngredient> newIngredients, int amountCreatedPerUnit, double newSecondsPerUnit,
      String? newRecipeName) {
    resultName = newResultName;
    recipeType = type;
    amountCreated = amountCreatedPerUnit;
    secondsPerUnit = newSecondsPerUnit;
    ingredients = newIngredients;
    recipeName = newRecipeName;
  }

  @override
  bool operator ==(other) =>
      other is NMSRecipe && resultName == other.resultName && recipeType == other.recipeType && const ListEquality().equals(ingredients, other.ingredients);

  @override
  int get hashCode => ingredients.hashCode;
}
