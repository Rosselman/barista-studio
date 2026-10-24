import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/preset_catalog.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../services/recipe_share_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/flash_recipe_dialog.dart';
import '../widgets/recipe_detail_dialog.dart';

class RecipesTab extends StatefulWidget {
  final BaristaBleService bleService;
  final StorageService storageService;
  final void Function(Recipe recipe)? onCustomize;
  final VoidCallback? onOpenBuilder;

  const RecipesTab({
    super.key,
    required this.bleService,
    required this.storageService,
    this.onCustomize,
    this.onOpenBuilder,
  });

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

// Backward compatibility alias
typedef PresetsTab = RecipesTab;

class _RecipesTabState extends State<RecipesTab> {
  int _modeIndex = 0; // 0: Curated Presets, 1: My Recipes
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _customRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadCustomRecipes();
    widget.storageService.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    if (mounted) {
      _loadCustomRecipes();
    }
  }

  @override
  void didUpdateWidget(RecipesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storageService != widget.storageService) {
      oldWidget.storageService.removeListener(_onStorageChanged);
      widget.storageService.addListener(_onStorageChanged);
      _loadCustomRecipes();
    }
  }

  void _loadCustomRecipes() {
    setState(() {
      _customRecipes = widget.storageService.getCustomRecipes();
    });
  }

  List<String> get _categories => PresetCatalog.categories;

  List<Recipe> get _filteredPresets {
    final query = _searchQuery.toLowerCase().trim();
    final list = PresetCatalog.presets.where((r) {
      final matchesCategory = _selectedCategory == 'All' ||
          r.category == _selectedCategory ||
          r.tags.contains(_selectedCategory);
      final matchesSearch = query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query) ||
          r.tags.any((t) => t.toLowerCase().contains(query)) ||
          r.ingredients.any((i) => i.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    // Favorites pinned to the top of the list preserving catalog popularity order
    final favorites = <Recipe>[];
    final nonFavorites = <Recipe>[];
    final favSet = widget.storageService.getFavorites();
    for (final r in list) {
      if (favSet.contains(r.id)) {
        favorites.add(r);
      } else {
        nonFavorites.add(r);
      }
    }
    return [...favorites, ...nonFavorites];
  }

  List<Recipe> get _filteredCustomRecipes {
    final query = _searchQuery.toLowerCase().trim();
    final list = _customRecipes.where((r) {
      final matchesCategory = _selectedCategory == 'All' ||
          r.category == _selectedCategory ||
          r.tags.contains(_selectedCategory);
      final matchesSearch = query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query) ||
          r.tags.any((t) => t.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();

    // Favorites pinned to the top of the list preserving custom order
    final favorites = <Recipe>[];
    final nonFavorites = <Recipe>[];
    final favSet = widget.storageService.getFavorites();
    for (final r in list) {
      if (favSet.contains(r.id)) {
        favorites.add(r);
      } else {
        nonFavorites.add(r);
      }
    }
    return [...favorites, ...nonFavorites];
  }

  @override
  void dispose() {
    widget.storageService.removeListener(_onStorageChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _showEditRecipeDetailsDialog(BuildContext context, Recipe recipe) {
    final nameCtrl = TextEditingController(text: recipe.name);
    final descCtrl = TextEditingController(text: recipe.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppTheme.goldPrimary, size: 22),
            SizedBox(width: 8),
            Text(
              'Customize Recipe Details',
              style: TextStyle(color: AppTheme.crema, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recipe Name (Max 16 ASCII for Machine Display)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: TextField(
                  controller: nameCtrl,
                  maxLength: 16,
                  style: const TextStyle(color: AppTheme.crema, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Description & Preparation Notes',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  maxLength: 240,
                  style: const TextStyle(color: AppTheme.crema, fontSize: 13),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'e.g. My bespoke cold foam recipe with a hint of cinnamon...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newDesc = descCtrl.text.trim();
              Navigator.of(ctx).pop();
              await widget.storageService.updateRecipeDetails(
                recipe.id,
                name: newName.isNotEmpty ? newName : recipe.name,
                description: newDesc,
              );
              if (context.mounted) {
                AppToast.success(context, 'Recipe details updated!');
              }
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  void _shareRecipe(BuildContext context, Recipe recipe) {
    final link = RecipeShareService.encodeShareUrl(recipe);
    Clipboard.setData(ClipboardData(text: link));
    AppToast.success(context, 'Share link copied to clipboard!');
  }

  void _showImportShareLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.link, color: AppTheme.goldPrimary, size: 22),
            SizedBox(width: 10),
            Text(
              'Import Share Link / Code',
              style: TextStyle(color: AppTheme.crema, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a baristastudio:// link or recipe share code below:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.crema, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'baristastudio://recipe?data=...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppTheme.surfaceInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste, color: AppTheme.goldLight, size: 18),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      controller.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Preview & Import'),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final recipe = RecipeShareService.decodeShareUrl(text);
              if (recipe == null) {
                AppToast.error(context, 'Invalid recipe share link or code. Please check the text and try again.');
                return;
              }
              Navigator.of(ctx).pop();
              RecipeDetailDialog.show(
                context,
                recipe: recipe,
                bleService: widget.bleService,
                storageService: widget.storageService,
                isSharedImport: true,
                onCustomize: widget.onCustomize,
                onSavedToMyRecipes: () {
                  _loadCustomRecipes();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppTheme.cyanCold, size: 22),
            SizedBox(width: 10),
            Text(
              'Import Recipes (JSON)',
              style: TextStyle(color: AppTheme.crema, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste custom recipes JSON (single recipe, list of recipes, or backup object):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(color: AppTheme.crema, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{\n  "recipes": [\n    {\n      "name": "My Recipe",\n      ...\n    }\n  ]\n}',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppTheme.surfaceInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, color: AppTheme.goldLight, size: 18),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        controller.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Import Recipes'),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final imported = RecipeShareService.importRecipesFromJson(text);
              if (imported.isEmpty) {
                AppToast.error(context, 'No valid recipes found in JSON. Please verify the JSON structure.');
                return;
              }
              final count = await widget.storageService.importCustomRecipes(imported);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                _loadCustomRecipes();
                AppToast.success(context, 'Successfully imported $count recipe(s) to My Recipes!');
              }
            },
          ),
        ],
      ),
    );
  }

  void _exportAllCustomRecipes(BuildContext context) {
    if (_customRecipes.isEmpty) {
      AppToast.info(context, 'No custom recipes to export. Create one in the builder first!');
      return;
    }

    final jsonStr = RecipeShareService.exportRecipesJson(_customRecipes);
    Clipboard.setData(ClipboardData(text: jsonStr));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: AppTheme.amberHeat, size: 22),
            SizedBox(width: 10),
            Text(
              'Exported Custom Recipes (JSON)',
              style: TextStyle(color: AppTheme.crema, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JSON copied to clipboard! You can save this text as a backup or share it:',
                style: TextStyle(color: AppTheme.emeraldSuccess, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr,
                    style: const TextStyle(color: AppTheme.crema, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Again'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              AppToast.success(context, 'JSON copied to clipboard!');
            },
          ),
          TextButton(
            child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRecipe(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Delete Recipe?', style: TextStyle(color: AppTheme.crema)),
        content: Text(
          'Are you sure you want to delete "${recipe.name}" from My Recipes? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rubyEmergency,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.storageService.deleteCustomRecipe(recipe.id);
              if (mounted) {
                _loadCustomRecipes();
                AppToast.info(this.context, 'Deleted "${recipe.name}"');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // Mode Toggle & Search Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2-Way Segmented Pill Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_modeIndex != 0) {
                                setState(() {
                                  _modeIndex = 0;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _modeIndex == 0 ? AppTheme.goldPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_cafe_outlined,
                                    size: 16,
                                    color: _modeIndex == 0 ? Colors.black : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Curated Presets (${PresetCatalog.presets.length})',
                                    style: TextStyle(
                                      color: _modeIndex == 0 ? Colors.black : AppTheme.textSecondary,
                                      fontWeight: _modeIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _modeIndex = 1;
                                _searchQuery = '';
                                _searchController.clear();
                                _loadCustomRecipes();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _modeIndex == 1 ? AppTheme.goldPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 16,
                                    color: _modeIndex == 1 ? Colors.black : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'My Recipes (${_customRecipes.length})',
                                    style: TextStyle(
                                      color: _modeIndex == 1 ? Colors.black : AppTheme.textSecondary,
                                      fontWeight: _modeIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppTheme.crema, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _modeIndex == 0
                            ? 'Search gourmet presets or ingredients...'
                            : 'Search your custom recipes...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Chips (Only in Curated Presets mode)
                  if (_modeIndex == 0)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppTheme.goldPrimary,
                              backgroundColor: AppTheme.surfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : AppTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.goldPrimary : AppTheme.borderSubtle,
                                  width: 1,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (_modeIndex == 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.goldLight,
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.link, size: 16, color: AppTheme.goldPrimary),
                            label: const Text('Import Share Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _showImportShareLinkDialog(context),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.crema,
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.file_download_outlined, size: 16, color: AppTheme.cyanCold),
                            label: const Text('Import JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _showImportJsonDialog(context),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceElevated,
                              foregroundColor: AppTheme.crema,
                              side: const BorderSide(color: AppTheme.borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 16, color: AppTheme.amberHeat),
                            label: const Text('Export JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: () => _exportAllCustomRecipes(context),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.goldPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Recipe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            onPressed: widget.onOpenBuilder,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Area (Presets or My Recipes)
          if (_modeIndex == 0)
            _buildPresetsGrid()
          else if (_customRecipes.isEmpty)
            _buildEmptyCustomRecipesState()
          else
            _buildCustomRecipesGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomRecipesState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.35)),
                ),
                child: const Icon(Icons.auto_awesome, size: 44, color: AppTheme.goldPrimary),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Custom Recipes Yet',
                style: TextStyle(
                  color: AppTheme.crema,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Design bespoke temperature, RPM, and duration profiles tailored to your exact taste in the Custom Builder, or import shared recipes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Open Custom Builder'),
                    onPressed: widget.onOpenBuilder,
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    icon: const Icon(Icons.link, size: 18, color: AppTheme.goldPrimary),
                    label: const Text('Import Share Link'),
                    onPressed: () => _showImportShareLinkDialog(context),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18, color: AppTheme.cyanCold),
                    label: const Text('Import JSON'),
                    onPressed: () => _showImportJsonDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsGrid() {
    final recipes = _filteredPresets;
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppTheme.goldPrimary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No matching recipes found',
                style: TextStyle(color: AppTheme.crema, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try refining your search term or selecting another category.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 215,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return _buildRecipeCard(context, recipe, isCustom: false);
              },
              childCount: recipes.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomRecipesGrid() {
    final recipes = _filteredCustomRecipes;
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppTheme.goldPrimary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No matching custom recipes found',
                style: TextStyle(color: AppTheme.crema, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try refining your search term.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 215,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return _buildRecipeCard(context, recipe, isCustom: true);
              },
              childCount: recipes.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, {required bool isCustom}) {
    final isCold = recipe.isCold;
    final isFavorite = widget.storageService.isFavorite(recipe.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCustom ? AppTheme.goldPrimary.withOpacity(0.3) : AppTheme.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Star Favorite, and Hot/Cold Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: const TextStyle(
                    color: AppTheme.crema,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFavorite ? AppTheme.goldPrimary : AppTheme.textMuted,
                ),
                tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.storageService.toggleFavorite(recipe.id),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isCold
                      ? AppTheme.cyanCold.withOpacity(0.12)
                      : AppTheme.amberHeat.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCold
                        ? AppTheme.cyanCold.withOpacity(0.6)
                        : AppTheme.amberHeat.withOpacity(0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCold ? Icons.ac_unit : Icons.local_fire_department,
                      size: 11,
                      color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isCold ? 'Cold' : '${recipe.maxTemp}°C',
                      style: TextStyle(
                        color: isCold ? AppTheme.cyanCold : AppTheme.amberHeat,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Pills Row: Duration, Peak RPM, Phases
          Row(
            children: [
              _buildPill(Icons.timer_outlined, '${recipe.totalDurationSeconds}s'),
              const SizedBox(width: 6),
              _buildPill(Icons.rotate_right, '${recipe.peakRpm} RPM'),
              const SizedBox(width: 6),
              _buildPill(Icons.layers_outlined, '${recipe.activePhases.length}p'),
              if (recipe.isMultiStep) ...[
                const SizedBox(width: 6),
                _buildPill(Icons.alt_route, '${recipe.stepCount} Steps', color: AppTheme.goldLight),
              ],
              if (isCustom) ...[
                const SizedBox(width: 6),
                _buildPill(Icons.star, 'Custom'),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Expanded(
            child: Text(
              recipe.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: isCustom ? 4 : 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    foregroundColor: AppTheme.crema,
                  ),
                  icon: Icon(
                    isCustom ? Icons.tune : Icons.menu_book_outlined,
                    size: 14,
                    color: AppTheme.goldLight,
                  ),
                  label: Text(
                    isCustom ? 'Edit in Builder' : 'Guide',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    if (isCustom) {
                      widget.onCustomize?.call(recipe);
                    } else {
                      RecipeDetailDialog.show(
                        context,
                        recipe: recipe,
                        bleService: widget.bleService,
                        onCustomize: widget.onCustomize,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: isCustom ? 3 : 1,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text(
                    'Flash',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    FlashRecipeDialog.show(
                      context,
                      recipe: recipe,
                      bleService: widget.bleService,
                    );
                  },
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.share, size: 18, color: AppTheme.goldLight),
                  tooltip: 'Share Code',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _shareRecipe(context, recipe),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                  tooltip: 'More Options',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  color: AppTheme.surfaceCard,
                  onSelected: (val) {
                    if (val == 'share') {
                      _shareRecipe(context, recipe);
                    } else if (val == 'edit') {
                      _showEditRecipeDetailsDialog(context, recipe);
                    } else if (val == 'delete') {
                      _confirmDeleteRecipe(context, recipe);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 18, color: AppTheme.goldLight),
                          SizedBox(width: 10),
                          Text('Share Code', style: TextStyle(color: AppTheme.crema, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, size: 18, color: AppTheme.goldLight),
                          SizedBox(width: 10),
                          Text('Customize Details', style: TextStyle(color: AppTheme.crema, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.rubyEmergency),
                          SizedBox(width: 10),
                          Text('Delete Recipe', style: TextStyle(color: AppTheme.rubyEmergency, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.12) : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color != null ? color.withOpacity(0.4) : AppTheme.borderSubtle,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color ?? AppTheme.goldPrimary),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color ?? AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
