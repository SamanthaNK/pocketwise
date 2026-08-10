from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import payment_method_controller
from app.core.database import get_db
from app.models.user import User
from app.schemas.payment_method import PaymentMethodResponse, PaymentMethodUpdateRequest

router = APIRouter(prefix="/payment-methods", tags=["Payment Methods"])


@router.get("", response_model=list[PaymentMethodResponse])
async def list_payment_methods(
    include_archived: bool = Query(default=False),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await payment_method_controller.list_payment_methods(current_user, include_archived, db)


@router.put("/{payment_method_id}", response_model=PaymentMethodResponse)
async def update_payment_method(
    payment_method_id: int,
    payload: PaymentMethodUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await payment_method_controller.update_payment_method(current_user, payment_method_id, payload, db)


@router.put("/{payment_method_id}/archive", response_model=PaymentMethodResponse)
async def archive_payment_method(
    payment_method_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await payment_method_controller.archive_payment_method(current_user, payment_method_id, db)


@router.put("/{payment_method_id}/unarchive", response_model=PaymentMethodResponse)
async def unarchive_payment_method(
    payment_method_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await payment_method_controller.unarchive_payment_method(current_user, payment_method_id, db)