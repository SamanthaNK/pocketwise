from app.core.exceptions import AppException
from app.models.transaction import Transaction
from app.repositories.category_repository import CategoryRepository
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse, TransactionSyncItem, TransactionSyncResult
from app.schemas.transaction import TransactionResponse


class SyncService:
    def __init__(
        self,
        transaction_repository: TransactionRepository,
        category_repository: CategoryRepository,
        payment_method_repository: PaymentMethodRepository,
    ):
        self.transaction_repository = transaction_repository
        self.category_repository = category_repository
        self.payment_method_repository = payment_method_repository

    async def sync_batch(self, user_id: int, payload: SyncBatchRequest) -> SyncBatchResponse:
        transaction_results = [
            await self._sync_transaction(user_id, item) for item in payload.transactions
        ]
        return SyncBatchResponse(transactions=transaction_results)

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

        existing = await self.transaction_repository.get_by_client_generated_id(
            item.client_generated_id, user_id
        )

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