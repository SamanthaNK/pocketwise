from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.savings_goal import SavingsGoal


class SavingsGoalRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, goal_id: int, user_id: int) -> SavingsGoal | None:
        stmt = select(SavingsGoal).where(SavingsGoal.id == goal_id, SavingsGoal.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_for_user(self, user_id: int) -> list[SavingsGoal]:
        stmt = (
            select(SavingsGoal)
            .where(SavingsGoal.user_id == user_id)
            .order_by(SavingsGoal.target_date.is_(None), SavingsGoal.target_date.asc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def create(self, goal: SavingsGoal) -> SavingsGoal:
        self.db.add(goal)
        await self.db.commit()
        await self.db.refresh(goal)
        return goal

    async def save(self, goal: SavingsGoal) -> SavingsGoal:
        self.db.add(goal)
        await self.db.commit()
        await self.db.refresh(goal)
        return goal

    async def delete(self, goal: SavingsGoal) -> None:
        await self.db.delete(goal)  # cascades to savings_contributions
        await self.db.commit()