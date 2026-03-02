import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/user_search_result_model.dart';

class PeopleSearchScreen extends StatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  String _query = '';
  List<UserSearchResult> _results = [];
  bool _loading = false;
  bool _hasMore = false;
  bool _myCityOnly = true;
  int _offset = 0;

  static const int _pageSize = 20;

  String? get _cityId {
    if (!_myCityOnly) return null;
    return ServiceLocator.currentCityService.currentCityId;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value != _query) {
        setState(() => _query = value);
        _search(reset: true);
      }
    });
  }

  void _onCityFilterChanged(bool value) {
    setState(() => _myCityOnly = value);
    _search(reset: true);
  }

  Future<void> _search({required bool reset}) async {
    if (_query.trim().length < 2) {
      setState(() {
        _results = [];
        _loading = false;
        _hasMore = false;
        _offset = 0;
      });
      return;
    }

    final offset = reset ? 0 : _offset;

    setState(() => _loading = true);

    try {
      final items = await ServiceLocator.usersService.searchUsers(
        _query.trim(),
        cityId: _cityId,
        limit: _pageSize,
        offset: offset,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _results = items;
        } else {
          _results = [..._results, ...items];
        }
        _offset = offset + items.length;
        _hasMore = items.length == _pageSize;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.findPeople)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: l10n.peopleSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(l10n.peopleMyCity),
                selected: _myCityOnly,
                onSelected: _onCityFilterChanged,
              ),
            ),
          ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_query.trim().length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.peopleSearchPlaceholder,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.peopleSearchEmpty,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => _search(reset: false),
                      child: Text(l10n.loadMore),
                    ),
            ),
          );
        }
        return _UserSearchCard(
          result: _results[index],
          onTap: () => context.push(
            '/user/${_results[index].id}',
            extra: _results[index],
          ),
        );
      },
    );
  }
}

class _UserSearchCard extends StatelessWidget {
  final UserSearchResult result;
  final VoidCallback onTap;

  const _UserSearchCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = result.name.isNotEmpty ? result.name[0].toUpperCase() : '?';
    final subtitle = [result.cityName, result.clubName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            result.avatarUrl != null ? NetworkImage(result.avatarUrl!) : null,
        child: result.avatarUrl == null ? Text(initials) : null,
      ),
      title: Text(result.name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
