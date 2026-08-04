from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category, CategoryType
from app.models.user import User
from app.repositories.category_repository import CategoryRepository
from app.schemas.category import CategoryCreateRequest, CategoryUpdateRequest
from app.services.category_service import CategoryService


async def list_categories(
    current_user: User, include_archived: bool, type_filter: CategoryType | None, db: AsyncSession
) -> list[Category]:
    service = CategoryService(CategoryRepository(db))
    return await service.list_categories(current_user.id, include_archived, type_filter)


async def create_category(current_user: User, payload: CategoryCreateRequest, db: AsyncSession) -> Category:
    service = CategoryService(CategoryRepository(db))
    return await service.create_category(current_user.id, payload)


async def update_category(
    current_user: User, category_id: int, payload: CategoryUpdateRequest, db: AsyncSession
) -> Category:
    service = CategoryService(CategoryRepository(db))
    return await service.update_category(current_user.id, category_id, payload)


async def archive_category(current_user: User, category_id: int, db: AsyncSession) -> Category:
    service = CategoryService(CategoryRepository(db))
    return await service.archive_category(current_user.id, category_id)


async def unarchive_category(current_user: User, category_id: int, db: AsyncSession) -> Category:
    service = CategoryService(CategoryRepository(db))
    return await service.unarchive_category(current_user.id, category_id)


async def delete_category(current_user: User, category_id: int, db: AsyncSession) -> None:
    service = CategoryService(CategoryRepository(db))
    await service.delete_category(current_user.id, category_id)