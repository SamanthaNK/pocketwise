from datetime import date

from app.core.exceptions import AppException
from app.models.savings_contribution import SavingsContribution, SavingsContributionType
from app.models.savings_goal import SavingsGoal
from app.repositories.savings_contribution_repository import SavingsContributionRepository
from app.repositories.savings_goal_repository import SavingsGoalRepository
from app.schemas.savings_goal import (
    SavingsContributionCreateRequest,
    SavingsContributionResponse,
    SavingsGoalCreateRequest,
    SavingsGoalResponse,
    SavingsGoalUpdateRequest,
)


class SavingsGoalService:
    def __init__(
        self,
        savings_goal_repository: SavingsGoalRepository,
        savings_contribution_repository: SavingsContributionRepository,
    ):
        self.savings_goal_repository = savings_goal_repository
        self.savings_contribution_repository = savings_contribution_repository

    async def create_goal(self, user_id: int, payload: SavingsGoalCreateRequest) -> SavingsGoal:
        goal = SavingsGoal(
            user_id=user_id,
            name=payload.name,
            target_amount=payload.target_amount,
            target_date=payload.target_date,
        )
        return await self.savings_goal_repository.create(goal)

    async def update_goal(self, user_id: int, goal_id: int, payload: SavingsGoalUpdateRequest) -> SavingsGoal:
        goal = await self._get_owned_goal(user_id, goal_id)

        if payload.name is not None:
            goal.name = payload.name
        if payload.target_amount is not None:
            goal.target_amount = payload.target_amount
        if payload.clear_target_date:
            goal.target_date = None
        elif payload.target_date is not None:
            goal.target_date = payload.target_date

        return await self.savings_goal_repository.save(goal)

    async def delete_goal(self, user_id: int, goal_id: int) -> None:
        goal = await self._get_owned_goal(user_id, goal_id)
        await self.savings_goal_repository.delete(goal)

    async def list_goals(self, user_id: int) -> list[SavingsGoalResponse]:
        goals = await self.savings_goal_repository.list_for_user(user_id)
        return [await self.to_response(goal) for goal in goals]

    async def get_goal(self, user_id: int, goal_id: int) -> SavingsGoalResponse:
        goal = await self._get_owned_goal(user_id, goal_id)
        return await self.to_response(goal)

    async def add_contribution(
        self, user_id: int, goal_id: int, payload: SavingsContributionCreateRequest
    ) -> SavingsContributionResponse:
        await self._get_owned_goal(user_id, goal_id)

        if payload.contribution_type == SavingsContributionType.WITHDRAWAL:
            current_saved = await self.savings_contribution_repository.sum_for_goal(goal_id)
            if payload.amount > current_saved:
                raise AppException(
                    status_code=409,
                    error_code="INSUFFICIENT_SAVED_AMOUNT",
                    message="You can't take out more than you've saved toward this goal.",
                    field_errors={"amount": f"Only {current_saved} XAF is available to take out."},
                )

        contribution = SavingsContribution(
            goal_id=goal_id,
            user_id=user_id,
            amount=payload.amount,
            contribution_type=payload.contribution_type,
            contribution_date=payload.contribution_date,
        )
        created = await self.savings_contribution_repository.create(contribution)
        return SavingsContributionResponse.model_validate(created)

    async def list_contributions(self, user_id: int, goal_id: int) -> list[SavingsContributionResponse]:
        await self._get_owned_goal(user_id, goal_id)
        contributions = await self.savings_contribution_repository.list_for_goal(goal_id, user_id)
        return [SavingsContributionResponse.model_validate(c) for c in contributions]

    async def delete_contribution(self, user_id: int, goal_id: int, contribution_id: int) -> None:
        await self._get_owned_goal(user_id, goal_id)

        contribution = await self.savings_contribution_repository.get_by_id(contribution_id, user_id)
        if contribution is None or contribution.goal_id != goal_id:
            raise AppException(
                status_code=404,
                error_code="CONTRIBUTION_NOT_FOUND",
                message="We couldn't find that contribution.",
            )
        await self.savings_contribution_repository.delete(contribution)

    async def _get_owned_goal(self, user_id: int, goal_id: int) -> SavingsGoal:
        goal = await self.savings_goal_repository.get_by_id(goal_id, user_id)
        if goal is None:
            raise AppException(
                status_code=404, error_code="SAVINGS_GOAL_NOT_FOUND", message="We couldn't find that savings goal."
            )
        return goal

    async def to_response(self, goal: SavingsGoal) -> SavingsGoalResponse:
        saved_amount = await self.savings_contribution_repository.sum_for_goal(goal.id)
        percent_complete = float(saved_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0.0
        is_reached = saved_amount >= goal.target_amount
        days_remaining = (goal.target_date - date.today()).days if goal.target_date else None

        return SavingsGoalResponse(
            id=goal.id,
            name=goal.name,
            target_amount=goal.target_amount,
            target_date=goal.target_date,
            saved_amount=saved_amount,
            percent_complete=round(percent_complete, 1),
            is_reached=is_reached,
            days_remaining=days_remaining,
            client_generated_id=goal.client_generated_id,
            updated_at=goal.updated_at,
        )