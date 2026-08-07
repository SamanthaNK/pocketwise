from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.savings_contribution import SavingsContribution


class SavingsContributionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, contribution_id: int, user_id: int) -> SavingsContribution | None:
        stmt = select(SavingsContribution).where(
            SavingsContribution.id == contribution_id, SavingsContribution.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def sum_for_goal(self, goal_id: int) -> Decimal:
        stmt = select(func.coalesce(func.sum(SavingsContribution.amount), 0)).where(
            SavingsContribution.goal_id == goal_id
        )
        result = await self.db.execute(stmt)
        return Decimal(result.scalar() or 0)

    async def create(self, contribution: SavingsContribution) -> SavingsContribution:
        self.db.add(contribution)
        await self.db.commit()
        await self.db.refresh(contribution)
        return contribution

    async def delete(self, contribution: SavingsContribution) -> None:
        await self.db.delete(contribution)
        await self.db.commit()