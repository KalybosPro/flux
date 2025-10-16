// **************************************************************************
// Flugx GetX API Generator - Pagination Support
// **************************************************************************

import 'package:http/http.dart' as http;

/// Types de pagination supportés
enum PaginationType {
  offset,      // offset + limit
  cursor,      // cursor-based
  page,        // page + size
  linkHeader,  // RFC 5988 Link header
  custom,      // Custom implementation
}

/// Configuration de pagination
class PaginationConfig {
  final PaginationType type;
  final bool autoLoad;
  final bool enableInfiniteScroll;
  final int? defaultPageSize;
  final int? maxPageSize;
  final bool persistScrollPosition;
  final Duration throttleDuration;
  final String? nextParam;
  final String? previousParam;
  final String? countParam;
  final String? limitParam;

  const PaginationConfig({
    this.type = PaginationType.offset,
    this.autoLoad = true,
    this.enableInfiniteScroll = false,
    this.defaultPageSize = 20,
    this.maxPageSize = 100,
    this.persistScrollPosition = false,
    this.throttleDuration = const Duration(milliseconds: 300),
    this.nextParam = 'next',
    this.previousParam = 'previous',
    this.countParam = 'count',
    this.limitParam = 'limit',
  });
}

/// État de pagination
class PaginationState {
  final int currentPage;
  final int? totalPages;
  final int? totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? nextCursor;
  final String? previousCursor;
  final String? nextUrl;
  final String? previousUrl;
  final bool isLoading;
  final bool isLastPage;

  const PaginationState({
    this.currentPage = 1,
    this.totalPages,
    this.totalItems,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.nextCursor,
    this.previousCursor,
    this.nextUrl,
    this.previousUrl,
    this.isLoading = false,
    this.isLastPage = false,
  });

  /// Crée un état initial
  factory PaginationState.initial({int startPage = 1}) {
    return PaginationState(currentPage: startPage);
  }

  /// Met à jour l'état avec de nouvelles données
  PaginationState copyWith({
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? nextCursor,
    String? previousCursor,
    String? nextUrl,
    String? previousUrl,
    bool? isLoading,
    bool? isLastPage,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      nextCursor: nextCursor ?? this.nextCursor,
      previousCursor: previousCursor ?? this.previousCursor,
      nextUrl: nextUrl ?? this.nextUrl,
      previousUrl: previousUrl ?? this.previousUrl,
      isLoading: isLoading ?? this.isLoading,
      isLastPage: isLastPage ?? this.isLastPage,
    );
  }

  /// Analyse les headers de réponse pour extraire l'état de pagination
  factory PaginationState.fromResponse(http.Response response, PaginationType type) {
    final headers = response.headers;
    final queryParams = Uri.parse(response.request!.url.toString()).queryParameters;

    switch (type) {
      case PaginationType.linkHeader:
        return _parseLinkHeader(headers['link']);

      case PaginationType.offset:
        return _parseOffsetPagination(queryParams, headers);

      case PaginationType.page:
        return _parsePagePagination(queryParams, headers);

      case PaginationType.cursor:
        return _parseCursorPagination(headers);

      case PaginationType.custom:
        // Implementation spécifique à l'API
        return PaginationState();
    }
  }

  static PaginationState _parseLinkHeader(String? linkHeader) {
    if (linkHeader == null) return PaginationState();

    final links = _parseLinkHeaderValues(linkHeader);
    return PaginationState(
      nextUrl: links['next'],
      previousUrl: links['previous'],
      hasNextPage: links.containsKey('next'),
      hasPreviousPage: links.containsKey('previous'),
    );
  }

  static PaginationState _parseOffsetPagination(Map<String, String> queryParams, Map<String, String>? headers) {
    final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;
    final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
    final currentPage = (offset ~/ limit) + 1;

    final total = headers?['x-total-count'] != null
        ? int.tryParse(headers!['x-total-count']!)
        : null;

    return PaginationState(
      currentPage: currentPage,
      totalItems: total,
      hasNextPage: total != null ? (offset + limit) < total : true,
      hasPreviousPage: currentPage > 1,
    );
  }

  static PaginationState _parsePagePagination(Map<String, String> queryParams, Map<String, String>? headers) {
    final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
    final size = int.tryParse(queryParams['size'] ?? '20') ?? 20;

    final total = headers?['x-total-count'] != null
        ? int.tryParse(headers!['x-total-count']!)
        : null;

    final totalPages = total != null ? (total / size).ceil() : null;

    return PaginationState(
      currentPage: page,
      totalPages: totalPages,
      totalItems: total,
      hasNextPage: totalPages != null ? page < totalPages : true,
      hasPreviousPage: page > 1,
    );
  }

