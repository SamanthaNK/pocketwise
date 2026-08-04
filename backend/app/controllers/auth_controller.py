from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RefreshRequest, RegisterRequest, TokenResponse
from app.services.auth_service import AuthService
from app.models.user import User
from app.schemas.auth import ChangePasswordRequest, MessageResponse


async def register_user(payload: RegisterRequest, db: AsyncSession) -> TokenResponse:
    service = AuthService(
        UserRepository(db),
        CategoryRepository(db),
        PaymentMethodRepository(db),
    )
    return await service.register(name=payload.name, email=payload.email, password=payload.password)


async def login_user(payload: LoginRequest, db: AsyncSession) -> TokenResponse:
    service = AuthService(UserRepository(db))
    return await service.login(email=payload.email, password=payload.password)


async def refresh_session(payload: RefreshRequest, db: AsyncSession) -> TokenResponse:
    service = AuthService(UserRepository(db))
    return await service.refresh(refresh_token=payload.refresh_token)

async def change_password(payload: ChangePasswordRequest, current_user: User, db: AsyncSession) -> MessageResponse:
    service = AuthService(UserRepository(db))
    await service.change_password(
        user=current_user,
        current_password=payload.current_password,
        new_password=payload.new_password,
    )
    return MessageResponse(message="Password updated. You're all set.")