from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import budget_controller
from app.core.database import get_db
from app.models.user import User
from app.schemas.budget import BudgetCreateRequest, BudgetResponse, BudgetUpdateRequest, FiftyThirtyTwentySummaryResponse

router = APIRouter(prefix="/budgets", tags=["Budgets"])


@router.get("", response_model=list[BudgetResponse])
async def list_budgets(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await budget_controller.list_budgets(current_user.id, db)


@router.get("/50-30-20-summary", response_model=FiftyThirtyTwentySummaryResponse)
async def get_fifty_thirty_twenty_summary(
    db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await budget_controller.get_fifty_thirty_twenty_summary(current_user.id, db)


@router.post("", response_model=list[BudgetResponse], status_code=201)
async def create_budget(
    payload: BudgetCreateRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await budget_controller.create_budget(current_user.id, payload, db)


@router.put("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    payload: BudgetUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await budget_controller.update_budget(current_user.id, budget_id, payload, db)


@router.delete("/{budget_id}", status_code=204)
async def delete_budget(
    budget_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    await budget_controller.delete_budget(current_user.id, budget_id, db)