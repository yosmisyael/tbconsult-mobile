import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:TBConsult/features/health_hub/data/data_sources/conversation_local_data_source.dart';
import 'package:TBConsult/features/health_hub/data/data_sources/triage_remote_data_source.dart';
import 'package:TBConsult/features/health_hub/data/data_sources/tb_knowledge_local_data_source.dart';
import 'package:TBConsult/features/health_hub/data/repositories/conversation_repository_impl.dart';
import 'package:TBConsult/features/health_hub/data/repositories/tb_knowledge_repository_impl.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/conversation_repository.dart';
import 'package:TBConsult/features/health_hub/domain/repositories/tb_knowledge_repository.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/get_conversations_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/get_conversation_detail_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/save_conversation_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/send_message_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/retrieve_tb_context_usecase.dart';
import 'package:TBConsult/features/health_hub/domain/usecases/generate_summary_usecase.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/health_hub_cubit.dart';
import 'package:TBConsult/features/health_hub/presentation/cubit/conversation_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── External dependencies ──────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPrefs);

  // ── Data sources ───────────────────────────────────────────────────────
  final tbKnowledgeDataSource = TBKnowledgeLocalDataSourceImpl();
  await tbKnowledgeDataSource.initialize();

  sl.registerLazySingleton<TBKnowledgeLocalDataSource>(
    () => tbKnowledgeDataSource,
  );

  sl.registerLazySingleton<ConversationLocalDataSource>(
    () => ConversationLocalDataSourceImpl(prefs: sl()),
  );

  sl.registerLazySingleton<TriageService>(
    () => TriageRemoteDataSource(
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      prefs: sl(),
    ),
  );

  // ── Repositories ───────────────────────────────────────────────────────
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<TBKnowledgeRepository>(
    () => TBKnowledgeRepositoryImpl(localDataSource: sl()),
  );

  // ── Use cases ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(
    () => GetConversationsUseCase(sl()),
  );

  sl.registerLazySingleton(
    () => GetConversationDetailUseCase(sl()),
  );

  sl.registerLazySingleton(
    () => SaveConversationUseCase(sl()),
  );

  sl.registerLazySingleton(
    () => RetrieveTBContextUseCase(sl()),
  );

  sl.registerLazySingleton(
    () => SendMessageUseCase(
      conversationRepository: sl(),
      knowledgeRepository: sl(),
      triageService: sl<TriageService>(),
    ),
  );

  sl.registerLazySingleton(
    () => GenerateSummaryUseCase(
      conversationRepository: sl(),
      triageService: sl<TriageService>(),
    ),
  );

  // ── Cubits (Factory — new instance per page) ───────────────────────────
  sl.registerFactory(
    () => HealthHubCubit(
      getConversations: sl(),
      conversationRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => ConversationCubit(
      sendMessageUseCase: sl(),
      saveConversationUseCase: sl(),
      getConversationDetailUseCase: sl(),
      generateSummaryUseCase: sl(),
    ),
  );
}
