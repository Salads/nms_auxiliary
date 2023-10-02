import 'package:http/http.dart' as http;
import 'package:nms_auxiliary/data_types/nms_item.dart';
import 'package:nms_auxiliary/data_types/nms_recipe.dart';
import 'package:nms_auxiliary/data_types/nms_wiki_crawler.dart';
import 'package:nms_auxiliary/data_types/nms_wiki_request_result.dart';
import 'nms_recipe_ingredient.dart';

const String _kBaseURL = 'https://nomanssky.fandom.com/wiki/';
const String _kRawPostFix = '?action=raw';

enum WikiRequestStatus {
  notStarted,
  inProgress,
  doneSuccess,
  doneFailed,
}

class NMSWikiRequest {
  late String _pageTitle;
  WikiRequestStatus status = WikiRequestStatus.notStarted;
  http.Client? _httpClient;
  late NMSWikiCrawler wikiCrawler;

  Set<String> linkedPageTitles = <String>{};
  List<NMSRecipe> craftingRecipes = <NMSRecipe>[];
  List<NMSRecipe> cookingRecipes = <NMSRecipe>[];
  List<NMSRecipe> refiningRecipes = <NMSRecipe>[];

  NMSWikiRequest(String pageTitle, this.wikiCrawler) {
    _pageTitle = pageTitle;
    _httpClient = wikiCrawler.httpClient;
  }

  void start() async {
    if (status != WikiRequestStatus.notStarted) return;

    print("Starting Request URL: $_kBaseURL$_pageTitle$_kRawPostFix");

    String? wikiText = await _httpClient?.read(Uri.parse('$_kBaseURL$_pageTitle$_kRawPostFix'));

    if (wikiText == null) return;

    _parseWikiText(wikiText);
  }

  void _printMatches(String wikiText, Iterable<RegExpMatch> matches, String matchesLabel) {
    List<String> matchesStrings = <String>[];
    for (RegExpMatch match in matches) {
      String matchStr = wikiText.substring(match.start, match.end);
      if (matchStr.isNotEmpty) {
        matchesStrings.add(matchStr);
      }
    }

    print("$matchesLabel Matches: ${matchesStrings.toString()}");
  }

