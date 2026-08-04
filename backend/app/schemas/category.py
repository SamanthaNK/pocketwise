import uuid
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

from app.models.category import BudgetGroup, CategoryType


class CategoryCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    type: CategoryType
    icon: str = Field(default="category", max_length=50)
    budget_group: BudgetGroup | None = None

    @model_validator(mode="after")
    def budget_group_only_for_expense(self):
        if self.type == CategoryType.INCOME and self.budget_group is not None:
            raise ValueError("budget_group only applies to expense categories.")
        return self


class CategoryUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    icon: str | None = Field(default=None, max_length=50)
    budget_group: BudgetGroup | None = None


class CategoryResponse(BaseModel):
    id: int
    name: str
    type: CategoryType
    icon: str
    budget_group: BudgetGroup | None
    is_default: bool
    is_archived: bool
    client_generated_id: uuid.UUID
    updated_at: datetime

    model_config = {"from_attributes": True}