  static PaginationState _parseCursorPagination(Map<String, String>? headers) {
    return PaginationState(
      nextCursor: headers?['x-next-cursor'],
      previousCursor: headers?['x-previous-cursor'],
      hasNextPage: headers?.containsKey('x-next-cursor') == true,
      hasPreviousPage: headers?.containsKey('x-previous-cursor') == true,
    );
  }

  static Map<String, String> _parseLinkHeaderValues(String linkHeader) {
    final links = <String, String>{};
    final linkPattern = RegExp(r'<([^>]+)>;\s*rel="([^"]+)"');

    for (final match in linkPattern.allMatches(linkHeader)) {
      final url = match.group(1);
      final rel = match.group(2);
      if (url != null && rel != null) {
        links[rel] = url;
      }
    }

    return links;
  }
}

/// Gestionnaire de pagination générique
class PaginationManager<T> {
  final PaginationConfig config;
  final Future<List<T>> Function(int page, int size, {Map<String, dynamic>? params}) fetchPage;

  PaginationState _state;
  final List<T> _items = [];
  Timer? _throttleTimer;

  PaginationManager({
    required this.config,
    required this.fetchPage,
    PaginationState? initialState,
  }) : _state = initialState ?? PaginationState.initial();

  PaginationState get state => _state;
  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _state.isLoading;

  /// Charge la page suivante
  Future<void> loadNextPage() async {
    if (_state.isLoading || _state.isLastPage || !_state.hasNextPage) {
      return;
    }

    await _loadPage(_state.currentPage + 1);
  }

  /// Charge la page précédente
  Future<void> loadPreviousPage() async {
    if (_state.isLoading || _state.currentPage <= 1) {
      return;
    }

    await _loadPage(_state.currentPage - 1);
  }

  /// Recharge la page courante
  Future<void> refresh() async {
    await _loadPage(_state.currentPage, refresh: true);
  }

  /// Charge une page spécifique
  Future<void> loadPage(int page) async {
    if (page < 1) return;
    await _loadPage(page);
  }

  /// Ajoute un élément manuellement (pour les listes modifiables)
  void addItem(T item) {
    _items.add(item);
    // Notifier les listeners si nécessaire
  }

  /// Supprime un élément
  void removeItem(T item) {
    _items.remove(item);
  }

  /// Vide tous les éléments
  void clear() {
    _items.clear();
    _state = PaginationState.initial();
  }

  Future<void> _loadPage(int page, {bool refresh = false}) async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true);

    try {
      final newItems = await fetchPage(
        page,
        config.defaultPageSize ?? 20,
        params: _buildPaginationParams(page),
      );

      if (refresh) {
        _items.clear();
      }

      _items.addAll(newItems);

      _state = _state.copyWith(
        currentPage: page,
        isLoading: false,
        isLastPage: newItems.length < (config.defaultPageSize ?? 20),
      );

    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Map<String, dynamic> _buildPaginationParams(int page) {
    switch (config.type) {
      case PaginationType.offset:
        return {
          'offset': (page - 1) * (config.defaultPageSize ?? 20),
          'limit': config.defaultPageSize,
        };

      case PaginationType.page:
        return {
          'page': page,
          'size': config.defaultPageSize,
        };

      case PaginationType.cursor:
        // Implement cursor logic here
        return {};

      case PaginationType.linkHeader:
      case PaginationType.custom:
        return {'page': page};
    }
  }

  /// Obtient des métadonnées sur la pagination
  Map<String, dynamic> getMetadata() {
    return {
      'current_page': _state.currentPage,
      'total_items': _items.length,
      'has_next_page': _state.hasNextPage,
      'has_previous_page': _state.hasPreviousPage,
      'is_loading': _state.isLoading,
      'is_last_page': _state.isLastPage,
      'total_pages': _state.totalPages,
    };
  }

  /// Méthode utilitaire pour vérifier si on peut charger davantage
  bool canLoadMore() {
    return !_state.isLoading &&
           !_state.isLastPage &&
           _state.hasNextPage &&
           (!config.enableInfiniteScroll || _items.isNotEmpty);
  }

  /// Libère les ressources
  void dispose() {
    _throttleTimer?.cancel();
    clear();
  }
}

/// Classe pour gérer le scroll infini avec pagination
class InfiniteScrollController {
  final PaginationManager paginationManager;
  final VoidCallback onLoadMore;
  final double threshold;

  InfiniteScrollController({
    required this.paginationManager,
    required this.onLoadMore,
    this.threshold = 0.8, // 80% de la hauteur
  });

  /// Appelé quand la position de scroll change
  void onScroll(double scrollPosition, double maxScrollExtent, double viewportHeight) {
    if (maxScrollExtent <= 0) return;

    final scrollPercentage = scrollPosition / maxScrollExtent;

    if (scrollPercentage >= threshold && paginationManager.canLoadMore()) {
      onLoadMore();
    }
  }
}

// Typdefs pour les callbacks (à définir dans l'implémentation Flutter)
typedef Timer = dynamic;
typedef VoidCallback = void Function();
