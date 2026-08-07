from datetime import date, datetime, timezone

from app.core.exceptions import AppException
from app.models.debt import Debt, DebtDirection
from app.repositories.debt_repository import DebtRepository
from app.schemas.debt import DebtCreateRequest, DebtListResponse, DebtResponse


class DebtService:
    def __init__(self, debt_repository: DebtRepository):
        self.debt_repository = debt_repository

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

    async def settle_debt(self, user_id: int, debt_id: int) -> Debt:
        debt = await self._get_owned_debt(user_id, debt_id)
        if debt.is_settled:
            raise AppException(
                status_code=409, error_code="DEBT_ALREADY_SETTLED", message="This debt is already marked as settled."
            )
        debt.is_settled = True
        debt.settled_at = datetime.now(timezone.utc)
        return await self.debt_repository.save(debt)

    async def list_debts(
        self, user_id: int, direction: DebtDirection | None, is_settled: bool | None
    ) -> DebtListResponse:
        debts = await self.debt_repository.list_for_user(user_id, direction, is_settled)

        total_owed_to_user = await self.debt_repository.sum_unsettled_by_direction(
            user_id, DebtDirection.OWED_TO_USER
        )
        total_owed_by_user = await self.debt_repository.sum_unsettled_by_direction(
            user_id, DebtDirection.OWED_BY_USER
        )

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