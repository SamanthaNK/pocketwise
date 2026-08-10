import jwt

from app.core.exceptions import AppException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import TokenResponse
from app.services.category_service import CategoryService
from app.services.payment_method_service import PaymentMethodService
from app.models.user import User


class AuthService:
    def __init__(
        self,
        user_repository: UserRepository,
        category_repository: CategoryRepository | None = None,
        payment_method_repository: PaymentMethodRepository | None = None,
        transaction_repository: TransactionRepository | None = None,
    ):
        self.user_repository = user_repository
        self.category_service = (
            CategoryService(category_repository, transaction_repository)
            if category_repository is not None and transaction_repository is not None
            else None
        )
        self.payment_method_service = (
            PaymentMethodService(payment_method_repository, transaction_repository)
            if payment_method_repository is not None and transaction_repository is not None
            else None
        )

    async def register(self, name: str, email: str, password: str) -> TokenResponse:
        existing_user = await self.user_repository.get_by_email(email)
        if existing_user is not None:
            raise AppException(
                status_code=409,
                error_code="EMAIL_ALREADY_REGISTERED",
                message="An account with this email already exists.",
                field_errors={"email": "This email is already registered."},
            )

        hashed = hash_password(password)
        user = await self.user_repository.create(name=name, email=email, hashed_password=hashed)

        assert self.category_service and self.payment_method_service, (
            "AuthService.register() requires category_repository, payment_method_repository, "
            "and transaction_repository."
        )
        await self.category_service.seed_defaults(user.id)
        await self.payment_method_service.seed_defaults(user.id)

        return TokenResponse(
            access_token=create_access_token(subject=str(user.id)),
            refresh_token=create_refresh_token(subject=str(user.id)),
        )

    async def login(self, email: str, password: str) -> TokenResponse:
        user = await self.user_repository.get_by_email(email)

        if user is None or not verify_password(password, user.hashed_password):
            raise AppException(
                status_code=401,
                error_code="INVALID_CREDENTIALS",
                message="Incorrect email or password.",
            )

        return TokenResponse(
            access_token=create_access_token(subject=str(user.id)),
            refresh_token=create_refresh_token(subject=str(user.id)),
        )

    async def refresh(self, refresh_token: str) -> TokenResponse:
        try:
            payload = decode_token(refresh_token)
        except jwt.PyJWTError:
            raise AppException(
                status_code=401,
                error_code="INVALID_REFRESH_TOKEN",
                message="Your session has expired. Please log in again.",
            )

        if payload.get("type") != "refresh":
            raise AppException(
                status_code=401,
                error_code="INVALID_REFRESH_TOKEN",
                message="Your session has expired. Please log in again.",
            )

        subject = payload["sub"]
        return TokenResponse(
            access_token=create_access_token(subject=subject),
            refresh_token=create_refresh_token(subject=subject),
        )

    async def change_password(self, user: User, current_password: str, new_password: str) -> None:
        if not verify_password(current_password, user.hashed_password):
            raise AppException(
                status_code=401,
                error_code="INCORRECT_CURRENT_PASSWORD",
                message="Your current password doesn't match.",
                field_errors={"current_password": "This doesn't match your current password."},
            )

        hashed = hash_password(new_password)
        await self.user_repository.update_password(user, hashed)