import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Numeric, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class SavingsContribution(Base):
    __tablename__ = "savings_contributions"
    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_savings_contribution_amount_positive"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    goal_id: Mapped[int] = mapped_column(ForeignKey("savings_goals.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    contribution_date: Mapped[date] = mapped_column(Date, nullable=False)

    client_generated_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=False, default=uuid.uuid4
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())