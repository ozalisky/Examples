import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:nda/database/database.dart';
import 'package:nda/domain/api/api.dart';
import 'package:nda/domain/beans/beans.dart';
import 'package:nda/domain/services/services.dart';
import 'package:nda/domain/sip/sip.dart';
import 'package:nda/mixins/mixins.dart';

part 'quick_messages_state.dart';

class QuickMessagesCubit extends Cubit<QuickMessagesState>
    with ChangeNotificationBlocMixin, SearchableCubitMixin, DebounceCubitMixin {
  QuickMessagesCubit() : super(const QuickMessagesState.initial()) {
    subscribeChangeNotifications();
  }

  /// Loads the Quick Messages list from Database/API.
  Future<void> load() async {
    emit(state.copyWith(status: StateStatus.request));

    final quickMessages = await DataResolver.fetch<List<QuickMessageEntity>>(
      cacheLoader: ChatRepository.getAllQuickMessages,
      dataLoader: MessagesAPI.getQuickMessages,
      cacheUpdater: (remoteData) async {
        await ChatRepository.upsertQuickMessages(remoteData);

        return ChatRepository.getAllQuickMessages();
      },
    );

    emit(
      state.copyWith(
        status: StateStatus.request,
        searchResult: quickMessages,
      ),
    );
  }

  /// Adds new Quick Message to DB and post it to the Web API.
  ///
  /// Throw [DioError] exception, handle it on UI.
  Future<bool> addNew(String message) async {
    final trimmedQm = message.trim();

    final quickMessagesList = await ChatRepository.getAllQuickMessages(
      search: trimmedQm,
    );

    for (final quickMessage in quickMessagesList) {
      if (quickMessage.message == trimmedQm) {
        return false;
      }
    }

    try {
      final quickMessage = await MessagesAPI.addQuickMessage(
        AddQuickMessageRequest(
          message: trimmedQm,
          category: 'main',
        ),
      );

      await ChatRepository.upsertQuickMessage(
        QuickMessageEntity(
          uuid: quickMessage.uuid,
          message: quickMessage.message,
          category: quickMessage.category,
          id: quickMessage.id,
        ),
      );

      return true;
    } catch (e, st) {
      AppLog.info(
        'Quick message could not be added.',
        exception: e,
        stackTrace: st,
      );
      return false;
    } finally {
      await load();
    }
  }

  Future<void> editMessage(
    QuickMessageEntity quickMessage,
    String newMessage,
  ) async {
    try {
      await MessagesAPI.deleteQuickMessage(quickMessage.uuid);

      await ChatRepository.deleteQuickMessage(quickMessage);

      final newQuickMessage = await MessagesAPI.addQuickMessage(
        AddQuickMessageRequest(
          message: newMessage,
          category: 'main',
        ),
      );

      await ChatRepository.upsertQuickMessage(
        QuickMessageEntity(
          uuid: newQuickMessage.uuid,
          message: newQuickMessage.message,
          category: newQuickMessage.category,
          id: newQuickMessage.id,
        ),
      );
    } catch (e, st) {
      AppLog.info(
        'Quick message could not be updated.',
        exception: e,
        stackTrace: st,
      );
    } finally {
      await load();
    }
  }

  Future<void> deleteMessage(QuickMessageEntity quickMessage) async {
    try {
      await MessagesAPI.deleteQuickMessage(quickMessage.uuid);

      await ChatRepository.deleteQuickMessage(quickMessage);
    } catch (e, st) {
      AppLog.info(
        'Quick message could not be deleted.',
        exception: e,
        stackTrace: st,
      );
    } finally {
      await load();
    }
  }

  void _handleSearch(String searchTerm) async {
    final quickMessages = await ChatRepository.getAllQuickMessages(
      search: searchTerm,
    );

    emit(
      state.copyWith(
        status: StateStatus.success,
        searchTerm: searchTerm,
        searchResult: quickMessages,
      ),
    );
  }

  @override
  void onQuickMessages(CNEventQuickMessages cn) async {
    await load();
  }

  @override
  void refreshFilters() {
    emit(
      state.copyWith(
        status: StateStatus.request,
        searchTerm: '',
      ),
    );

    _handleSearch(state.searchTerm);
  }

  @override
  void onChange(Change<QuickMessagesState> change) {
    super.onChange(change);

    if (change.currentState.searchTerm != change.nextState.searchTerm) {
      _handleSearch(change.nextState.searchTerm);
    }
  }

  @override
  Future<void> search(String searchTerm) async {
    emitDebounce(state.copyWith(searchTerm: searchTerm));
  }
}
