import uuid
from decimal import Decimal

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.savings_contribution import SavingsContribution, SavingsContributionType


class SavingsContributionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, contribution_id: int, user_id: int) -> SavingsContribution | None:
        stmt = select(SavingsContribution).where(
            SavingsContribution.id == contribution_id, SavingsContribution.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_client_generated_id(
        self, client_generated_id: uuid.UUID, user_id: int
    ) -> SavingsContribution | None:
        stmt = select(SavingsContribution).where(
            SavingsContribution.client_generated_id == client_generated_id,
            SavingsContribution.user_id == user_id,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_for_goal(self, goal_id: int, user_id: int) -> list[SavingsContribution]:
        stmt = (
            select(SavingsContribution)
            .where(SavingsContribution.goal_id == goal_id, SavingsContribution.user_id == user_id)
            .order_by(SavingsContribution.contribution_date.desc(), SavingsContribution.created_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def sum_for_goal(self, goal_id: int) -> Decimal:
        """Net saved amount: deposits minus withdrawals — progress can now go
        down as well as up."""
        deposit_case = case(
            (SavingsContribution.contribution_type == SavingsContributionType.DEPOSIT, SavingsContribution.amount),
            else_=0,
        )
        withdrawal_case = case(
            (SavingsContribution.contribution_type == SavingsContributionType.WITHDRAWAL, SavingsContribution.amount),
            else_=0,
        )
        stmt = select(
            func.coalesce(func.sum(deposit_case), 0) - func.coalesce(func.sum(withdrawal_case), 0)
        ).where(SavingsContribution.goal_id == goal_id)
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