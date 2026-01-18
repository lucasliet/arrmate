import 'package:flutter/material.dart';

/// A text field with autocomplete support for qBittorrent categories.
///
/// Features:
/// - Lazy loading: fetches categories on focus
/// - Free input: allows typing custom categories
/// - Fallback: if fetch fails, behaves as regular text field
class CategoryAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Future<List<String>> Function() onFetchCategories;

  const CategoryAutocompleteField({
    super.key,
    required this.controller,
    required this.onFetchCategories,
  });

  @override
  State<CategoryAutocompleteField> createState() =>
      _CategoryAutocompleteFieldState();
}

class _CategoryAutocompleteFieldState extends State<CategoryAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  List<String> _categories = [];
  bool _isLoading = false;
  bool _hasFetched = false;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_hasFetched && !_fetchFailed) {
      _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories = await widget.onFetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _hasFetched = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchFailed = true;
          _isLoading = false;
        });
        // Show visual feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load categories. Using free text mode.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If fetch failed or no categories, show regular text field
    if (_fetchFailed || (_hasFetched && _categories.isEmpty)) {
      return TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: 'Category (Optional)',
          prefixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.category),
          border: const OutlineInputBorder(),
        ),
      );
    }

    return RawAutocomplete<String>(
      focusNode: _focusNode,
      textEditingController: widget.controller,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty || _categories.isEmpty) {
          return _categories;
        }
        return _categories.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Category (Optional)',
                prefixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.category),
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 300,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}
