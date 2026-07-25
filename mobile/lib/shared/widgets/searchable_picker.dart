import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/app_spacing.dart';
import '../../domain/models/models.dart';

/// Tappable field that opens a searchable bottom-sheet picker.
class SearchableSelectField extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    this.valueText,
    this.subtitle,
    this.enabled = true,
    this.leadingIcon = Icons.list_alt_rounded,
  });

  final String label;
  final String hint;
  final String? valueText;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText != null && valueText!.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: enabled ? AppColors.surface : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: hasValue
                      ? AppColors.charcoal.withValues(alpha: 0.22)
                      : AppColors.border,
                  width: hasValue ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasValue
                          ? AppColors.brandRed.withValues(alpha: 0.1)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: hasValue
                          ? AppColors.brandRed
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasValue ? valueText! : hint,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: hasValue
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                hasValue ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Generic searchable bottom-sheet picker.
Future<T?> showSearchablePickerSheet<T>({
  required BuildContext context,
  required List<T> items,
  required String Function(T item) labelOf,
  required bool Function(T item, T? selected) isSelected,
  required bool Function(T item, String query) matchesQuery,
  T? selected,
  String title = 'Select',
  String? subtitle,
  String searchHint = 'Search…',
  String itemNoun = 'items',
  String emptyHint = 'Try a different search.',
  String? Function(T item)? secondaryLabelOf,
  IconData itemIcon = Icons.circle_outlined,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (_) => _SearchablePickerSheet<T>(
      items: items,
      selected: selected,
      title: title,
      subtitle: subtitle,
      searchHint: searchHint,
      itemNoun: itemNoun,
      emptyHint: emptyHint,
      labelOf: labelOf,
      secondaryLabelOf: secondaryLabelOf,
      isSelected: isSelected,
      matchesQuery: matchesQuery,
      itemIcon: itemIcon,
    ),
  );
}

Future<RouteModel?> showRoutePickerSheet({
  required BuildContext context,
  required List<RouteModel> routes,
  RouteModel? selected,
  String title = 'Select route',
  String? subtitle,
  String searchHint = 'Search origin or destination',
}) {
  return showSearchablePickerSheet<RouteModel>(
    context: context,
    items: routes,
    selected: selected,
    title: title,
    subtitle: subtitle,
    searchHint: searchHint,
    itemNoun: 'routes',
    emptyHint: 'Try a different origin or destination.',
    itemIcon: Icons.alt_route_rounded,
    labelOf: (r) => '${r.origin}  →  ${r.destination}',
    secondaryLabelOf: (r) => r.hasParents ? 'Linked segment' : null,
    isSelected: (item, selected) => selected?.id == item.id,
    matchesQuery: (r, q) =>
        r.origin.toLowerCase().contains(q) ||
        r.destination.toLowerCase().contains(q) ||
        r.label.toLowerCase().contains(q),
  );
}

Future<FleetModel?> showFleetPickerSheet({
  required BuildContext context,
  required List<FleetModel> fleets,
  FleetModel? selected,
  String title = 'Select bus',
  String? subtitle,
  String searchHint = 'Search fleet number',
}) {
  return showSearchablePickerSheet<FleetModel>(
    context: context,
    items: fleets,
    selected: selected,
    title: title,
    subtitle: subtitle,
    searchHint: searchHint,
    itemNoun: 'buses',
    emptyHint: 'Try a different fleet number.',
    itemIcon: Icons.directions_bus_rounded,
    labelOf: (f) => f.number,
    secondaryLabelOf: (f) =>
        f.status == null || f.status!.isEmpty ? null : f.status,
    isSelected: (item, selected) => selected?.id == item.id,
    matchesQuery: (f, q) =>
        f.number.toLowerCase().contains(q) ||
        (f.status?.toLowerCase().contains(q) ?? false),
  );
}

