from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import CurrencyUpdateRequest, PrivacyModeUpdateRequest, ProfileUpdateRequest
from app.services.user_service import UserService


async def update_privacy_mode(current_user: User, payload: PrivacyModeUpdateRequest, db: AsyncSession) -> User:
    service = UserService(UserRepository(db))
    return await service.set_privacy_mode(current_user, payload.enabled)


async def update_profile(current_user: User, payload: ProfileUpdateRequest, db: AsyncSession) -> User:
    service = UserService(UserRepository(db))
    return await service.update_profile(current_user, payload.name)


async def update_currency(current_user: User, payload: CurrencyUpdateRequest, db: AsyncSession) -> User:
    service = UserService(UserRepository(db))
    return await service.update_currency(current_user, payload.currency.value)