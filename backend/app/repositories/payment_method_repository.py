from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment_method import PaymentMethod


class PaymentMethodRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_for_user(self, user_id: int, include_archived: bool = False) -> list[PaymentMethod]:
        stmt = select(PaymentMethod).where(PaymentMethod.user_id == user_id)
        if not include_archived:
            stmt = stmt.where(PaymentMethod.is_archived.is_(False))
        stmt = stmt.order_by(PaymentMethod.type, PaymentMethod.label)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, payment_method_id: int, user_id: int) -> PaymentMethod | None:
        stmt = select(PaymentMethod).where(
            PaymentMethod.id == payment_method_id, PaymentMethod.user_id == user_id
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, payment_method: PaymentMethod) -> PaymentMethod:
        self.db.add(payment_method)
        await self.db.commit()
        await self.db.refresh(payment_method)
        return payment_method

    async def save(self, payment_method: PaymentMethod) -> PaymentMethod:
        self.db.add(payment_method)
        await self.db.commit()
        await self.db.refresh(payment_method)
        return payment_method

    async def delete(self, payment_method: PaymentMethod) -> None:
        await self.db.delete(payment_method)
        await self.db.commit()

    async def has_transactions(self, payment_method_id: int) -> bool:
        from app.models.transaction import Transaction
        from sqlalchemy import exists

        stmt = select(exists().where(Transaction.payment_method_id == payment_method_id))
        result = await self.db.execute(stmt)
        return bool(result.scalar())