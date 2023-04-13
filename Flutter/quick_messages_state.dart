part of 'quick_messages_cubit.dart';

class QuickMessagesState extends Equatable
    implements SearchableState<QuickMessageEntity> {
  const QuickMessagesState._({
    this.status = StateStatus.initial,
    this.searchTerm = '',
    this.searchResult = const <QuickMessageEntity>[],
  });

  const QuickMessagesState.initial() : this._();

  final StateStatus status;
  @override
  final String searchTerm;
  @override
  final List<QuickMessageEntity> searchResult;

  @override
  List<Object> get props => [
        status,
        searchTerm,
        searchResult,
      ];

  QuickMessagesState copyWith({
    StateStatus? status,
    String? searchTerm,
    List<QuickMessageEntity>? searchResult,
  }) {
    return QuickMessagesState._(
      status: status ?? this.status,
      searchTerm: searchTerm ?? this.searchTerm,
      searchResult: searchResult ?? this.searchResult,
    );
  }

  @override
  SearchableState<QuickMessageEntity> cleanSearchState() {
    return copyWith(
      status: StateStatus.initial,
      searchTerm: '',
      searchResult: [],
    );
  }
}
