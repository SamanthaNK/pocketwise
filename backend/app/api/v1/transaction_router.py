from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import transaction_controller
from app.core.database import get_db
from app.models.user import User
from app.repositories.transaction_repository import TransactionFilters
from app.schemas.transaction import (
    SortBy,
    SortOrder,
    TransactionCreateRequest,
    TransactionListResponse,
    TransactionResponse,
    TransactionUpdateRequest,
)

router = APIRouter(prefix="/transactions", tags=["Transactions"])


def _build_filters(
    start_date, end_date, category_id, min_amount, max_amount, search, sort_by, sort_order, limit, offset
) -> TransactionFilters:
    return TransactionFilters(
        start_date=start_date, end_date=end_date, category_id=category_id,
        min_amount=min_amount, max_amount=max_amount, search=search,
        sort_by=sort_by, sort_order=sort_order, limit=limit, offset=offset,
    )


@router.get("", response_model=TransactionListResponse)
async def list_transactions(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    category_id: int | None = Query(default=None),
    min_amount: Decimal | None = Query(default=None, gt=0),
    max_amount: Decimal | None = Query(default=None, gt=0),
    search: str | None = Query(default=None, max_length=255),
    sort_by: SortBy = Query(default="date"),
    sort_order: SortOrder = Query(default="desc"),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    filters = _build_filters(
        start_date, end_date, category_id, min_amount, max_amount, search, sort_by, sort_order, limit, offset
    )
    return await transaction_controller.list_transactions(current_user.id, filters, db)


@router.get("/export/csv")
async def export_transactions_csv(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    category_id: int | None = Query(default=None),
    min_amount: Decimal | None = Query(default=None, gt=0),
    max_amount: Decimal | None = Query(default=None, gt=0),
    search: str | None = Query(default=None, max_length=255),
    sort_by: SortBy = Query(default="date"),
    sort_order: SortOrder = Query(default="desc"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """FR 4.8 (Could): CSV export, same filters as the regular list.
    PNG/PDF export are deferred to a later pass."""
    filters = _build_filters(
        start_date, end_date, category_id, min_amount, max_amount, search, sort_by, sort_order, limit=1, offset=0
    )
    csv_text = await transaction_controller.export_transactions_csv(current_user.id, filters, db)
    return Response(
        content=csv_text,
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=pocketwise_transactions.csv"},
    )


@router.post("", response_model=TransactionResponse, status_code=201)
async def create_transaction(
    payload: TransactionCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await transaction_controller.create_transaction(current_user.id, payload, db)


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await transaction_controller.get_transaction(current_user.id, transaction_id, db)


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    transaction_id: int,
    payload: TransactionUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await transaction_controller.update_transaction(current_user.id, transaction_id, payload, db)


@router.delete("/{transaction_id}", status_code=204)
async def delete_transaction(
    transaction_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await transaction_controller.delete_transaction(current_user.id, transaction_id, db)