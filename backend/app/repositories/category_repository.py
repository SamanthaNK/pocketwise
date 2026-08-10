from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category, CategoryType


class CategoryRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_for_user(
        self, user_id: int, include_archived: bool = False, type_filter: CategoryType | None = None
    ) -> list[Category]:
        stmt = select(Category).where(Category.user_id == user_id)
        if not include_archived:
            stmt = stmt.where(Category.is_archived.is_(False))
        if type_filter is not None:
            stmt = stmt.where(Category.type == type_filter)
        stmt = stmt.order_by(Category.type, Category.name)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, category_id: int, user_id: int) -> Category | None:
        stmt = select(Category).where(Category.id == category_id, Category.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_client_generated_id(self, client_generated_id, user_id: int) -> Category | None:
        stmt = select(Category).where(
            Category.client_generated_id == client_generated_id, Category.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_name(self, user_id: int, name: str) -> Category | None:
        stmt = select(Category).where(Category.user_id == user_id, Category.name == name)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, category: Category) -> Category:
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def save(self, category: Category) -> Category:
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def delete(self, category: Category) -> None:
        await self.db.delete(category)
        await self.db.commit()