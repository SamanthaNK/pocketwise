from datetime import date, timedelta
from decimal import Decimal

from app.core.exceptions import AppException
from app.models.budget import Budget, BudgetPeriodType, BudgetRuleType
from app.models.category import BudgetGroup, CategoryType
from app.repositories.budget_repository import BudgetRepository
from app.repositories.category_repository import CategoryRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.budget import (
    BudgetCreateRequest,
    BudgetResponse,
    BudgetUpdateRequest,
    FiftyThirtyTwentySummaryResponse,
)

NEEDS_PERCENT = Decimal("0.50")
WANTS_PERCENT = Decimal("0.30")
SAVINGS_PERCENT = Decimal("0.20")


class BudgetService:
    def __init__(
        self,
        budget_repository: BudgetRepository,
        category_repository: CategoryRepository,
        transaction_repository: TransactionRepository,
    ):
        self.budget_repository = budget_repository
        self.category_repository = category_repository
        self.transaction_repository = transaction_repository

    async def create_budget(self, user_id: int, payload: BudgetCreateRequest) -> list[Budget]:
        if payload.rule_type == BudgetRuleType.CUSTOM:
            return [await self._create_custom_budget(user_id, payload)]
        return await self._create_fifty_thirty_twenty_budgets(user_id, payload)

    async def _create_custom_budget(self, user_id: int, payload: BudgetCreateRequest) -> Budget:
        category = await self.category_repository.get_by_id(payload.category_id, user_id)
        if category is None:
            raise AppException(status_code=404, error_code="CATEGORY_NOT_FOUND", message="We couldn't find that category.")
        if category.is_archived:
            raise AppException(
                status_code=409, error_code="CATEGORY_ARCHIVED", message="This category is archived, so it can't be budgeted."
            )
        if category.type != CategoryType.EXPENSE:
            raise AppException(
                status_code=422,
                error_code="VALIDATION_ERROR",
                message="Only expense categories can have a budget.",
                field_errors={"category_id": "Income categories can't be budgeted."},
            )

        existing = await self.budget_repository.get_active_custom_budget_for_category(user_id, payload.category_id)
        if existing is not None:
            raise AppException(
                status_code=409,
                error_code="BUDGET_ALREADY_EXISTS",
                message="This category already has an active budget.",
            )

        active_fifty_thirty_twenty = await self.budget_repository.list_active_by_rule_type(
            user_id, BudgetRuleType.FIFTY_THIRTY_TWENTY
        )
        if active_fifty_thirty_twenty:
            await self.budget_repository.deactivate_all_active(user_id)

        budget = Budget(
            user_id=user_id,
            rule_type=BudgetRuleType.CUSTOM,
            period_type=payload.period_type,
            category_id=payload.category_id,
            budget_group=None,
            limit_amount=payload.limit_amount,
            declared_income=None,
        )
        return await self.budget_repository.create(budget)

    async def _create_fifty_thirty_twenty_budgets(self, user_id: int, payload: BudgetCreateRequest) -> list[Budget]:
        await self.budget_repository.deactivate_all_active(user_id)

        income = payload.declared_income
        group_allocations = [
            (BudgetGroup.NEEDS, income * NEEDS_PERCENT),
            (BudgetGroup.WANTS, income * WANTS_PERCENT),
            (BudgetGroup.SAVINGS, income * SAVINGS_PERCENT),
        ]

        new_budgets = [
            Budget(
                user_id=user_id,
                rule_type=BudgetRuleType.FIFTY_THIRTY_TWENTY,
                period_type=BudgetPeriodType.MONTHLY,
                category_id=None,
                budget_group=group,
                limit_amount=limit_amount,
                declared_income=income,
            )
            for group, limit_amount in group_allocations
        ]
        return await self.budget_repository.create_many(new_budgets)

    async def update_budget(self, user_id: int, budget_id: int, payload: BudgetUpdateRequest) -> Budget:
        budget = await self._get_owned_budget(user_id, budget_id)
        if payload.limit_amount is not None:
            budget.limit_amount = payload.limit_amount
        if payload.period_type is not None:
            budget.period_type = payload.period_type
        return await self.budget_repository.save(budget)

    async def delete_budget(self, user_id: int, budget_id: int) -> None:
        budget = await self._get_owned_budget(user_id, budget_id)
        await self.budget_repository.delete(budget)

    async def list_budgets(self, user_id: int) -> list[BudgetResponse]:
        budgets = await self.budget_repository.list_active_for_user(user_id)
        return [await self.to_response(user_id, budget) for budget in budgets]

    async def get_fifty_thirty_twenty_summary(self, user_id: int) -> FiftyThirtyTwentySummaryResponse:
        budgets = await self.budget_repository.list_active_by_rule_type(user_id, BudgetRuleType.FIFTY_THIRTY_TWENTY)
        if not budgets:
            raise AppException(
                status_code=404,
                error_code="FIFTY_THIRTY_TWENTY_NOT_CONFIGURED",
                message="You haven't set up a 50/30/20 budget yet.",
            )

        responses = [await self.to_response(user_id, budget) for budget in budgets]
        return FiftyThirtyTwentySummaryResponse(
            declared_income=budgets[0].declared_income, groups=responses
        )

    async def _get_owned_budget(self, user_id: int, budget_id: int) -> Budget:
        budget = await self.budget_repository.get_by_id(budget_id, user_id)
        if budget is None:
            raise AppException(status_code=404, error_code="BUDGET_NOT_FOUND", message="We couldn't find that budget.")
        return budget

    def _period_bounds(self, period_type: BudgetPeriodType) -> tuple[date, date]:
        today = date.today()
        if period_type == BudgetPeriodType.MONTHLY:
            return today.replace(day=1), today
        start = today - timedelta(days=today.weekday())
        return start, today

    async def to_response(self, user_id: int, budget: Budget) -> BudgetResponse:
        start_date, end_date = self._period_bounds(budget.period_type)

        if budget.category_id is not None:
            spent = await self.transaction_repository.sum_expense_for_category(
                user_id, budget.category_id, start_date, end_date
            )
        else:
            spent = await self.transaction_repository.sum_expense_for_budget_group(
                user_id, budget.budget_group, start_date, end_date
            )

        remaining = budget.limit_amount - spent
        percent_used = float(spent / budget.limit_amount * 100) if budget.limit_amount > 0 else 0.0

        return BudgetResponse(
            id=budget.id,
            rule_type=budget.rule_type,
            period_type=budget.period_type,
            category_id=budget.category_id,
            budget_group=budget.budget_group,
            limit_amount=budget.limit_amount,
            declared_income=budget.declared_income,
            is_active=budget.is_active,
            spent=spent,
            remaining=remaining,
            percent_used=round(percent_used, 1),
            updated_at=budget.updated_at,
        )