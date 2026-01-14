import 'package:flutter/material.dart';

/// A text field with autocomplete support for qBittorrent tags.
///
/// Features:
/// - Multi-value: allows selecting multiple tags
/// - Chips display: shows selected tags as chips
/// - Lazy loading: fetches tags on focus
/// - Free input: allows typing custom tags separated by comma
/// - Fallback: if fetch fails, behaves as regular text field
class TagsAutocompleteField extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final Future<List<String>> Function() onFetchTags;

  const TagsAutocompleteField({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.onFetchTags,
  });

  @override
  State<TagsAutocompleteField> createState() => _TagsAutocompleteFieldState();
}

class _TagsAutocompleteFieldState extends State<TagsAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  List<String> _availableTags = [];
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
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_hasFetched && !_fetchFailed) {
      _fetchTags();
    }
  }

  Future<void> _fetchTags() async {
    setState(() => _isLoading = true);

    try {
      final tags = await widget.onFetchTags();
      if (mounted) {
        setState(() {
          _availableTags = tags;
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
            content: Text('Could not load tags. Using free text mode.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !widget.selectedTags.contains(trimmedTag)) {
      widget.onTagsChanged([...widget.selectedTags, trimmedTag]);
      _textController.clear();
    }
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.selectedTags.where((t) => t != tag).toList());
  }

  void _handleSubmit(String value) {
    // Handle comma-separated input
    final tags = value
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty);
    final newTags = <String>[...widget.selectedTags];

    for (final tag in tags) {
      if (!newTags.contains(tag)) {
        newTags.add(tag);
      }
    }

    if (newTags.length != widget.selectedTags.length) {
      widget.onTagsChanged(newTags);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected tags as chips
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Autocomplete field or regular text field
        if (_fetchFailed || (_hasFetched && _availableTags.isEmpty))
          TextFormField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Comma separated',
              prefixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.label),
              border: const OutlineInputBorder(),
            ),
            onFieldSubmitted: _handleSubmit,
          )
        else
          RawAutocomplete<String>(
            focusNode: _focusNode,
            textEditingController: _textController,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty || _availableTags.isEmpty) {
                return _availableTags.where(
                  (tag) => !widget.selectedTags.contains(tag),
                );
              }
              return _availableTags.where(
                (tag) =>
                    !widget.selectedTags.contains(tag) &&
                    tag.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
              );
            },
            onSelected: (String selection) {
              _addTag(selection);
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
                      labelText: 'Tags (Optional)',
                      hintText: 'Type to search or add custom tags',
                      prefixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(Icons.label),
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (value) {
                      _handleSubmit(value);
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
          ),
      ],
    );
  }
}
