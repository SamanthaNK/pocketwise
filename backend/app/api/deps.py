import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import AppException
from app.core.security import decode_token
from app.models.user import User
from app.repositories.user_repository import UserRepository

bearer_scheme = HTTPBearer()

_INVALID_SESSION = "Invalid or expired session. Please log in again."


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:

    try:
        payload = decode_token(credentials.credentials)
    except jwt.PyJWTError:
        raise AppException(status_code=401, error_code="INVALID_SESSION", message=_INVALID_SESSION)

    if payload.get("type") != "access":
        raise AppException(status_code=401, error_code="INVALID_SESSION", message=_INVALID_SESSION)

    user = await UserRepository(db).get_by_id(int(payload["sub"]))
    if user is None:
        raise AppException(status_code=401, error_code="INVALID_SESSION", message=_INVALID_SESSION)

    return user