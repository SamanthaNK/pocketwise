from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# Single async engine shared across the app's lifetime
engine = create_async_engine(settings.database_url, echo=(settings.environment == "development"))

# Session factory — each request gets its own session via the get_db dependency
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    """Base class every SQLAlchemy model inherits from."""
    pass


async def get_db():
    """FastAPI dependency that yields a request-scoped DB session."""
    async with AsyncSessionLocal() as session:
        yield session
