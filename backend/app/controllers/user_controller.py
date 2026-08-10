from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import PrivacyModeUpdateRequest
from app.services.user_service import UserService


async def update_privacy_mode(current_user: User, payload: PrivacyModeUpdateRequest, db: AsyncSession) -> User:
    service = UserService(UserRepository(db))
    return await service.set_privacy_mode(current_user, payload.enabled)