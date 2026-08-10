from sqlalchemy.ext.asyncio import AsyncSession

from app.models.debt import DebtDirection
from app.repositories.category_repository import CategoryRepository
from app.repositories.debt_repository import DebtRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.debt import (
    DebtCreateRequest,
    DebtListResponse,
    DebtResponse,
    DebtSettleRequest,
    DebtSettleResponse,
    DebtUpdateRequest,
)
from app.services.debt_service import DebtService


def _build_service(db: AsyncSession) -> DebtService:
    return DebtService(
        DebtRepository(db), CategoryRepository(db), PaymentMethodRepository(db), TransactionRepository(db)
    )


async def create_debt(user_id: int, payload: DebtCreateRequest, db: AsyncSession) -> DebtResponse:
    service = _build_service(db)
    debt = await service.create_debt(user_id, payload)
    return service.to_response(debt)


async def update_debt(user_id: int, debt_id: int, payload: DebtUpdateRequest, db: AsyncSession) -> DebtResponse:
    service = _build_service(db)
    debt = await service.update_debt(user_id, debt_id, payload)
    return service.to_response(debt)


async def settle_debt(user_id: int, debt_id: int, payload: DebtSettleRequest, db: AsyncSession) -> DebtSettleResponse:
    service = _build_service(db)
    return await service.settle_debt(user_id, debt_id, payload)


async def list_debts(
    user_id: int, direction: DebtDirection | None, is_settled: bool | None, db: AsyncSession
) -> DebtListResponse:
    return await _build_service(db).list_debts(user_id, direction, is_settled)