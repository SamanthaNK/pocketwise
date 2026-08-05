from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, model_validator

from app.models.budget import BudgetPeriodType, BudgetRuleType
from app.models.category import BudgetGroup


class BudgetCreateRequest(BaseModel):
    rule_type: BudgetRuleType

    category_id: int | None = None
    limit_amount: Decimal | None = Field(default=None, gt=0)
    period_type: BudgetPeriodType | None = None

    declared_income: Decimal | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def fields_match_rule_type(self):
        if self.rule_type == BudgetRuleType.CUSTOM:
            if self.category_id is None or self.limit_amount is None or self.period_type is None:
                raise ValueError(
                    "Custom budgets require category_id, limit_amount, and period_type."
                )
            if self.declared_income is not None:
                raise ValueError("declared_income only applies to the fifty_thirty_twenty rule_type.")
        else:
            if self.declared_income is None:
                raise ValueError("fifty_thirty_twenty budgets require declared_income.")
            if self.category_id is not None or self.limit_amount is not None or self.period_type is not None:
                raise ValueError(
                    "category_id, limit_amount, and period_type don't apply to the "
                    "fifty_thirty_twenty rule_type — it's always monthly, and limits "
                    "are calculated automatically from declared_income."
                )
        return self


class BudgetUpdateRequest(BaseModel):
    limit_amount: Decimal | None = Field(default=None, gt=0)
    period_type: BudgetPeriodType | None = None


class BudgetResponse(BaseModel):
    id: int
    rule_type: BudgetRuleType
    period_type: BudgetPeriodType
    category_id: int | None
    budget_group: BudgetGroup | None
    limit_amount: Decimal
    declared_income: Decimal | None
    is_active: bool
    spent: Decimal
    remaining: Decimal
    percent_used: float
    updated_at: datetime


class FiftyThirtyTwentySummaryResponse(BaseModel):
    declared_income: Decimal
    groups: list[BudgetResponse]