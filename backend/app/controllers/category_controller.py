from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category, CategoryType
from app.models.user import User
from app.repositories.category_repository import CategoryRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.category import CategoryCreateRequest, CategoryUpdateRequest
from app.services.category_service import CategoryService

def _build_service(db: AsyncSession) -> CategoryService:
    return CategoryService(CategoryRepository(db), TransactionRepository(db))

async def list_categories(
    current_user: User, include_archived: bool, type_filter: CategoryType | None, db: AsyncSession
) -> list[Category]:
    return await _build_service(db).list_categories(current_user.id, include_archived, type_filter)


async def create_category(current_user: User, payload: CategoryCreateRequest, db: AsyncSession) -> Category:
    return await _build_service(db).create_category(current_user.id, payload)


async def update_category(
    current_user: User, category_id: int, payload: CategoryUpdateRequest, db: AsyncSession
) -> Category:
    return await _build_service(db).update_category(current_user.id, category_id, payload)


async def archive_category(current_user: User, category_id: int, db: AsyncSession) -> Category:
    return await _build_service(db).archive_category(current_user.id, category_id)


async def unarchive_category(current_user: User, category_id: int, db: AsyncSession) -> Category:
    return await _build_service(db).unarchive_category(current_user.id, category_id)


async def delete_category(current_user: User, category_id: int, db: AsyncSession) -> None:
    await _build_service(db).delete_category(current_user.id, category_id)