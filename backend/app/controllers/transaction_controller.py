from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction
from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionFilters, TransactionRepository
from app.schemas.transaction import TransactionCreateRequest, TransactionListResponse, TransactionUpdateRequest
from app.services.transaction_service import TransactionService


def _build_service(db: AsyncSession) -> TransactionService:
    return TransactionService(
        TransactionRepository(db), CategoryRepository(db), PaymentMethodRepository(db)
    )


async def create_transaction(user_id: int, payload: TransactionCreateRequest, db: AsyncSession) -> Transaction:
    return await _build_service(db).create_transaction(user_id, payload)


async def update_transaction(
    user_id: int, transaction_id: int, payload: TransactionUpdateRequest, db: AsyncSession
) -> Transaction:
    return await _build_service(db).update_transaction(user_id, transaction_id, payload)


async def delete_transaction(user_id: int, transaction_id: int, db: AsyncSession) -> None:
    await _build_service(db).delete_transaction(user_id, transaction_id)


async def get_transaction(user_id: int, transaction_id: int, db: AsyncSession) -> Transaction:
    return await _build_service(db).get_transaction(user_id, transaction_id)


async def list_transactions(user_id: int, filters: TransactionFilters, db: AsyncSession) -> TransactionListResponse:
    return await _build_service(db).list_transactions(user_id, filters)


async def export_transactions_csv(user_id: int, filters: TransactionFilters, db: AsyncSession) -> str:
    return await _build_service(db).export_csv(user_id, filters)