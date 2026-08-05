from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.budget_repository import BudgetRepository
from app.repositories.category_repository import CategoryRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.budget import (
    BudgetCreateRequest,
    BudgetResponse,
    BudgetUpdateRequest,
    FiftyThirtyTwentySummaryResponse,
)
from app.services.budget_service import BudgetService


def _build_service(db: AsyncSession) -> BudgetService:
    return BudgetService(BudgetRepository(db), CategoryRepository(db), TransactionRepository(db))


async def create_budget(user_id: int, payload: BudgetCreateRequest, db: AsyncSession) -> list[BudgetResponse]:
    service = _build_service(db)
    created = await service.create_budget(user_id, payload)
    return [await service.to_response(user_id, budget) for budget in created]


async def update_budget(user_id: int, budget_id: int, payload: BudgetUpdateRequest, db: AsyncSession) -> BudgetResponse:
    service = _build_service(db)
    updated = await service.update_budget(user_id, budget_id, payload)
    return await service.to_response(user_id, updated)


async def delete_budget(user_id: int, budget_id: int, db: AsyncSession) -> None:
    await _build_service(db).delete_budget(user_id, budget_id)


async def list_budgets(user_id: int, db: AsyncSession) -> list[BudgetResponse]:
    return await _build_service(db).list_budgets(user_id)


async def get_fifty_thirty_twenty_summary(user_id: int, db: AsyncSession) -> FiftyThirtyTwentySummaryResponse:
    return await _build_service(db).get_fifty_thirty_twenty_summary(user_id)