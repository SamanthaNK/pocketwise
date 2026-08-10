from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse
from app.services.sync_service import SyncService


def _build_service(db: AsyncSession) -> SyncService:
    return SyncService(
        TransactionRepository(db), CategoryRepository(db), PaymentMethodRepository(db)
    )


async def sync_batch(user_id: int, payload: SyncBatchRequest, db: AsyncSession) -> SyncBatchResponse:
    return await _build_service(db).sync_batch(user_id, payload)