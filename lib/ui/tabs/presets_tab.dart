import 'package:flutter/material.dart';
import '../../data/preset_catalog.dart';
import '../../models/recipe.dart';
import '../../services/barista_ble_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/flash_recipe_dialog.dart';
import '../widgets/recipe_detail_dialog.dart';

class PresetsTab extends StatefulWidget {
  final BaristaBleService bleService;
  final void Function(Recipe recipe)? onCustomize;

  const PresetsTab({
    super.key,
    required this.bleService,
    this.onCustomize,
  });

  @override
  State<PresetsTab> createState() => _PresetsTabState();
}

class _PresetsTabState extends State<PresetsTab> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Recipe> get _filteredRecipes {
    return PresetCatalog.presets.where((r) {
      final matchesCategory =
          _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.ingredients.any((i) => i.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // Filter & Search Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        hintText: 'Search gourmet recipes or ingredients...',
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

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PresetCatalog.categories.map((cat) {
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
                ],
              ),
            ),
          ),

          // Recipe Cards Grid
          SliverPadding(
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
                      final recipe = _filteredRecipes[index];
                      return _buildRecipeCard(context, recipe);
                    },
                    childCount: _filteredRecipes.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final isCold = recipe.isCold;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Hot/Cold Badge
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
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppTheme.borderSubtle),
                    foregroundColor: AppTheme.crema,
                  ),
                  onPressed: () {
                    RecipeDetailDialog.show(
                      context,
                      recipe: recipe,
                      bleService: widget.bleService,
                      onCustomize: widget.onCustomize,
                    );
                  },
                  child: const Text('Guide', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.flash_on, size: 14),
                  label: const Text('Flash', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    FlashRecipeDialog.show(
                      context,
                      recipe: recipe,
                      bleService: widget.bleService,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.goldPrimary),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
