import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from app.models.category import CategoryType


class TransactionCreateRequest(BaseModel):
    category_id: int
    payment_method_id: int | None = None
    amount: Decimal = Field(gt=0)
    description: str | None = Field(default=None, max_length=255)
    transaction_date: date


class TransactionUpdateRequest(BaseModel):
    category_id: int | None = None
    payment_method_id: int | None = None
    amount: Decimal | None = Field(default=None, gt=0)
    description: str | None = Field(default=None, max_length=255)
    transaction_date: date | None = None
    clear_payment_method: bool = False


class TransactionResponse(BaseModel):
    id: int
    category_id: int
    payment_method_id: int | None
    type: CategoryType
    amount: Decimal
    description: str | None
    transaction_date: date
    client_generated_id: uuid.UUID
    updated_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    transactions: list[TransactionResponse]
    total_income: Decimal
    total_expense: Decimal
    net: Decimal
    count: int


SortBy = Literal["date", "amount"]
SortOrder = Literal["asc", "desc"]