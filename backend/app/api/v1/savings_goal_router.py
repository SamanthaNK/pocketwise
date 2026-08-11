from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import savings_goal_controller
from app.core.database import get_db
from app.models.user import User
from app.schemas.savings_goal import (
    SavingsContributionCreateRequest,
    SavingsContributionResponse,
    SavingsGoalCreateRequest,
    SavingsGoalResponse,
    SavingsGoalUpdateRequest,
)

router = APIRouter(prefix="/goals", tags=["Savings Goals"])


@router.get("", response_model=list[SavingsGoalResponse])
async def list_goals(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await savings_goal_controller.list_goals(current_user.id, db)


@router.post("", response_model=SavingsGoalResponse, status_code=status.HTTP_201_CREATED)
async def create_goal(
    payload: SavingsGoalCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await savings_goal_controller.create_goal(current_user.id, payload, db)


@router.get("/{goal_id}", response_model=SavingsGoalResponse)
async def get_goal(goal_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await savings_goal_controller.get_goal(current_user.id, goal_id, db)


@router.put("/{goal_id}", response_model=SavingsGoalResponse)
async def update_goal(
    goal_id: int,
    payload: SavingsGoalUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await savings_goal_controller.update_goal(current_user.id, goal_id, payload, db)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(goal_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    await savings_goal_controller.delete_goal(current_user.id, goal_id, db)


@router.post(
    "/{goal_id}/contributions", response_model=SavingsContributionResponse, status_code=status.HTTP_201_CREATED
)
async def add_contribution(
    goal_id: int,
    payload: SavingsContributionCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await savings_goal_controller.add_contribution(current_user.id, goal_id, payload, db)


@router.get("/{goal_id}/contributions", response_model=list[SavingsContributionResponse])
async def list_contributions(
    goal_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await savings_goal_controller.list_contributions(current_user.id, goal_id, db)


@router.delete("/{goal_id}/contributions/{contribution_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contribution(
    goal_id: int,
    contribution_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await savings_goal_controller.delete_contribution(current_user.id, goal_id, contribution_id, db)