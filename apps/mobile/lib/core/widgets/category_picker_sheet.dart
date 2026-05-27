import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/category_visuals.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/category/domain/entities/category_entity.dart';

/// Resultado da seleção no [CategoryPickerSheet].
///
/// `category` é null quando o usuário escolhe "Sem categoria" (apenas se
/// o sheet for aberto com `allowNoCategory: true`).
class CategoryPickerResult {
  final CategoryEntity? category;
  const CategoryPickerResult(this.category);
}

/// Abre um bottom sheet padronizado para escolher uma categoria.
///
/// Recursos:
/// - Lista ordenada alfabeticamente
/// - Campo de busca no topo (filtra por nome em tempo real)
/// - Ícones e cores derivados do nome da categoria (ou do `color` salvo)
/// - Subcategorias agrupadas sob o pai (visual indented)
/// - Item especial "Sem categoria" no topo quando [allowNoCategory] é true
/// - Estado selecionado destacado com borda colorida
/// - Empty state quando a busca não devolve nada
///
/// [categories] já deve vir filtrada por tipo (Despesa/Receita/Transf.)
/// quando aplicável. Esse widget só ordena e exibe.
///
/// [highlightId] marca o id atualmente selecionado para destaque visual.
Future<CategoryPickerResult?> showCategoryPickerSheet(
  BuildContext context, {
  required List<CategoryEntity> categories,
  String? highlightId,
  String title = 'Selecione uma categoria',
  String? subtitle,
  bool allowNoCategory = true,
  String noCategoryLabel = 'Sem categoria',
  String? noCategorySubtitle,
}) {
  return showModalBottomSheet<CategoryPickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CategoryPickerSheetBody(
      categories: categories,
      highlightId: highlightId,
      title: title,
      subtitle: subtitle,
      allowNoCategory: allowNoCategory,
      noCategoryLabel: noCategoryLabel,
      noCategorySubtitle: noCategorySubtitle,
    ),
  );
}

class _CategoryPickerSheetBody extends StatefulWidget {
  final List<CategoryEntity> categories;
  final String? highlightId;
  final String title;
  final String? subtitle;
  final bool allowNoCategory;
  final String noCategoryLabel;
  final String? noCategorySubtitle;

  const _CategoryPickerSheetBody({
    required this.categories,
    required this.highlightId,
    required this.title,
    required this.subtitle,
    required this.allowNoCategory,
    required this.noCategoryLabel,
    required this.noCategorySubtitle,
  });

  @override
  State<_CategoryPickerSheetBody> createState() =>
      _CategoryPickerSheetBodyState();
}

