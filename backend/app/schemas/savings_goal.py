import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class SavingsGoalCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    target_amount: Decimal = Field(gt=0)
    target_date: date | None = None


class SavingsGoalUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    target_amount: Decimal | None = Field(default=None, gt=0)
    target_date: date | None = None
    clear_target_date: bool = False


class SavingsGoalResponse(BaseModel):
    id: int
    name: str
    target_amount: Decimal
    target_date: date | None
    saved_amount: Decimal
    percent_complete: float
    is_reached: bool
    days_remaining: int | None
    client_generated_id: uuid.UUID
    updated_at: datetime


class SavingsContributionCreateRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    contribution_date: date


class SavingsContributionResponse(BaseModel):
    id: int
    goal_id: int
    amount: Decimal
    contribution_date: date
    client_generated_id: uuid.UUID
    created_at: datetime

    model_config = {"from_attributes": True}