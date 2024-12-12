import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_model.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../services/search_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import '../widgets/task_list_item.dart';
import '../widgets/meeting_list_item.dart';
import '../widgets/user_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  SearchFilter _filter = SearchFilter();
  String _selectedType = 'tasks'; // tasks, meetings, users
  bool _isLoading = false;
  bool _hasMore = false;
  String? _nextPageToken;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
      _nextPageToken = null;
    });

    try {
      final searchService = Provider.of<SearchService>(context, listen: false);
      final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;

      if (currentUser == null) return;

      // Arama geçmişine kaydet
      await searchService.saveSearchHistory(
        currentUser.uid,
        _searchController.text,
      );

      // Filtreyi güncelle
      _filter = _filter.copyWith(
        searchText: _searchController.text,
      );

      // Seçilen tipe göre arama yap
      SearchResult result;
      switch (_selectedType) {
        case 'tasks':
          result = await searchService.searchTasks(_filter);
          break;
        case 'meetings':
          result = await searchService.searchMeetings(_filter);
          break;
        case 'users':
          result = await searchService.searchUsers(_filter);
          break;
        default:
          return;
      }

      setState(() {
        _searchResults = result.items;
        _hasMore = result.hasMore;
        _nextPageToken = result.nextPageToken;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_nextPageToken == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchService = Provider.of<SearchService>(context, listen: false);

      SearchResult result;
      switch (_selectedType) {
        case 'tasks':
          result = await searchService.searchTasks(
            _filter,
            nextPageToken: _nextPageToken,
          );
          break;
        case 'meetings':
          result = await searchService.searchMeetings(
            _filter,
            nextPageToken: _nextPageToken,
          );
          break;
        case 'users':
          result = await searchService.searchUsers(
            _filter,
            nextPageToken: _nextPageToken,
          );
          break;
        default:
          return;
      }

      setState(() {
        _searchResults.addAll(result.items);
        _hasMore = result.hasMore;
        _nextPageToken = result.nextPageToken;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        filter: _filter,
        onApply: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
          _search();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Ara...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults.clear();
                });
              },
            ),
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeSelector(),
          _buildSearchHistory(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'tasks',
            label: Text('Görevler'),
            icon: Icon(Icons.task),
          ),
          ButtonSegment(
            value: 'meetings',
            label: Text('Toplantılar'),
            icon: Icon(Icons.meeting_room),
          ),
          ButtonSegment(
            value: 'users',
            label: Text('Kullanıcılar'),
            icon: Icon(Icons.people),
          ),
        ],
        selected: {_selectedType},
        onSelectionChanged: (Set<String> selection) {
          setState(() {
            _selectedType = selection.first;
            _searchResults.clear();
          });
          if (_searchController.text.isNotEmpty) {
            _search();
          }
        },
      ),
    );
  }

  Widget _buildSearchHistory() {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    if (currentUser == null || _searchResults.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<String>>(
      stream: Provider.of<SearchService>(context)
          .getSearchHistory(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Son Aramalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Provider.of<SearchService>(context, listen: false)
                          .clearSearchHistory(currentUser.uid);
                    },
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: snapshot.data!.map((text) {
                return ActionChip(
                  label: Text(text),
                  onPressed: () {
                    _searchController.text = text;
                    _search();
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı: "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Arama yapmak için yukarıdaki alanı kullanın',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} sonuç bulundu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_filter.isEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Filtreleri Temizle'),
                  onPressed: () {
                    setState(() {
                      _filter = SearchFilter();
                    });
                    _search();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _searchResults.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _searchResults.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = _searchResults[index];
              if (item is TaskModel) {
                return TaskListItem(task: item);
              } else if (item is MeetingModel) {
                return MeetingListItem(meeting: item);
              } else if (item is UserModel) {
                return UserListItem(user: item);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class FilterDialog extends StatefulWidget {
  final SearchFilter filter;
  final Function(SearchFilter) onApply;

  const FilterDialog({
    super.key,
    required this.filter,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late SearchFilter _filter;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
    _startDateController.text = _filter.startDate != null
        ? '${_filter.startDate!.day}/${_filter.startDate!.month}/${_filter.startDate!.year}'
        : '';
    _endDateController.text = _filter.endDate != null
        ? '${_filter.endDate!.day}/${_filter.endDate!.month}/${_filter.endDate!.year}'
        : '';
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrele'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Departman filtresi
            const Text('Departmanlar'),
            Wrap(
              spacing: 8,
              children: AppConstants.departments.map((department) {
                return FilterChip(
                  label: Text(department),
                  selected: _filter.departments?.contains(department) ?? false,
                  onSelected: (selected) {
                    setState(() {
                      final departments = _filter.departments?.toList() ?? [];
                      if (selected) {
                        departments.add(department);
                      } else {
                        departments.remove(department);
                      }
                      _filter = _filter.copyWith(departments: departments);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Durum filtresi
            const Text('Durumlar'),
            Wrap(
              spacing: 8,
              children: AppConstants.statusLabels.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value),
                  selected: _filter.statuses?.contains(entry.key) ?? false,
                  onSelected: (selected) {
                    setState(() {
                      final statuses = _filter.statuses?.toList() ?? [];
                      if (selected) {
                        statuses.add(entry.key);
                      } else {
                        statuses.remove(entry.key);
                      }
                      _filter = _filter.copyWith(statuses: statuses);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Tarih filtresi
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç Tarihi',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filter.startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _filter = _filter.copyWith(startDate: date);
                          _startDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Bitiş Tarihi',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filter.endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _filter = _filter.copyWith(endDate: date);
                          _endDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sıralama
            DropdownButtonFormField<String>(
              value: _filter.sortBy,
              decoration: const InputDecoration(
                labelText: 'Sıralama',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'createdAt',
                  child: Text('Oluşturma Tarihi'),
                ),
                DropdownMenuItem(
                  value: 'dueDate',
                  child: Text('Bitiş Tarihi'),
                ),
                DropdownMenuItem(
                  value: 'priority',
                  child: Text('Öncelik'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(sortBy: value);
                });
              },
            ),

            const SizedBox(height: 8),

            // Sıralama yönü
            CheckboxListTile(
              title: const Text('Artan Sıralama'),
              value: _filter.sortAscending ?? true,
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(sortAscending: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _filter = SearchFilter();
            widget.onApply(_filter);
            Navigator.pop(context);
          },
          child: const Text('Temizle'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_filter);
            Navigator.pop(context);
          },
          child: const Text('Uygula'),
        ),
      ],
    );
  }
} 