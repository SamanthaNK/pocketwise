from sqlalchemy.ext.asyncio import AsyncSession

from app.models.debt import DebtDirection
from app.repositories.debt_repository import DebtRepository
from app.schemas.debt import DebtCreateRequest, DebtListResponse, DebtResponse
from app.services.debt_service import DebtService


def _build_service(db: AsyncSession) -> DebtService:
    return DebtService(DebtRepository(db))


async def create_debt(user_id: int, payload: DebtCreateRequest, db: AsyncSession) -> DebtResponse:
    service = _build_service(db)
    debt = await service.create_debt(user_id, payload)
    return service.to_response(debt)


async def settle_debt(user_id: int, debt_id: int, db: AsyncSession) -> DebtResponse:
    service = _build_service(db)
    debt = await service.settle_debt(user_id, debt_id)
    return service.to_response(debt)


async def list_debts(
    user_id: int, direction: DebtDirection | None, is_settled: bool | None, db: AsyncSession
) -> DebtListResponse:
    return await _build_service(db).list_debts(user_id, direction, is_settled)