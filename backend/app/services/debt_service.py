from datetime import date, datetime, timezone

from app.core.exceptions import AppException
from app.models.category import CategoryType
from app.models.debt import Debt, DebtDirection
from app.models.transaction import Transaction
from app.repositories.category_repository import CategoryRepository
from app.repositories.debt_repository import DebtRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.debt import (
    DebtCreateRequest,
    DebtListResponse,
    DebtResponse,
    DebtSettleRequest,
    DebtSettleResponse,
    DebtUpdateRequest,
)
from app.schemas.transaction import TransactionResponse


class DebtService:
    def __init__(
        self,
        debt_repository: DebtRepository,
        category_repository: CategoryRepository | None = None,
        payment_method_repository: PaymentMethodRepository | None = None,
        transaction_repository: TransactionRepository | None = None,
    ):
        self.debt_repository = debt_repository
        self.category_repository = category_repository
        self.payment_method_repository = payment_method_repository
        self.transaction_repository = transaction_repository

    async def create_debt(self, user_id: int, payload: DebtCreateRequest) -> Debt:
        debt = Debt(
            user_id=user_id,
            person_name=payload.person_name,
            amount=payload.amount,
            direction=payload.direction,
            due_date=payload.due_date,
            note=payload.note,
        )
        return await self.debt_repository.create(debt)

    async def update_debt(self, user_id: int, debt_id: int, payload: DebtUpdateRequest) -> Debt:
        debt = await self._get_owned_debt(user_id, debt_id)
        if debt.is_settled:
            raise AppException(
                status_code=409,
                error_code="DEBT_ALREADY_SETTLED",
                message="This debt is already settled, so its details can't be edited anymore.",
            )

        if payload.person_name is not None:
            debt.person_name = payload.person_name
        if payload.amount is not None:
            debt.amount = payload.amount
        if payload.direction is not None:
            debt.direction = payload.direction
        if payload.clear_due_date:
            debt.due_date = None
        elif payload.due_date is not None:
            debt.due_date = payload.due_date
        if payload.clear_note:
            debt.note = None
        elif payload.note is not None:
            debt.note = payload.note

        return await self.debt_repository.save(debt)

    async def settle_debt(self, user_id: int, debt_id: int, payload: DebtSettleRequest) -> DebtSettleResponse:
        debt = await self._get_owned_debt(user_id, debt_id)
        if debt.is_settled:
            raise AppException(
                status_code=409, error_code="DEBT_ALREADY_SETTLED", message="This debt is already marked as settled."
            )

        debt.is_settled = True
        debt.settled_at = datetime.now(timezone.utc)
        settled_debt = await self.debt_repository.save(debt)

        generated_transaction = None
        if payload.generate_transaction:
            generated_transaction = await self._generate_settlement_transaction(user_id, settled_debt, payload)

        return DebtSettleResponse(
            debt=self.to_response(settled_debt),
            generated_transaction=(
                TransactionResponse.model_validate(generated_transaction) if generated_transaction else None
            ),
        )

    async def _generate_settlement_transaction(
        self, user_id: int, debt: Debt, payload: DebtSettleRequest
    ) -> Transaction:
        assert self.category_repository and self.payment_method_repository and self.transaction_repository, (
            "DebtService needs category_repository, payment_method_repository, and "
            "transaction_repository to generate a settlement transaction."
        )

        if payload.category_id is None:
            raise AppException(
                status_code=422,
                error_code="VALIDATION_ERROR",
                message="A category is required to generate a transaction for this settlement.",
                field_errors={"category_id": "This field is required when generate_transaction is true."},
            )

        category = await self.category_repository.get_by_id(payload.category_id, user_id)
        if category is None:
            raise AppException(status_code=404, error_code="CATEGORY_NOT_FOUND", message="We couldn't find that category.")

        expected_type = CategoryType.INCOME if debt.direction == DebtDirection.OWED_TO_USER else CategoryType.EXPENSE
        if category.type != expected_type:
            raise AppException(
                status_code=422,
                error_code="VALIDATION_ERROR",
                message=f"Settling this debt needs an {expected_type.value} category.",
                field_errors={"category_id": f"Must be an {expected_type.value} category for this debt's direction."},
            )

        if payload.payment_method_id is not None:
            payment_method = await self.payment_method_repository.get_by_id(payload.payment_method_id, user_id)
            if payment_method is None:
                raise AppException(
                    status_code=404, error_code="PAYMENT_METHOD_NOT_FOUND", message="We couldn't find that payment method."
                )

        transaction = Transaction(
            user_id=user_id,
            category_id=payload.category_id,
            payment_method_id=payload.payment_method_id,
            type=expected_type,
            amount=debt.amount,
            description=f"Debt settled: {debt.person_name}",
            transaction_date=date.today(),
        )
        return await self.transaction_repository.create(transaction)

    async def list_debts(
        self, user_id: int, direction: DebtDirection | None, is_settled: bool | None
    ) -> DebtListResponse:
        debts = await self.debt_repository.list_for_user(user_id, direction, is_settled)

        total_owed_to_user = await self.debt_repository.sum_unsettled_by_direction(user_id, DebtDirection.OWED_TO_USER)
        total_owed_by_user = await self.debt_repository.sum_unsettled_by_direction(user_id, DebtDirection.OWED_BY_USER)

        return DebtListResponse(
            debts=[self.to_response(debt) for debt in debts],
            total_owed_to_user=total_owed_to_user,
            total_owed_by_user=total_owed_by_user,
            count=len(debts),
        )

    async def _get_owned_debt(self, user_id: int, debt_id: int) -> Debt:
        debt = await self.debt_repository.get_by_id(debt_id, user_id)
        if debt is None:
            raise AppException(status_code=404, error_code="DEBT_NOT_FOUND", message="We couldn't find that debt.")
        return debt

    def to_response(self, debt: Debt) -> DebtResponse:
        days_until_due = (debt.due_date - date.today()).days if debt.due_date else None
        return DebtResponse(
            id=debt.id,
            person_name=debt.person_name,
            amount=debt.amount,
            direction=debt.direction,
            due_date=debt.due_date,
            note=debt.note,
            is_settled=debt.is_settled,
            settled_at=debt.settled_at,
            days_until_due=days_until_due,
            client_generated_id=debt.client_generated_id,
            updated_at=debt.updated_at,
        )