  void _parseWikiText(String wikiText) {
    Set<String> linkedPageTitles = <String>{};
    List<RegExpMatch> linkedPageMatches = <RegExpMatch>[];

    print("Regex Matching for page: $_pageTitle");

    //These links should give us the page titles directly!
    RegExp iLinkRegex = RegExp(r'(?<=ilink\|).+?((?=})|(?=\|))');
    Iterable<RegExpMatch> iLinkMatches = iLinkRegex.allMatches(wikiText);
    linkedPageMatches.addAll(iLinkMatches);

    _printMatches(wikiText, iLinkMatches, "ilink");

    RegExp lsthRegex = RegExp(r"((?<=lst:)|(?<=lst.:)).+?(?=[\|}])");
    Iterable<RegExpMatch> lsthMatches = lsthRegex.allMatches(wikiText);
    linkedPageMatches.addAll(lsthMatches);

    _printMatches(wikiText, lsthMatches, "lst[x]");

    // Convert RegExp to actual strings
    for (int x = 0; x < linkedPageMatches.length; x++) {
      RegExpMatch match = linkedPageMatches[x];
      linkedPageTitles.add(wikiText.substring(match.start, match.end));
    }

    RegExp craftRegex = RegExp(r"(?<=Craft\|).+?(?=[\|}])");
    Iterable<RegExpMatch> craftMatches = craftRegex.allMatches(wikiText);

    _printMatches(wikiText, craftMatches, "Craft");

    // Process crafting wikitext
    for (RegExpMatch match in craftMatches) {
      String wikiTextMatch = match.input.substring(match.start, match.end);
      wikiTextMatch = wikiTextMatch.trim();
      List<String> ingredientStrings = wikiTextMatch.split(";");
      for (String ingredientStr in ingredientStrings) {
        ingredientStr = ingredientStr.trim();
        List<String> ingredientSubparts = ingredientStr.split(",");
        List<NMSRecipeIngredient> recipeIngredients = <NMSRecipeIngredient>[];
        for (int i = 0; i < ingredientSubparts.length; i++) {
          String ingredientNameOrAmount = ingredientSubparts[i].trim();
          String currentIngredientName = "";
          if (ingredientNameOrAmount.isEmpty) continue;
          if (i % 2 == 0) {
            // Ingredient Name (Page Title)
            currentIngredientName = ingredientNameOrAmount;
          } else {
            // Ingredient Amount
            int ingredientAmount = int.parse(ingredientNameOrAmount);
            recipeIngredients.add(NMSRecipeIngredient(currentIngredientName, ingredientAmount));
            linkedPageTitles.add(currentIngredientName);
          }
        }

        craftingRecipes.add(NMSRecipe(_pageTitle, RecipeType.crafting, recipeIngredients, 1, 0, ""));
      }
    }

    // Cooking recipes can be multiline, so we need to take this in steps.
    RegExp cookRegex = RegExp(r"(?<=Cook\|).+?(?=})", dotAll: true, multiLine: true);
    Iterable<RegExpMatch> cookMatches = cookRegex.allMatches(wikiText);
    _printMatches(wikiText, cookMatches, "Cook");

    List<String> baseCookingMatches = <String>[];
    for (RegExpMatch match in cookMatches) {
      baseCookingMatches.add(wikiText.substring(match.start, match.end).trim());
    }

    // Process Each string match for cooking sections.
    // Split then trim strings at | and \n chars
    for (String match in baseCookingMatches) {
      Iterable<String> matches = match.split(RegExp(r"[\n|]")).where((element) => element.isNotEmpty);
      // Now process all the individual cooking recipes for this item.
      for (String recipeText in matches) {
        // Lumpy Brainstem,1;Lumpy Brainstem,1;1;5%Combine And Reduce
        // Iron,50;Aluminium,100;Cream,1;Ferrite Dust,1;3;4 (no custom recipe name)
        List<NMSRecipeIngredient> cookingRecipeIngredients = <NMSRecipeIngredient>[];
        Iterable<String> recipeParts = recipeText.split(",;").where((element) => element.isNotEmpty && element.trim() != "");
        String currentIngredient = "";
        int amountCreatedPerRecipe = 0;
        double timePerUnit = 0;
        String? recipeCustomName;
        for (int x = 0; x < recipeParts.length; x++) {
          String recipePart = recipeParts.elementAt(x);

          if (x % 2 == 0) {
            // First element, 0...2...4... etc.
            // Could be ingredient name, if we're inside the ingredient list,
            // or could be a number, for num created.

            int? maybeNumber = int.tryParse(recipePart);
            if (maybeNumber == null) {
              // This is a string, so we're in the ingredient list still
              currentIngredient = recipePart;
            } else {
              // This is a number, so now we're out of hte ingredient list, and need to read
              // number items created from recipe, processing time, [optional] recipe custom name
              amountCreatedPerRecipe = int.parse(recipePart);

              Iterable<String> timeAndMaybeName = recipeParts.elementAt(x + 1).split("%");
              for (String e in timeAndMaybeName) {
                e = e.trim();
              }
              timeAndMaybeName = timeAndMaybeName.where((element) => element.isNotEmpty);

              timePerUnit = double.parse(timeAndMaybeName.elementAt(0));
              if (timeAndMaybeName.length > 1) {
                recipeCustomName = timeAndMaybeName.elementAt(1);
              }
            }
          } else {
            // current ingredient amount
            int ingredientAmount = int.parse(recipePart);
            cookingRecipeIngredients.add(NMSRecipeIngredient(currentIngredient, ingredientAmount));
            linkedPageTitles.add(currentIngredient);
          }
        }

        cookingRecipes.add(NMSRecipe(_pageTitle, RecipeType.cooking, cookingRecipeIngredients, amountCreatedPerRecipe, timePerUnit, recipeCustomName));
      }
    }

    // Refining recipes can be multiline, so we need to take this in steps.
    // These are the same as cooking recpies! Just the section header is different.
    RegExp refineRegex = RegExp(r"(?<=PoC-Refine).+?(?=})", dotAll: true, multiLine: true);
    Iterable<RegExpMatch> refineMatches = refineRegex.allMatches(wikiText);
    List<String> baseRefineMatches = <String>[];
    for (RegExpMatch match in refineMatches) {
      baseRefineMatches.add(wikiText.substring(match.start, match.end).trim());
    }

    _printMatches(wikiText, refineMatches, "Refine");

    // Process Each string match for cooking sections.
    // Split then trim strings at | and \n chars
    for (String match in baseRefineMatches) {
      Iterable<String> matches = match.split(RegExp(r"[\n|]")).where((element) => element.isNotEmpty);
      // Now process all the individual cooking recipes for this item.
      for (String recipeText in matches) {
        // Lumpy Brainstem,1;Lumpy Brainstem,1;1;5%Combine And Reduce
        // Iron,50;Aluminium,100;Cream,1;Ferrite Dust,1;3;4 (no custom recipe name)
        List<NMSRecipeIngredient> refiningRecipeIngredients = <NMSRecipeIngredient>[];
        Iterable<String> recipeParts = recipeText.split(",;").where((element) => element.isNotEmpty && element.trim() != "");
        String currentIngredient = "";
        int amountCreatedPerRecipe = 0;
        double timePerUnit = 0;
        String? recipeCustomName;
        for (int x = 0; x < recipeParts.length; x++) {
          String recipePart = recipeParts.elementAt(x);

          if (x % 2 == 0) {
            // First element, 0...2...4... etc.
            // Could be ingredient name, if we're inside the ingredient list,
            // or could be a number, for num created.

            int? maybeNumber = int.tryParse(recipePart);
            if (maybeNumber == null) {
              // This is a string, so we're in the ingredient list still
              currentIngredient = recipePart;
            } else {
              // This is a number, so now we're out of hte ingredient list, and need to read
              // number items created from recipe, processing time, [optional] recipe custom name
              amountCreatedPerRecipe = int.parse(recipePart);

              Iterable<String> timeAndMaybeName = recipeParts.elementAt(x + 1).split("%");
              for (String e in timeAndMaybeName) {
                e = e.trim();
              }
              timeAndMaybeName = timeAndMaybeName.where((element) => element.isNotEmpty);

              timePerUnit = double.parse(timeAndMaybeName.elementAt(0));
              if (timeAndMaybeName.length > 1) {
                recipeCustomName = timeAndMaybeName.elementAt(1);
              }
            }
          } else {
            // current ingredient amount
            int ingredientAmount = int.parse(recipePart);
            refiningRecipeIngredients.add(NMSRecipeIngredient(currentIngredient, ingredientAmount));
            linkedPageTitles.add(currentIngredient);
          }
        }

        refiningRecipes.add(NMSRecipe(_pageTitle, RecipeType.refine, refiningRecipeIngredients, amountCreatedPerRecipe, timePerUnit, recipeCustomName));
      }
    }

    NMSItem? newItem;

    if (cookingRecipes.isNotEmpty || craftingRecipes.isNotEmpty || refiningRecipes.isNotEmpty) {
      // We should have an item!
      newItem = NMSItem(_pageTitle, craftingRecipes, cookingRecipes, refiningRecipes);
    }

    wikiCrawler.onRequestComplete(NMSWikiRequestResult(newItem, linkedPageTitles.toList()));
    // end _parseText
  }
}
