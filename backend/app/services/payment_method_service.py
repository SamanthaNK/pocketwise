from app.core.exceptions import AppException
from app.models.payment_method import MobileMoneyProvider, PaymentMethod, PaymentMethodType
from app.repositories.payment_method_repository import PaymentMethodRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.payment_method import PaymentMethodUpdateRequest

DEFAULT_PAYMENT_METHODS: list[dict] = [
    {"type": PaymentMethodType.CASH, "provider": None, "label": "Cash"},
    {"type": PaymentMethodType.MOBILE_MONEY, "provider": MobileMoneyProvider.MTN, "label": "MTN MoMo"},
    {"type": PaymentMethodType.MOBILE_MONEY, "provider": MobileMoneyProvider.ORANGE, "label": "Orange Money"},
    {"type": PaymentMethodType.BANK_CARD, "provider": None, "label": "Bank/Card"},
]


class PaymentMethodService:
    def __init__(self, payment_method_repository: PaymentMethodRepository, transaction_repository: TransactionRepository):
        self.payment_method_repository = payment_method_repository
        self.transaction_repository = transaction_repository

    async def seed_defaults(self, user_id: int) -> None:
        for defaults in DEFAULT_PAYMENT_METHODS:
            payment_method = PaymentMethod(
                user_id=user_id,
                type=defaults["type"],
                provider=defaults["provider"],
                label=defaults["label"],
                is_default=True,
            )
            self.payment_method_repository.db.add(payment_method)
        await self.payment_method_repository.db.commit()

    async def list_payment_methods(self, user_id: int, include_archived: bool) -> list[PaymentMethod]:
        return await self.payment_method_repository.list_for_user(user_id, include_archived)

    async def update_payment_method(
        self, user_id: int, payment_method_id: int, payload: PaymentMethodUpdateRequest
    ) -> PaymentMethod:
        payment_method = await self._get_owned(user_id, payment_method_id)
        payment_method.label = payload.label
        return await self.payment_method_repository.save(payment_method)

    async def archive_payment_method(self, user_id: int, payment_method_id: int) -> PaymentMethod:
        payment_method = await self._get_owned(user_id, payment_method_id)
        await self._block_if_has_transactions(payment_method_id)
        payment_method.is_archived = True
        return await self.payment_method_repository.save(payment_method)

    async def unarchive_payment_method(self, user_id: int, payment_method_id: int) -> PaymentMethod:
        payment_method = await self._get_owned(user_id, payment_method_id)
        payment_method.is_archived = False
        return await self.payment_method_repository.save(payment_method)

    async def _get_owned(self, user_id: int, payment_method_id: int) -> PaymentMethod:
        payment_method = await self.payment_method_repository.get_by_id(payment_method_id, user_id)
        if payment_method is None:
            raise AppException(
                status_code=404,
                error_code="PAYMENT_METHOD_NOT_FOUND",
                message="We couldn't find that payment method.",
            )
        return payment_method

    async def _block_if_has_transactions(self, payment_method_id: int) -> None:
        if await self.transaction_repository.has_transactions_for_payment_method(payment_method_id):
            raise AppException(
                status_code=409,
                error_code="PAYMENT_METHOD_HAS_TRANSACTIONS",
                message="This payment method has transactions linked to it, so it can't be archived.",
            )