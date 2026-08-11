from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.savings_contribution_repository import SavingsContributionRepository
from app.repositories.savings_goal_repository import SavingsGoalRepository
from app.schemas.savings_goal import (
    SavingsContributionCreateRequest,
    SavingsContributionResponse,
    SavingsGoalCreateRequest,
    SavingsGoalResponse,
    SavingsGoalUpdateRequest,
)
from app.services.savings_goal_service import SavingsGoalService


def _build_service(db: AsyncSession) -> SavingsGoalService:
    return SavingsGoalService(SavingsGoalRepository(db), SavingsContributionRepository(db))


async def create_goal(user_id: int, payload: SavingsGoalCreateRequest, db: AsyncSession) -> SavingsGoalResponse:
    service = _build_service(db)
    goal = await service.create_goal(user_id, payload)
    return await service.to_response(goal)


async def update_goal(
    user_id: int, goal_id: int, payload: SavingsGoalUpdateRequest, db: AsyncSession
) -> SavingsGoalResponse:
    service = _build_service(db)
    goal = await service.update_goal(user_id, goal_id, payload)
    return await service.to_response(goal)


async def delete_goal(user_id: int, goal_id: int, db: AsyncSession) -> None:
    await _build_service(db).delete_goal(user_id, goal_id)


async def list_goals(user_id: int, db: AsyncSession) -> list[SavingsGoalResponse]:
    return await _build_service(db).list_goals(user_id)


async def get_goal(user_id: int, goal_id: int, db: AsyncSession) -> SavingsGoalResponse:
    return await _build_service(db).get_goal(user_id, goal_id)


async def add_contribution(
    user_id: int, goal_id: int, payload: SavingsContributionCreateRequest, db: AsyncSession
) -> SavingsContributionResponse:
    return await _build_service(db).add_contribution(user_id, goal_id, payload)


async def list_contributions(user_id: int, goal_id: int, db: AsyncSession) -> list[SavingsContributionResponse]:
    return await _build_service(db).list_contributions(user_id, goal_id)


async def delete_contribution(user_id: int, goal_id: int, contribution_id: int, db: AsyncSession) -> None:
    await _build_service(db).delete_contribution(user_id, goal_id, contribution_id)