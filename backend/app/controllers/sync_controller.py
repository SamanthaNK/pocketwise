from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.budget_repository import BudgetRepository
from app.repositories.category_repository import CategoryRepository
from app.repositories.debt_repository import DebtRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.savings_contribution_repository import SavingsContributionRepository
from app.repositories.savings_goal_repository import SavingsGoalRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse
from app.services.sync_service import SyncService


def _build_service(db: AsyncSession) -> SyncService:
    return SyncService(
        TransactionRepository(db),
        CategoryRepository(db),
        PaymentMethodRepository(db),
        BudgetRepository(db),
        SavingsGoalRepository(db),
        SavingsContributionRepository(db),
        DebtRepository(db),
    )


async def sync_batch(user_id: int, payload: SyncBatchRequest, db: AsyncSession) -> SyncBatchResponse:
    return await _build_service(db).sync_batch(user_id, payload)