from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment_method import PaymentMethod
from app.models.user import User
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.payment_method import PaymentMethodUpdateRequest
from app.services.payment_method_service import PaymentMethodService

def _build_service(db: AsyncSession) -> PaymentMethodService:
    return PaymentMethodService(PaymentMethodRepository(db), TransactionRepository(db))

async def list_payment_methods(current_user: User, include_archived: bool, db: AsyncSession) -> list[PaymentMethod]:
    return await _build_service(db).list_payment_methods(current_user.id, include_archived)


async def update_payment_method(
    current_user: User, payment_method_id: int, payload: PaymentMethodUpdateRequest, db: AsyncSession
) -> PaymentMethod:
    return await _build_service(db).update_payment_method(current_user.id, payment_method_id, payload)


async def archive_payment_method(current_user: User, payment_method_id: int, db: AsyncSession) -> PaymentMethod:
    return await _build_service(db).archive_payment_method(current_user.id, payment_method_id)


async def unarchive_payment_method(current_user: User, payment_method_id: int, db: AsyncSession) -> PaymentMethod:
    return await _build_service(db).unarchive_payment_method(current_user.id, payment_method_id)