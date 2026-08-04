from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment_method import PaymentMethod
from app.models.user import User
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.schemas.payment_method import PaymentMethodCreateRequest, PaymentMethodUpdateRequest
from app.services.payment_method_service import PaymentMethodService


async def list_payment_methods(current_user: User, include_archived: bool, db: AsyncSession) -> list[PaymentMethod]:
    service = PaymentMethodService(PaymentMethodRepository(db))
    return await service.list_payment_methods(current_user.id, include_archived)


async def create_payment_method(
    current_user: User, payload: PaymentMethodCreateRequest, db: AsyncSession
) -> PaymentMethod:
    service = PaymentMethodService(PaymentMethodRepository(db))
    return await service.create_payment_method(current_user.id, payload)


async def update_payment_method(
    current_user: User, payment_method_id: int, payload: PaymentMethodUpdateRequest, db: AsyncSession
) -> PaymentMethod:
    service = PaymentMethodService(PaymentMethodRepository(db))
    return await service.update_payment_method(current_user.id, payment_method_id, payload)


async def archive_payment_method(current_user: User, payment_method_id: int, db: AsyncSession) -> PaymentMethod:
    service = PaymentMethodService(PaymentMethodRepository(db))
    return await service.archive_payment_method(current_user.id, payment_method_id)


async def unarchive_payment_method(current_user: User, payment_method_id: int, db: AsyncSession) -> PaymentMethod:
    service = PaymentMethodService(PaymentMethodRepository(db))
    return await service.unarchive_payment_method(current_user.id, payment_method_id)


async def delete_payment_method(current_user: User, payment_method_id: int, db: AsyncSession) -> None:
    service = PaymentMethodService(PaymentMethodRepository(db))
    await service.delete_payment_method(current_user.id, payment_method_id)