Future<DriverModel?> showDriverPickerSheet({
  required BuildContext context,
  required List<DriverModel> drivers,
  DriverModel? selected,
  String title = 'Select driver',
  String? subtitle,
  String searchHint = 'Search driver name',
}) {
  return showSearchablePickerSheet<DriverModel>(
    context: context,
    items: drivers,
    selected: selected,
    title: title,
    subtitle: subtitle,
    searchHint: searchHint,
    itemNoun: 'drivers',
    emptyHint: 'Try a different driver name.',
    itemIcon: Icons.person_rounded,
    labelOf: (d) => d.fullName,
    secondaryLabelOf: (d) =>
        d.status == null || d.status!.isEmpty ? null : d.status,
    isSelected: (item, selected) => selected?.id == item.id,
    matchesQuery: (d, q) => d.fullName.toLowerCase().contains(q),
  );
}

Future<String?> showCurrencyPickerSheet({
  required BuildContext context,
  required List<String> currencies,
  String? selected,
  String title = 'Select currency',
  String? subtitle,
  String searchHint = 'Search currency',
}) {
  return showSearchablePickerSheet<String>(
    context: context,
    items: currencies,
    selected: selected,
    title: title,
    subtitle: subtitle,
    searchHint: searchHint,
    itemNoun: 'currencies',
    emptyHint: 'Try a different currency code.',
    itemIcon: Icons.payments_outlined,
    labelOf: (c) => c,
    secondaryLabelOf: _currencySecondaryLabel,
    isSelected: (item, selected) => selected == item,
    matchesQuery: (c, q) {
      final label = _currencySecondaryLabel(c)?.toLowerCase() ?? '';
      return c.toLowerCase().contains(q) || label.contains(q);
    },
  );
}

String? _currencySecondaryLabel(String code) {
  return switch (code.toUpperCase()) {
    'USD' => 'US Dollar',
    'ZWG' => 'Zimbabwe Gold',
    'ZIG' => 'Zimbabwe Gold',
    'ZWL' => 'Zimbabwe Dollar',
    'ZAR' => 'South African Rand',
    'EUR' => 'Euro',
    'GBP' => 'British Pound',
    'BWP' => 'Botswana Pula',
    'MWK' => 'Malawian Kwacha',
    'MZN' => 'Mozambican Metical',
    _ => null,
  };
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.items,
    required this.title,
    required this.searchHint,
    required this.itemNoun,
    required this.emptyHint,
    required this.labelOf,
    required this.isSelected,
    required this.matchesQuery,
    required this.itemIcon,
    this.selected,
    this.subtitle,
    this.secondaryLabelOf,
  });

  final List<T> items;
  final T? selected;
  final String title;
  final String? subtitle;
  final String searchHint;
  final String itemNoun;
  final String emptyHint;
  final String Function(T item) labelOf;
  final String? Function(T item)? secondaryLabelOf;
  final bool Function(T item, T? selected) isSelected;
  final bool Function(T item, String query) matchesQuery;
  final IconData itemIcon;

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) => widget.matchesQuery(item, q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final showSearch = widget.items.length > 5;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: theme.textTheme.titleLarge),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (showSearch) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      autofocus: widget.items.length > 8,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    filtered.length == widget.items.length
                        ? '${widget.items.length} ${widget.itemNoun}'
                        : '${filtered.length} of ${widget.items.length} ${widget.itemNoun}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _query.isEmpty
                                  ? 'No ${widget.itemNoun} available'
                                  : 'No ${widget.itemNoun} match “$_query”',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.emptyHint,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = widget.isSelected(item, widget.selected);
                        final secondary = widget.secondaryLabelOf?.call(item);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brandRed.withValues(alpha: 0.12)
                                  : AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Icon(
                              selected ? Icons.check_rounded : widget.itemIcon,
                              color: selected
                                  ? AppColors.brandRed
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            widget.labelOf(item),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected
                                  ? AppColors.brandRed
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: secondary == null || secondary.isEmpty
                              ? null
                              : Text(
                                  secondary,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.brandRed,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
