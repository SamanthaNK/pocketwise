import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.debt import DebtDirection
from app.schemas.transaction import TransactionResponse


class DebtCreateRequest(BaseModel):
    person_name: str = Field(min_length=1, max_length=100)
    amount: Decimal = Field(gt=0)
    direction: DebtDirection
    due_date: date | None = None
    note: str | None = Field(default=None, max_length=255)


class DebtUpdateRequest(BaseModel):
    person_name: str | None = Field(default=None, min_length=1, max_length=100)
    amount: Decimal | None = Field(default=None, gt=0)
    direction: DebtDirection | None = None
    due_date: date | None = None
    clear_due_date: bool = False
    note: str | None = Field(default=None, max_length=255)
    clear_note: bool = False


class DebtSettleRequest(BaseModel):
    generate_transaction: bool = False
    category_id: int | None = None
    payment_method_id: int | None = None


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


class DebtSettleResponse(BaseModel):
    debt: DebtResponse
    generated_transaction: TransactionResponse | None = None


class DebtListResponse(BaseModel):
    debts: list[DebtResponse]
    total_owed_to_user: Decimal
    total_owed_by_user: Decimal
    count: int