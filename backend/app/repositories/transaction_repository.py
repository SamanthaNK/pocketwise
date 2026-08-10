import uuid
from dataclasses import dataclass
from datetime import date
from decimal import Decimal

from sqlalchemy import case, exists, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category, CategoryType
from app.models.payment_method import PaymentMethod
from app.models.transaction import Transaction
from app.schemas.transaction import SortBy, SortOrder


@dataclass
class TransactionFilters:

    start_date: date | None = None
    end_date: date | None = None
    category_id: int | None = None
    min_amount: Decimal | None = None
    max_amount: Decimal | None = None
    search: str | None = None
    sort_by: SortBy = "date"
    sort_order: SortOrder = "desc"
    limit: int = 100
    offset: int = 0


class TransactionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    def _apply_filters(self, stmt, user_id: int, filters: TransactionFilters):
        stmt = stmt.where(Transaction.user_id == user_id)
        if filters.start_date is not None:
            stmt = stmt.where(Transaction.transaction_date >= filters.start_date)
        if filters.end_date is not None:
            stmt = stmt.where(Transaction.transaction_date <= filters.end_date)
        if filters.category_id is not None:
            stmt = stmt.where(Transaction.category_id == filters.category_id)
        if filters.min_amount is not None:
            stmt = stmt.where(Transaction.amount >= filters.min_amount)
        if filters.max_amount is not None:
            stmt = stmt.where(Transaction.amount <= filters.max_amount)
        if filters.search:
            stmt = stmt.where(Transaction.description.ilike(f"%{filters.search}%"))
        return stmt

    async def list_for_user(self, user_id: int, filters: TransactionFilters) -> list[Transaction]:
        stmt = select(Transaction)
        stmt = self._apply_filters(stmt, user_id, filters)

        sort_column = Transaction.transaction_date if filters.sort_by == "date" else Transaction.amount
        stmt = stmt.order_by(sort_column.asc() if filters.sort_order == "asc" else sort_column.desc())

        stmt = stmt.offset(filters.offset).limit(filters.limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def sum_totals_for_user(self, user_id: int, filters: TransactionFilters) -> tuple[Decimal, Decimal]:
        """Income/expense totals over the FULL filtered set, ignoring limit/offset."""
        income_case = case((Transaction.type == CategoryType.INCOME, Transaction.amount), else_=0)
        expense_case = case((Transaction.type == CategoryType.EXPENSE, Transaction.amount), else_=0)

        stmt = select(
            func.coalesce(func.sum(income_case), 0),
            func.coalesce(func.sum(expense_case), 0),
        )
        stmt = self._apply_filters(stmt, user_id, filters)

        result = await self.db.execute(stmt)
        total_income, total_expense = result.one()
        return Decimal(total_income), Decimal(total_expense)

    async def get_by_id(self, transaction_id: int, user_id: int) -> Transaction | None:
        stmt = select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_client_generated_id(
        self, client_generated_id: uuid.UUID, user_id: int
    ) -> Transaction | None:
        stmt = select(Transaction).where(
            Transaction.client_generated_id == client_generated_id, Transaction.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, transaction: Transaction) -> Transaction:
        self.db.add(transaction)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def save(self, transaction: Transaction) -> Transaction:
        self.db.add(transaction)
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def delete(self, transaction: Transaction) -> None:
        await self.db.delete(transaction)
        await self.db.commit()

    async def has_transactions_for_category(self, category_id: int) -> bool:
        stmt = select(exists().where(Transaction.category_id == category_id))
        result = await self.db.execute(stmt)
        return bool(result.scalar())

    async def has_transactions_for_payment_method(self, payment_method_id: int) -> bool:
        stmt = select(exists().where(Transaction.payment_method_id == payment_method_id))
        result = await self.db.execute(stmt)
        return bool(result.scalar())

    async def sum_expense_for_category(
        self, user_id: int, category_id: int, start_date: date, end_date: date
    ) -> Decimal:
        stmt = select(func.coalesce(func.sum(Transaction.amount), 0)).where(
            Transaction.user_id == user_id,
            Transaction.category_id == category_id,
            Transaction.type == CategoryType.EXPENSE,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
        )
        result = await self.db.execute(stmt)
        return Decimal(result.scalar() or 0)

    async def sum_expense_for_budget_group(
        self, user_id: int, budget_group, start_date: date, end_date: date
    ) -> Decimal:
        stmt = (
            select(func.coalesce(func.sum(Transaction.amount), 0))
            .join(Category, Category.id == Transaction.category_id)
            .where(
                Transaction.user_id == user_id,
                Category.budget_group == budget_group,
                Transaction.type == CategoryType.EXPENSE,
                Transaction.transaction_date >= start_date,
                Transaction.transaction_date <= end_date,
            )
        )
        result = await self.db.execute(stmt)
        return Decimal(result.scalar() or 0)