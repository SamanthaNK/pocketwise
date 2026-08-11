from app.core.exceptions import AppException
from app.models.category import Category, CategoryType
from app.models.debt import Debt
from app.models.savings_contribution import SavingsContribution, SavingsContributionType
from app.models.savings_goal import SavingsGoal
from app.models.transaction import Transaction
from app.repositories.budget_repository import BudgetRepository
from app.repositories.category_repository import CategoryRepository
from app.repositories.debt_repository import DebtRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.savings_contribution_repository import SavingsContributionRepository
from app.repositories.savings_goal_repository import SavingsGoalRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.category import CategoryResponse
from app.schemas.payment_method import PaymentMethodResponse
from app.schemas.savings_goal import SavingsContributionResponse
from app.schemas.sync import (
    BudgetSyncItem,
    BudgetSyncResult,
    CategorySyncItem,
    CategorySyncResult,
    DebtSyncItem,
    DebtSyncResult,
    PaymentMethodSyncItem,
    PaymentMethodSyncResult,
    SavingsContributionSyncItem,
    SavingsContributionSyncResult,
    SavingsGoalSyncItem,
    SavingsGoalSyncResult,
    SyncBatchRequest,
    SyncBatchResponse,
    TransactionSyncItem,
    TransactionSyncResult,
)
from app.schemas.transaction import TransactionResponse
from app.services.budget_service import BudgetService
from app.services.debt_service import DebtService
from app.services.savings_goal_service import SavingsGoalService


