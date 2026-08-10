import uuid
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.debt import Debt, DebtDirection


class DebtRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, debt_id: int, user_id: int) -> Debt | None:
        stmt = select(Debt).where(Debt.id == debt_id, Debt.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_client_generated_id(self, client_generated_id: uuid.UUID, user_id: int) -> Debt | None:
        stmt = select(Debt).where(Debt.client_generated_id == client_generated_id, Debt.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_for_user(
        self, user_id: int, direction: DebtDirection | None, is_settled: bool | None
    ) -> list[Debt]:
        stmt = select(Debt).where(Debt.user_id == user_id)
        if direction is not None:
            stmt = stmt.where(Debt.direction == direction)
        if is_settled is not None:
            stmt = stmt.where(Debt.is_settled == is_settled)
        stmt = stmt.order_by(Debt.due_date.is_(None), Debt.due_date.asc(), Debt.created_at.desc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def sum_unsettled_by_direction(self, user_id: int, direction: DebtDirection) -> Decimal:
        stmt = select(func.coalesce(func.sum(Debt.amount), 0)).where(
            Debt.user_id == user_id, Debt.direction == direction, Debt.is_settled.is_(False)
        )
        result = await self.db.execute(stmt)
        return Decimal(result.scalar() or 0)

    async def create(self, debt: Debt) -> Debt:
        self.db.add(debt)
        await self.db.commit()
        await self.db.refresh(debt)
        return debt

    async def save(self, debt: Debt) -> Debt:
        self.db.add(debt)
        await self.db.commit()
        await self.db.refresh(debt)
        return debt