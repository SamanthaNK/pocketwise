import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.debt import DebtDirection


class DebtCreateRequest(BaseModel):
    person_name: str = Field(min_length=1, max_length=100)
    amount: Decimal = Field(gt=0)
    direction: DebtDirection
    due_date: date | None = None
    note: str | None = Field(default=None, max_length=255)


class DebtResponse(BaseModel):
    id: int
    person_name: str
    amount: Decimal
    direction: DebtDirection
    due_date: date | None
    note: str | None
    is_settled: bool
    settled_at: datetime | None
    days_until_due: int | None
    client_generated_id: uuid.UUID
    updated_at: datetime


class DebtListResponse(BaseModel):
    debts: list[DebtResponse]
    total_owed_to_user: Decimal
    total_owed_by_user: Decimal
    count: int