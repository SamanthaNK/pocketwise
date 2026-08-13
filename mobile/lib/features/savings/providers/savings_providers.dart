import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/feature_providers.dart';
import '../data/savings_contribution_local_repository.dart';
import '../data/savings_goal_local_repository.dart';
import '../models/savings_contribution_model.dart';
import '../models/savings_goal_model.dart';

final savingsGoalsProvider = FutureProvider.autoDispose<List<SavingsGoalModel>>((ref) {
  return ref.watch(savingsGoalLocalRepositoryProvider).getAll();
});

final goalContributionsProvider =
    FutureProvider.autoDispose.family<List<SavingsContributionModel>, String>((ref, goalId) {
  return ref.watch(savingsContributionLocalRepositoryProvider).getForGoal(goalId);
});

class SavingsGoalWriteController {
  SavingsGoalWriteController(this._goalRepo, this._contributionRepo, this._appDatabase);

  final SavingsGoalLocalRepository _goalRepo;
  final SavingsContributionLocalRepository _contributionRepo;
  final AppDatabase _appDatabase;

  Future<void> createGoal({required String name, required int targetAmount, DateTime? targetDate}) async {
    final goal = SavingsGoalModel(
      clientGeneratedId: const Uuid().v4(),
      serverId: null,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      savedAmount: 0,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _goalRepo.create(goal);
  }

  Future<void> updateGoal(SavingsGoalModel existing, {required String name, required int targetAmount, DateTime? targetDate}) async {
    final updated = SavingsGoalModel(
      clientGeneratedId: existing.clientGeneratedId,
      serverId: existing.serverId,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      savedAmount: existing.savedAmount,
      isDeleted: false,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _goalRepo.update(updated);
  }

  Future<void> deleteGoal(String clientGeneratedId) async {
    final db = await _appDatabase.instance;
    await db.update('savings_contributions', {'is_deleted': 1}, where: 'goal_id = ?', whereArgs: [clientGeneratedId]);
    await _goalRepo.softDelete(clientGeneratedId);
  }

  Future<String?> addContribution({
    required String goalClientId,
    required int amount,
    required String contributionType,
    required DateTime date,
  }) async {
    if (contributionType == 'withdrawal') {
      final currentSaved = await _contributionRepo.sumForGoal(goalClientId);
      if (amount > currentSaved) {
        return "You can only take out up to $currentSaved XAF — that's what's currently saved.";
      }
    }

    final contribution = SavingsContributionModel(
      clientGeneratedId: const Uuid().v4(),
      serverId: null,
      goalId: goalClientId,
      amount: amount,
      contributionType: contributionType,
      contributionDate: date,
      isDeleted: false,
      synced: false,
      createdAt: DateTime.now().toUtc(),
    );
    await _contributionRepo.create(contribution);

    final newSaved = await _contributionRepo.sumForGoal(goalClientId);
    await _goalRepo.recomputeSavedAmount(goalClientId, newSaved);
    return null;
  }

  Future<void> deleteContribution(String goalClientId, String contributionClientId) async {
    await _contributionRepo.softDelete(contributionClientId);
    final newSaved = await _contributionRepo.sumForGoal(goalClientId);
    await _goalRepo.recomputeSavedAmount(goalClientId, newSaved);
  }
}

final savingsGoalWriteControllerProvider = Provider((ref) {
  return SavingsGoalWriteController(
    ref.watch(savingsGoalLocalRepositoryProvider),
    ref.watch(savingsContributionLocalRepositoryProvider),
    ref.watch(appDatabaseProvider),
  );
});