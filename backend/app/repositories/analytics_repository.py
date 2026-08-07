from datetime import date
from decimal import Decimal

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category, CategoryType
from app.models.transaction import Transaction


class AnalyticsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def totals_for_range(self, user_id: int, start_date: date, end_date: date) -> tuple[Decimal, Decimal]:
        income_case = case((Transaction.type == CategoryType.INCOME, Transaction.amount), else_=0)
        expense_case = case((Transaction.type == CategoryType.EXPENSE, Transaction.amount), else_=0)

        stmt = select(
            func.coalesce(func.sum(income_case), 0),
            func.coalesce(func.sum(expense_case), 0),
        ).where(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
        )
        result = await self.db.execute(stmt)
        total_income, total_expense = result.one()
        return Decimal(total_income), Decimal(total_expense)

    async def expense_breakdown_by_category(
        self, user_id: int, start_date: date, end_date: date
    ) -> list[tuple[int, str, str, Decimal]]:
        stmt = (
            select(Category.id, Category.name, Category.icon, func.sum(Transaction.amount))
            .join(Transaction, Transaction.category_id == Category.id)
            .where(
                Transaction.user_id == user_id,
                Transaction.type == CategoryType.EXPENSE,
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date,
            )
            .group_by(Category.id, Category.name, Category.icon)
            .order_by(func.sum(Transaction.amount).desc())
        )
        result = await self.db.execute(stmt)
        return [(row[0], row[1], row[2], Decimal(row[3])) for row in result.all()]