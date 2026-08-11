import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from app.models.budget import BudgetPeriodType
from app.models.category import BudgetGroup, CategoryType
from app.models.debt import DebtDirection
from app.models.savings_contribution import SavingsContributionType
from app.schemas.budget import BudgetResponse
from app.schemas.category import CategoryResponse
from app.schemas.debt import DebtResponse
from app.schemas.payment_method import PaymentMethodResponse
from app.schemas.savings_goal import SavingsContributionResponse, SavingsGoalResponse
from app.schemas.transaction import TransactionResponse

SyncStatus = Literal["created", "updated", "conflict"]


# Transactions

class TransactionSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    category_id: int
    payment_method_id: int | None = None
    amount: Decimal = Field(gt=0)
    description: str | None = Field(default=None, max_length=255)
    transaction_date: date
    updated_at: datetime


class TransactionSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: SyncStatus
    transaction: TransactionResponse


# Categories

class CategorySyncItem(BaseModel):
    client_generated_id: uuid.UUID
    name: str = Field(min_length=1, max_length=100)
    type: CategoryType
    icon: str = Field(default="category", max_length=50)
    budget_group: BudgetGroup | None = None
    updated_at: datetime


class CategorySyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: SyncStatus
    category: CategoryResponse


# Payment methods — label edits only

class PaymentMethodSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    label: str = Field(min_length=1, max_length=100)
    updated_at: datetime


class PaymentMethodSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: Literal["updated", "conflict"]
    payment_method: PaymentMethodResponse


# Budgets — updates only (limit_amount / period_type)

class BudgetSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    limit_amount: Decimal = Field(gt=0)
    period_type: BudgetPeriodType
    updated_at: datetime


class BudgetSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: Literal["updated", "conflict"]
    budget: BudgetResponse


# Savings goals

class SavingsGoalSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    name: str = Field(min_length=1, max_length=100)
    target_amount: Decimal = Field(gt=0)
    target_date: date | None = None
    updated_at: datetime


class SavingsGoalSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: SyncStatus
    savings_goal: SavingsGoalResponse


# Savings contributions — create-only

class SavingsContributionSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    goal_id: int
    amount: Decimal = Field(gt=0)
    contribution_type: SavingsContributionType = SavingsContributionType.DEPOSIT
    contribution_date: date


class SavingsContributionSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: Literal["created", "already_synced"]
    savings_contribution: SavingsContributionResponse


# Debts

class DebtSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    person_name: str = Field(min_length=1, max_length=100)
    amount: Decimal = Field(gt=0)
    direction: DebtDirection
    due_date: date | None = None
    note: str | None = Field(default=None, max_length=255)
    updated_at: datetime


class DebtSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: SyncStatus
    debt: DebtResponse


# Batch request/response

class SyncBatchRequest(BaseModel):
    transactions: list[TransactionSyncItem] = Field(default_factory=list)
    categories: list[CategorySyncItem] = Field(default_factory=list)
    payment_methods: list[PaymentMethodSyncItem] = Field(default_factory=list)
    budgets: list[BudgetSyncItem] = Field(default_factory=list)
    savings_goals: list[SavingsGoalSyncItem] = Field(default_factory=list)
    savings_contributions: list[SavingsContributionSyncItem] = Field(default_factory=list)
    debts: list[DebtSyncItem] = Field(default_factory=list)


class SyncBatchResponse(BaseModel):
    transactions: list[TransactionSyncResult] = Field(default_factory=list)
    categories: list[CategorySyncResult] = Field(default_factory=list)
    payment_methods: list[PaymentMethodSyncResult] = Field(default_factory=list)
    budgets: list[BudgetSyncResult] = Field(default_factory=list)
    savings_goals: list[SavingsGoalSyncResult] = Field(default_factory=list)
    savings_contributions: list[SavingsContributionSyncResult] = Field(default_factory=list)
    debts: list[DebtSyncResult] = Field(default_factory=list)