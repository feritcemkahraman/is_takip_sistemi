import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerWidget extends StatefulWidget {
  final Function(String) onEmojiSelected;
  final bool showSearchBar;
  final bool showRecentsTab;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.showSearchBar = true,
    this.showRecentsTab = true,
  });

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  Category _currentCategory = Category.RECENT;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearchBar)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Emoji ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        Expanded(
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              widget.onEmojiSelected(emoji.emoji);
            },
            onBackspacePressed: () {
              // Silme tuşuna basıldığında yapılacak işlem
            },
            config: Config(
              columns: 7,
              emojiSizeMax: 32,
              verticalSpacing: 0,
              horizontalSpacing: 0,
              initCategory: _currentCategory,
              bgColor: Theme.of(context).scaffoldBackgroundColor,
              indicatorColor: Theme.of(context).colorScheme.primary,
              iconColor: Colors.grey,
              iconColorSelected: Theme.of(context).colorScheme.primary,
              backspaceColor: Theme.of(context).colorScheme.primary,
              skinToneDialogBgColor: Colors.white,
              skinToneIndicatorColor: Colors.grey,
              enableSkinTones: true,
              showRecentsTab: widget.showRecentsTab,
              recentTabBehavior: RecentTabBehavior.RECENT,
              recentsLimit: 28,
              replaceEmojiOnLimitExceed: true,
              noRecents: const Text(
                'Henüz emoji kullanılmadı',
                style: TextStyle(fontSize: 20, color: Colors.black26),
                textAlign: TextAlign.center,
              ),
              loadingIndicator: const SizedBox.shrink(),
              tabIndicatorAnimDuration: kTabScrollDuration,
              categoryIcons: const CategoryIcons(),
              buttonMode: ButtonMode.MATERIAL,
              checkPlatformCompatibility: true,
            ),
          ),
        ),
      ],
    );
  }
} 