class SyncService:
    def __init__(
        self,
        transaction_repository: TransactionRepository,
        category_repository: CategoryRepository,
        payment_method_repository: PaymentMethodRepository,
        budget_repository: BudgetRepository,
        savings_goal_repository: SavingsGoalRepository,
        savings_contribution_repository: SavingsContributionRepository,
        debt_repository: DebtRepository,
    ):
        self.transaction_repository = transaction_repository
        self.category_repository = category_repository
        self.payment_method_repository = payment_method_repository
        self.budget_repository = budget_repository
        self.savings_goal_repository = savings_goal_repository
        self.savings_contribution_repository = savings_contribution_repository
        self.debt_repository = debt_repository

        self._budget_service = BudgetService(budget_repository, category_repository, transaction_repository)
        self._savings_goal_service = SavingsGoalService(savings_goal_repository, savings_contribution_repository)
        self._debt_service = DebtService(debt_repository)

    async def sync_batch(self, user_id: int, payload: SyncBatchRequest) -> SyncBatchResponse:
        return SyncBatchResponse(
            transactions=[await self._sync_transaction(user_id, item) for item in payload.transactions],
            categories=[await self._sync_category(user_id, item) for item in payload.categories],
            payment_methods=[await self._sync_payment_method(user_id, item) for item in payload.payment_methods],
            budgets=[await self._sync_budget(user_id, item) for item in payload.budgets],
            savings_goals=[await self._sync_savings_goal(user_id, item) for item in payload.savings_goals],
            savings_contributions=[
                await self._sync_savings_contribution(user_id, item) for item in payload.savings_contributions
            ],
            debts=[await self._sync_debt(user_id, item) for item in payload.debts],
        )

    # Transactions

    async def _sync_transaction(self, user_id: int, item: TransactionSyncItem) -> TransactionSyncResult:
        category = await self.category_repository.get_by_id(item.category_id, user_id)
        if category is None:
            raise AppException(
                status_code=404,
                error_code="CATEGORY_NOT_FOUND",
                message=f"Category {item.category_id} referenced by an offline transaction wasn't found.",
            )

        if item.payment_method_id is not None:
            payment_method = await self.payment_method_repository.get_by_id(item.payment_method_id, user_id)
            if payment_method is None:
                raise AppException(
                    status_code=404,
                    error_code="PAYMENT_METHOD_NOT_FOUND",
                    message=f"Payment method {item.payment_method_id} referenced by an offline transaction wasn't found.",
                )

        existing = await self.transaction_repository.get_by_client_generated_id(item.client_generated_id, user_id)

        if existing is None:
            transaction = Transaction(
                user_id=user_id,
                category_id=item.category_id,
                payment_method_id=item.payment_method_id,
                type=category.type,
                amount=item.amount,
                description=item.description,
                transaction_date=item.transaction_date,
                client_generated_id=item.client_generated_id,
            )
            created = await self.transaction_repository.create(transaction)
            return TransactionSyncResult(
                client_generated_id=item.client_generated_id,
                status="created",
                transaction=TransactionResponse.model_validate(created),
            )

        if item.updated_at > existing.updated_at:
            existing.category_id = item.category_id
            existing.payment_method_id = item.payment_method_id
            existing.type = category.type
            existing.amount = item.amount
            existing.description = item.description
            existing.transaction_date = item.transaction_date
            saved = await self.transaction_repository.save(existing)
            return TransactionSyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                transaction=TransactionResponse.model_validate(saved),
            )

        return TransactionSyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            transaction=TransactionResponse.model_validate(existing),
        )

    # Categories

    async def _sync_category(self, user_id: int, item: CategorySyncItem) -> CategorySyncResult:
        if item.budget_group is not None and item.type == CategoryType.INCOME:
            raise AppException(
                status_code=422,
                error_code="VALIDATION_ERROR",
                message="Income categories can't belong to a 50/30/20 group.",
                field_errors={"budget_group": "Only expense categories can have a budget group."},
            )

        existing = await self.category_repository.get_by_client_generated_id(item.client_generated_id, user_id)

        if existing is None:
            name_taken = await self.category_repository.get_by_name(user_id, item.name)
            if name_taken is not None:
                raise AppException(
                    status_code=409,
                    error_code="CATEGORY_NAME_TAKEN",
                    message="You already have a category with this name.",
                    field_errors={"name": "This name is already in use."},
                )
            category = Category(
                user_id=user_id,
                name=item.name,
                type=item.type,
                icon=item.icon,
                budget_group=item.budget_group,
                is_default=False,
                client_generated_id=item.client_generated_id,
            )
            created = await self.category_repository.create(category)
            return CategorySyncResult(
                client_generated_id=item.client_generated_id,
                status="created",
                category=CategoryResponse.model_validate(created),
            )

        if item.updated_at > existing.updated_at:
            if item.name != existing.name:
                name_taken = await self.category_repository.get_by_name(user_id, item.name)
                if name_taken is not None and name_taken.id != existing.id:
                    raise AppException(
                        status_code=409,
                        error_code="CATEGORY_NAME_TAKEN",
                        message="You already have a category with this name.",
                        field_errors={"name": "This name is already in use."},
                    )
            existing.name = item.name
            existing.icon = item.icon
            existing.budget_group = item.budget_group
            saved = await self.category_repository.save(existing)
            return CategorySyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                category=CategoryResponse.model_validate(saved),
            )

        return CategorySyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            category=CategoryResponse.model_validate(existing),
        )

    # Payment methods (label edits only)

    async def _sync_payment_method(self, user_id: int, item: PaymentMethodSyncItem) -> PaymentMethodSyncResult:
        existing = await self.payment_method_repository.get_by_client_generated_id(item.client_generated_id, user_id)
        if existing is None:
            raise AppException(
                status_code=404,
                error_code="PAYMENT_METHOD_NOT_FOUND",
                message="This payment method doesn't exist on the server. Payment methods can't be created "
                "offline — only the four seeded defaults exist, and every account already has them.",
            )

        if item.updated_at > existing.updated_at:
            existing.label = item.label
            saved = await self.payment_method_repository.save(existing)
            return PaymentMethodSyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                payment_method=PaymentMethodResponse.model_validate(saved),
            )

        return PaymentMethodSyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            payment_method=PaymentMethodResponse.model_validate(existing),
        )

    # Budgets (update only)

    async def _sync_budget(self, user_id: int, item: BudgetSyncItem) -> BudgetSyncResult:
        existing = await self.budget_repository.get_by_client_generated_id(item.client_generated_id, user_id)
        if existing is None:
            raise AppException(
                status_code=404,
                error_code="BUDGET_NOT_FOUND",
                message="This budget doesn't exist on the server. New budgets can't be created offline — "
                "creating one has effects on other budgets (deactivating the previous mode) that need "
                "to happen online.",
            )

        if item.updated_at > existing.updated_at:
            existing.limit_amount = item.limit_amount
            existing.period_type = item.period_type
            saved = await self.budget_repository.save(existing)
            return BudgetSyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                budget=await self._budget_service.to_response(user_id, saved),
            )

        return BudgetSyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            budget=await self._budget_service.to_response(user_id, existing),
        )

    # Savings goals

    async def _sync_savings_goal(self, user_id: int, item: SavingsGoalSyncItem) -> SavingsGoalSyncResult:
        existing = await self.savings_goal_repository.get_by_client_generated_id(item.client_generated_id, user_id)

        if existing is None:
            goal = SavingsGoal(
                user_id=user_id,
                name=item.name,
                target_amount=item.target_amount,
                target_date=item.target_date,
                client_generated_id=item.client_generated_id,
            )
            created = await self.savings_goal_repository.create(goal)
            return SavingsGoalSyncResult(
                client_generated_id=item.client_generated_id,
                status="created",
                savings_goal=await self._savings_goal_service.to_response(created),
            )

        if item.updated_at > existing.updated_at:
            existing.name = item.name
            existing.target_amount = item.target_amount
            existing.target_date = item.target_date
            saved = await self.savings_goal_repository.save(existing)
            return SavingsGoalSyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                savings_goal=await self._savings_goal_service.to_response(saved),
            )

        return SavingsGoalSyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            savings_goal=await self._savings_goal_service.to_response(existing),
        )

    # Savings contributions (create-only, immutable)

    async def _sync_savings_contribution(
        self, user_id: int, item: SavingsContributionSyncItem
    ) -> SavingsContributionSyncResult:
        already = await self.savings_contribution_repository.get_by_client_generated_id(
            item.client_generated_id, user_id
        )
        if already is not None:
            return SavingsContributionSyncResult(
                client_generated_id=item.client_generated_id,
                status="already_synced",
                savings_contribution=SavingsContributionResponse.model_validate(already),
            )

        goal = await self.savings_goal_repository.get_by_id(item.goal_id, user_id)
        if goal is None:
            raise AppException(
                status_code=404,
                error_code="SAVINGS_GOAL_NOT_FOUND",
                message=f"Savings goal {item.goal_id} referenced by an offline contribution wasn't found.",
            )

        if item.contribution_type == SavingsContributionType.WITHDRAWAL:
            current_saved = await self.savings_contribution_repository.sum_for_goal(item.goal_id)
            if item.amount > current_saved:
                raise AppException(
                    status_code=409,
                    error_code="INSUFFICIENT_SAVED_AMOUNT",
                    message="An offline withdrawal exceeds what's actually saved toward this goal.",
                    field_errors={"amount": f"Only {current_saved} XAF is available to take out."},
                )

        contribution = SavingsContribution(
            goal_id=item.goal_id,
            user_id=user_id,
            amount=item.amount,
            contribution_type=item.contribution_type,
            contribution_date=item.contribution_date,
            client_generated_id=item.client_generated_id,
        )
        created = await self.savings_contribution_repository.create(contribution)
        return SavingsContributionSyncResult(
            client_generated_id=item.client_generated_id,
            status="created",
            savings_contribution=SavingsContributionResponse.model_validate(created),
        )

    # Debts

    async def _sync_debt(self, user_id: int, item: DebtSyncItem) -> DebtSyncResult:
        existing = await self.debt_repository.get_by_client_generated_id(item.client_generated_id, user_id)

        if existing is None:
            debt = Debt(
                user_id=user_id,
                person_name=item.person_name,
                amount=item.amount,
                direction=item.direction,
                due_date=item.due_date,
                note=item.note,
                client_generated_id=item.client_generated_id,
            )
            created = await self.debt_repository.create(debt)
            return DebtSyncResult(
                client_generated_id=item.client_generated_id,
                status="created",
                debt=self._debt_service.to_response(created),
            )

        if item.updated_at > existing.updated_at and not existing.is_settled:
            existing.person_name = item.person_name
            existing.amount = item.amount
            existing.direction = item.direction
            existing.due_date = item.due_date
            existing.note = item.note
            saved = await self.debt_repository.save(existing)
            return DebtSyncResult(
                client_generated_id=item.client_generated_id,
                status="updated",
                debt=self._debt_service.to_response(saved),
            )

        return DebtSyncResult(
            client_generated_id=item.client_generated_id,
            status="conflict",
            debt=self._debt_service.to_response(existing),
        )