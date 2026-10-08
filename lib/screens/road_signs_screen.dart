import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/road_sign.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/road_sign_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sources_note.dart';
import '../utils/text_search.dart';

/// Free, ungated illustrated gallery of road signs and their meanings —
/// reference material, not a graded test, matching the website's free
/// /belgilar page.
///
/// Built out of slivers rather than grids nested in a list: the old layout
/// used `shrinkWrap` grids inside a `ListView`, which forced all 269 tiles
/// (and their images) to be built and decoded up front, so opening the screen
/// and every keystroke in the search box dropped frames.
class RoadSignsScreen extends StatefulWidget {
  const RoadSignsScreen({super.key});

  @override
  State<RoadSignsScreen> createState() => _RoadSignsScreenState();
}

class _RoadSignsScreenState extends State<RoadSignsScreen> {
  late Future<List<RoadSignGroup>> _future;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = RoadSignService.loadGroups();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Filtering rebuilds the whole gallery, so it waits for a pause in typing
  /// instead of running on every keystroke.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final next = foldForSearch(value.trim());
      if (!mounted || next == _query) return;
      setState(() => _query = next);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      // The search field is pinned above the scrollable grid, so it's never
      // covered by the keyboard — no need to pay for a full-Scaffold resize
      // (and the relayout of the whole grid) every time the keyboard opens.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(s('road_signs'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: s('search_road_signs'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clearQuery,
                      ),
                filled: true,
                fillColor: AppTheme.card(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RoadSignGroup>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.blue),
                  );
                }

                final filtered = _filterGroups(snapshot.data ?? const [], lang);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      s('no_results'),
                      style: TextStyle(color: AppTheme.textM(context)),
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  // Only what fits on screen (plus a little) is ever built.
                  slivers: [
                    for (final group in filtered) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            group.getTitle(lang),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textP(context),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _SignTile(sign: group.items[index], lang: lang),
                            childCount: group.items.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: SourcesNote(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<RoadSignGroup> _filterGroups(List<RoadSignGroup> groups, String lang) {
    if (_query.isEmpty) return groups;
    final result = <RoadSignGroup>[];
    for (final group in groups) {
      final items = group.items.where((item) {
        // Folded on both sides so `o'q` and `o'q` are the same query
        // (see foldForSearch).
        return foldForSearch(item.code).contains(_query) ||
            foldForSearch(item.getTitle(lang)).contains(_query);
      }).toList();
      if (items.isNotEmpty) {
        result.add(RoadSignGroup(titles: group.titles, items: items));
      }
    }
    return result;
  }
}

class _SignTile extends StatelessWidget {
  final RoadSign sign;
  final String lang;

  const _SignTile({required this.sign, required this.lang});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border(ctx)),
              ),
              child: Image.asset(
                'assets/tests-json/belgilar_images/${sign.assetFileName}',
                fit: BoxFit.contain,
                cacheWidth: 480,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sign.code,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sign.getTitle(lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textP(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Image.asset(
                    'assets/tests-json/belgilar_images/${sign.assetFileName}',
                    fit: BoxFit.contain,
                    // Thumbnails are ~110 dp wide; decoding the full-size
                    // artwork for every tile is what made this grid heavy.
                    cacheWidth: 240,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sign.code,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textM(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
