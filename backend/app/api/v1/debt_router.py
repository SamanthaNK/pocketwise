from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import debt_controller
from app.core.database import get_db
from app.models.debt import DebtDirection
from app.models.user import User
from app.schemas.debt import DebtCreateRequest, DebtListResponse, DebtResponse

router = APIRouter(prefix="/debts", tags=["Debts"])


@router.get("", response_model=DebtListResponse)
async def list_debts(
    direction: DebtDirection | None = Query(default=None),
    is_settled: bool | None = Query(default=False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await debt_controller.list_debts(current_user.id, direction, is_settled, db)


@router.post("", response_model=DebtResponse, status_code=status.HTTP_201_CREATED)
async def create_debt(
    payload: DebtCreateRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)
):
    return await debt_controller.create_debt(current_user.id, payload, db)


@router.put("/{debt_id}/settle", response_model=DebtResponse)
async def settle_debt(debt_id: int, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await debt_controller.settle_debt(current_user.id, debt_id, db)