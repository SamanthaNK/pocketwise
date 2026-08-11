from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.budget import Budget, BudgetRuleType


class BudgetRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, budget_id: int, user_id: int) -> Budget | None:
        stmt = select(Budget).where(Budget.id == budget_id, Budget.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_active_for_user(self, user_id: int) -> list[Budget]:
        stmt = select(Budget).where(Budget.user_id == user_id, Budget.is_active.is_(True))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_active_by_rule_type(self, user_id: int, rule_type: BudgetRuleType) -> list[Budget]:
        stmt = select(Budget).where(
            Budget.user_id == user_id, Budget.is_active.is_(True), Budget.rule_type == rule_type
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_active_custom_budget_for_category(self, user_id: int, category_id: int) -> Budget | None:
        stmt = select(Budget).where(
            Budget.user_id == user_id,
            Budget.is_active.is_(True),
            Budget.rule_type == BudgetRuleType.CUSTOM,
            Budget.category_id == category_id,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def deactivate_all_active(self, user_id: int) -> None:
        stmt = (
            update(Budget)
            .where(Budget.user_id == user_id, Budget.is_active.is_(True))
            .values(is_active=False)
        )
        await self.db.execute(stmt)
        await self.db.commit()

    async def create(self, budget: Budget) -> Budget:
        self.db.add(budget)
        await self.db.commit()
        await self.db.refresh(budget)
        return budget

    async def create_many(self, budgets: list[Budget]) -> list[Budget]:
        self.db.add_all(budgets)
        await self.db.commit()
        for budget in budgets:
            await self.db.refresh(budget)
        return budgets

    async def save(self, budget: Budget) -> Budget:
        self.db.add(budget)
        await self.db.commit()
        await self.db.refresh(budget)
        return budget

    async def delete(self, budget: Budget) -> None:
        await self.db.delete(budget)
        await self.db.commit()
    async def get_by_client_generated_id(self, client_generated_id, user_id: int):
        stmt = select(Budget).where(Budget.client_generated_id == client_generated_id, Budget.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()