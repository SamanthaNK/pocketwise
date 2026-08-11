import csv
import io

from app.core.exceptions import AppException
from app.models.transaction import Transaction
from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionFilters, TransactionRepository
from app.schemas.transaction import TransactionCreateRequest, TransactionListResponse, TransactionUpdateRequest


class TransactionService:
    def __init__(
        self,
        transaction_repository: TransactionRepository,
        category_repository: CategoryRepository,
        payment_method_repository: PaymentMethodRepository,
    ):
        self.transaction_repository = transaction_repository
        self.category_repository = category_repository
        self.payment_method_repository = payment_method_repository

    async def create_transaction(self, user_id: int, payload: TransactionCreateRequest) -> Transaction:
        category = await self._get_owned_active_category(user_id, payload.category_id)
        if payload.payment_method_id is not None:
            await self._get_owned_active_payment_method(user_id, payload.payment_method_id)

        transaction = Transaction(
            user_id=user_id,
            category_id=payload.category_id,
            payment_method_id=payload.payment_method_id,
            type=category.type,
            amount=payload.amount,
            description=payload.description,
            transaction_date=payload.transaction_date,
        )
        return await self.transaction_repository.create(transaction)

    async def update_transaction(
        self, user_id: int, transaction_id: int, payload: TransactionUpdateRequest
    ) -> Transaction:
        transaction = await self._get_owned_transaction(user_id, transaction_id)

        if payload.category_id is not None and payload.category_id != transaction.category_id:
            category = await self._get_owned_active_category(user_id, payload.category_id)
            transaction.category_id = payload.category_id
            transaction.type = category.type

        if payload.clear_payment_method:
            transaction.payment_method_id = None
        elif payload.payment_method_id is not None:
            await self._get_owned_active_payment_method(user_id, payload.payment_method_id)
            transaction.payment_method_id = payload.payment_method_id

        if payload.amount is not None:
            transaction.amount = payload.amount
        if payload.description is not None:
            transaction.description = payload.description
        if payload.transaction_date is not None:
            transaction.transaction_date = payload.transaction_date

        return await self.transaction_repository.save(transaction)

    async def delete_transaction(self, user_id: int, transaction_id: int) -> None:
        transaction = await self._get_owned_transaction(user_id, transaction_id)
        await self.transaction_repository.delete(transaction)

    async def get_transaction(self, user_id: int, transaction_id: int) -> Transaction:
        return await self._get_owned_transaction(user_id, transaction_id)

    async def list_transactions(self, user_id: int, filters: TransactionFilters) -> TransactionListResponse:
        transactions = await self.transaction_repository.list_for_user(user_id, filters)
        total_income, total_expense = await self.transaction_repository.sum_totals_for_user(user_id, filters)

        return TransactionListResponse(
            transactions=transactions,
            total_income=total_income,
            total_expense=total_expense,
            net=total_income - total_expense,
            count=len(transactions),
        )

    async def export_csv(self, user_id: int, filters: TransactionFilters) -> str:
        """FR 4.8 (Could): CSV export, respecting the same filters as the
        regular list. PNG/PDF export are deferred for now."""
        transactions = await self.transaction_repository.list_for_export(user_id, filters)

        categories = await self.category_repository.list_for_user(user_id, include_archived=True)
        payment_methods = await self.payment_method_repository.list_for_user(user_id, include_archived=True)
        category_names = {category.id: category.name for category in categories}
        payment_method_labels = {pm.id: pm.label for pm in payment_methods}

        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(["Date", "Type", "Category", "Payment Method", "Amount (XAF)", "Description"])
        for transaction in transactions:
            writer.writerow([
                transaction.transaction_date.isoformat(),
                transaction.type.value,
                category_names.get(transaction.category_id, "Unknown"),
                payment_method_labels.get(transaction.payment_method_id, "") if transaction.payment_method_id else "",
                str(transaction.amount),
                transaction.description or "",
            ])
        return buffer.getvalue()

    async def _get_owned_transaction(self, user_id: int, transaction_id: int) -> Transaction:
        transaction = await self.transaction_repository.get_by_id(transaction_id, user_id)
        if transaction is None:
            raise AppException(
                status_code=404, error_code="TRANSACTION_NOT_FOUND", message="We couldn't find that transaction."
            )
        return transaction

    async def _get_owned_active_category(self, user_id: int, category_id: int):
        category = await self.category_repository.get_by_id(category_id, user_id)
        if category is None:
            raise AppException(
                status_code=404, error_code="CATEGORY_NOT_FOUND", message="We couldn't find that category."
            )
        if category.is_archived:
            raise AppException(
                status_code=409,
                error_code="CATEGORY_ARCHIVED",
                message="This category is archived, so it can't be used for new transactions.",
            )
        return category

    async def _get_owned_active_payment_method(self, user_id: int, payment_method_id: int):
        payment_method = await self.payment_method_repository.get_by_id(payment_method_id, user_id)
        if payment_method is None:
            raise AppException(
                status_code=404,
                error_code="PAYMENT_METHOD_NOT_FOUND",
                message="We couldn't find that payment method.",
            )
        if payment_method.is_archived:
            raise AppException(
                status_code=409,
                error_code="PAYMENT_METHOD_ARCHIVED",
                message="This payment method is archived, so it can't be used for new transactions.",
            )
        return payment_method