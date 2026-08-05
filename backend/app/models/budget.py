import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Numeric, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.category import BudgetGroup


class BudgetRuleType(str, enum.Enum):
    CUSTOM = "custom"
    FIFTY_THIRTY_TWENTY = "fifty_thirty_twenty"


class BudgetPeriodType(str, enum.Enum):
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class Budget(Base):
    __tablename__ = "budgets"
    __table_args__ = (
        CheckConstraint("limit_amount > 0", name="ck_budget_limit_positive"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    rule_type: Mapped[BudgetRuleType] = mapped_column(
        SAEnum(BudgetRuleType, name="budget_rule_type"), nullable=False
    )
    period_type: Mapped[BudgetPeriodType] = mapped_column(
        SAEnum(BudgetPeriodType, name="budget_period_type"), nullable=False
    )

    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="RESTRICT"), nullable=True, index=True
    )

    budget_group: Mapped[BudgetGroup | None] = mapped_column(
        SAEnum(BudgetGroup, name="budget_group", create_type=False), nullable=True
    )

    limit_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)

    declared_income: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)

    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    client_generated_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=False, default=uuid.uuid4
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )