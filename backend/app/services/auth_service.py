import jwt

from app.core.exceptions import AppException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.repositories.user_repository import UserRepository
from app.schemas.auth import TokenResponse
from app.models.user import User


class AuthService:
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository

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