class _CategoryPickerSheetBodyState extends State<_CategoryPickerSheetBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(CategoryEntity c) {
    if (_query.isEmpty) return true;
    return c.name.toLowerCase().contains(_query.toLowerCase());
  }

  /// Organiza categorias em uma estrutura "pai + filhos", ordenadas
  /// alfabeticamente. Quando há filtro de busca:
  ///  - Pai aparece se ele OU algum filho casar
  ///  - Filhos não-casados ficam ocultos sob um pai que casou
  ///  - Filhos casados aparecem mesmo se o pai não casou (mostra o pai como
  ///    cabeçalho não-clicável para contexto)
  List<_PickerEntry> _buildEntries() {
    final byId = {for (final c in widget.categories) c.id: c};
    final roots = widget.categories
        .where((c) => c.parentId == null || !byId.containsKey(c.parentId))
        .toList();
    final childrenByParent = <String, List<CategoryEntity>>{};
    for (final c in widget.categories) {
      if (c.parentId != null && byId.containsKey(c.parentId)) {
        childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    int alphabetical(CategoryEntity a, CategoryEntity b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());

    roots.sort(alphabetical);
    childrenByParent.forEach((_, list) => list.sort(alphabetical));

    final entries = <_PickerEntry>[];
    for (final parent in roots) {
      final parentMatches = _matchesQuery(parent);
      final children = childrenByParent[parent.id] ?? const [];
      final matchedChildren = children.where(_matchesQuery).toList();

      // Se nem o pai nem filhos casam com a busca, pula.
      if (!parentMatches && matchedChildren.isEmpty) continue;

      entries.add(_PickerEntry.parent(parent, isHeaderOnly: !parentMatches));

      // Se há query, só mostra os filhos que casam.
      // Sem query, mostra todos os filhos do pai.
      final toShow = _query.isEmpty ? children : matchedChildren;
      for (final child in toShow) {
        entries.add(_PickerEntry.child(child));
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final entries = _buildEntries();

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: tc.neoCardElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tc.neoTextFaint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: tc.neoText,
                ),
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.subtitle!,
                  style: TextStyle(fontSize: 12.5, color: tc.neoTextMuted),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: TextStyle(
                  fontSize: 14,
                  color: tc.neoText,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar categoria',
                  hintStyle: TextStyle(
                    color: tc.neoTextFaint,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: tc.neoTextMuted, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: tc.neoTextMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: tc.neoCard,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tc.neoCardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tc.neoCardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: tc.neoTeal, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: entries.isEmpty && !widget.allowNoCategory
                  ? _buildEmpty(tc)
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      children: [
                        if (widget.allowNoCategory && _query.isEmpty)
                          _NoCategoryTile(
                            label: widget.noCategoryLabel,
                            subtitle: widget.noCategorySubtitle,
                            selected: widget.highlightId == null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(
                                  context, const CategoryPickerResult(null));
                            },
                          ),
                        if (widget.allowNoCategory && _query.isEmpty)
                          const SizedBox(height: 8),
                        if (entries.isEmpty)
                          _buildEmpty(tc)
                        else
                          for (final entry in entries) ...[
                            _PickerTile(
                              entry: entry,
                              highlightId: widget.highlightId,
                              query: _query,
                              onTap: entry.isHeaderOnly
                                  ? null
                                  : () {
                                      HapticFeedback.selectionClick();
                                      Navigator.pop(
                                        context,
                                        CategoryPickerResult(entry.category),
                                      );
                                    },
                            ),
                            const SizedBox(height: 6),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            IconBadge(
              icon: Icons.search_off_rounded,
              tone: 'neutral',
              size: 48,
              iconSize: 22,
              radius: 14,
            ),
            const SizedBox(height: 10),
            Text(
              _query.isEmpty
                  ? 'Nenhuma categoria disponível'
                  : 'Nada encontrado para "$_query"',
              style: TextStyle(
                fontSize: 13,
                color: tc.neoTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerEntry {
  final CategoryEntity category;
  final bool isChild;

  /// True quando o pai só está na lista como cabeçalho para dar contexto
  /// aos filhos casados — o pai em si não casou com a query.
  final bool isHeaderOnly;

  _PickerEntry.parent(this.category, {this.isHeaderOnly = false})
      : isChild = false;

  _PickerEntry.child(this.category)
      : isChild = true,
        isHeaderOnly = false;
}

class _PickerTile extends StatelessWidget {
  final _PickerEntry entry;
  final String? highlightId;
  final String query;
  final VoidCallback? onTap;

  const _PickerTile({
    required this.entry,
    required this.highlightId,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final cat = entry.category;
    final selected = cat.id == highlightId;
    final visuals = iconAndToneForCategory(cat.name);
    final overrideColor = colorFromCategoryHex(cat.color);
    final iconBadge = overrideColor != null
        ? IconBadge(
            icon: visuals.icon,
            background: overrideColor
                .withValues(alpha: tc.isDark ? 0.22 : 0.18),
            foreground: overrideColor,
          )
        : IconBadge(icon: visuals.icon, tone: visuals.tone);

    final disabled = entry.isHeaderOnly;
    final indent = entry.isChild ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Material(
        color: selected
            ? tc.neoTeal.withValues(alpha: tc.isDark ? 0.10 : 0.06)
            : tc.neoCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? tc.neoTeal : tc.neoCardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Opacity(opacity: disabled ? 0.55 : 1.0, child: iconBadge),
                const SizedBox(width: 12),
                Expanded(
                  child: _HighlightedText(
                    text: cat.name,
                    query: query,
                    baseStyle: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? tc.neoTextFaint
                          : (selected ? tc.neoTeal : tc.neoText),
                    ),
                    highlightStyle: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? tc.neoTeal : tc.neoText,
                      backgroundColor: tc.neoAttention.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: tc.neoTeal, size: 20)
                else if (entry.isChild)
                  Text(
                    'sub',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: tc.neoTextFaint,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final idx = lowerText.indexOf(lowerQuery);
    if (idx < 0) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: highlightStyle,
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

class _NoCategoryTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _NoCategoryTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: selected
          ? tc.neoTeal.withValues(alpha: tc.isDark ? 0.10 : 0.06)
          : tc.neoCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? tc.neoTeal : tc.neoCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              IconBadge(icon: Icons.block_rounded, tone: 'neutral'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? tc.neoTeal : tc.neoText,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.neoTextMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: tc.neoTeal, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
