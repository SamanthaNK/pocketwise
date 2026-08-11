from app.models.user import User
from app.repositories.user_repository import UserRepository


class UserService:
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository

    async def set_privacy_mode(self, user: User, enabled: bool) -> User:
        return await self.user_repository.update_privacy_mode(user, enabled)

    async def update_profile(self, user: User, name: str) -> User:
        return await self.user_repository.update_profile(user, name)

    async def update_currency(self, user: User, currency: str) -> User:
        return await self.user_repository.update_currency(user, currency)