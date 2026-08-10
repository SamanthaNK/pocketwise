from app.core.exceptions import AppException
from app.models.category import BudgetGroup, Category, CategoryType
from app.repositories.category_repository import CategoryRepository
from app.repositories.transaction_repository import TransactionRepository
from app.schemas.category import CategoryCreateRequest, CategoryUpdateRequest

DEFAULT_CATEGORIES: list[dict] = [
    {"name": "Food", "type": CategoryType.EXPENSE, "icon": "restaurant", "budget_group": BudgetGroup.NEEDS},
    {"name": "Transport", "type": CategoryType.EXPENSE, "icon": "directions_bus", "budget_group": BudgetGroup.NEEDS},
    {"name": "Bills & Utilities", "type": CategoryType.EXPENSE, "icon": "bolt", "budget_group": BudgetGroup.NEEDS},
    {"name": "Rent", "type": CategoryType.EXPENSE, "icon": "home", "budget_group": BudgetGroup.NEEDS},
    {"name": "Airtime & Data", "type": CategoryType.EXPENSE, "icon": "sim_card", "budget_group": BudgetGroup.NEEDS},
    {"name": "Health", "type": CategoryType.EXPENSE, "icon": "medical_services", "budget_group": BudgetGroup.NEEDS},
    {"name": "Education", "type": CategoryType.EXPENSE, "icon": "school", "budget_group": BudgetGroup.NEEDS},
    {"name": "Shopping", "type": CategoryType.EXPENSE, "icon": "shopping_bag", "budget_group": BudgetGroup.WANTS},
    {"name": "Entertainment", "type": CategoryType.EXPENSE, "icon": "celebration", "budget_group": BudgetGroup.WANTS},
    {"name": "Savings & Investments", "type": CategoryType.EXPENSE, "icon": "savings", "budget_group": BudgetGroup.SAVINGS},
    {"name": "Other Expense", "type": CategoryType.EXPENSE, "icon": "category", "budget_group": BudgetGroup.WANTS},
    {"name": "Salary", "type": CategoryType.INCOME, "icon": "payments", "budget_group": None},
    {"name": "Business Income", "type": CategoryType.INCOME, "icon": "storefront", "budget_group": None},
    {"name": "Gifts & Support", "type": CategoryType.INCOME, "icon": "redeem", "budget_group": None},
    {"name": "Other Income", "type": CategoryType.INCOME, "icon": "account_balance_wallet", "budget_group": None},
]


class CategoryService:
    def __init__(self, category_repository: CategoryRepository, transaction_repository: TransactionRepository):
        self.category_repository = category_repository
        self.transaction_repository = transaction_repository

    async def seed_defaults(self, user_id: int) -> None:
        for defaults in DEFAULT_CATEGORIES:
            category = Category(
                user_id=user_id,
                name=defaults["name"],
                type=defaults["type"],
                icon=defaults["icon"],
                budget_group=defaults["budget_group"],
                is_default=True,
            )
            self.category_repository.db.add(category)
        await self.category_repository.db.commit()

    async def list_categories(
        self, user_id: int, include_archived: bool, type_filter: CategoryType | None
    ) -> list[Category]:
        return await self.category_repository.list_for_user(user_id, include_archived, type_filter)

    async def create_category(self, user_id: int, payload: CategoryCreateRequest) -> Category:
        await self._ensure_name_available(user_id, payload.name)
        category = Category(
            user_id=user_id,
            name=payload.name,
            type=payload.type,
            icon=payload.icon,
            budget_group=payload.budget_group,
            is_default=False,
        )
        return await self.category_repository.create(category)

    async def update_category(self, user_id: int, category_id: int, payload: CategoryUpdateRequest) -> Category:
        category = await self._get_owned_category(user_id, category_id)

        if payload.name is not None and payload.name != category.name:
            await self._ensure_name_available(user_id, payload.name, ignore_category_id=category.id)
            category.name = payload.name

        if payload.icon is not None:
            category.icon = payload.icon

        if payload.budget_group is not None:
            if category.type == CategoryType.INCOME:
                raise AppException(
                    status_code=422,
                    error_code="VALIDATION_ERROR",
                    message="Income categories can't belong to a 50/30/20 group.",
                    field_errors={"budget_group": "Only expense categories can have a budget group."},
                )
            category.budget_group = payload.budget_group

        return await self.category_repository.save(category)

    async def archive_category(self, user_id: int, category_id: int) -> Category:
        category = await self._get_owned_category(user_id, category_id)
        await self._block_if_has_transactions(category_id)
        category.is_archived = True
        return await self.category_repository.save(category)

    async def unarchive_category(self, user_id: int, category_id: int) -> Category:
        category = await self._get_owned_category(user_id, category_id)
        category.is_archived = False
        return await self.category_repository.save(category)

    async def delete_category(self, user_id: int, category_id: int) -> None:
        category = await self._get_owned_category(user_id, category_id)
        await self._block_if_has_transactions(category_id)
        await self.category_repository.delete(category)

    async def _get_owned_category(self, user_id: int, category_id: int) -> Category:
        category = await self.category_repository.get_by_id(category_id, user_id)
        if category is None:
            raise AppException(
                status_code=404, error_code="CATEGORY_NOT_FOUND", message="We couldn't find that category."
            )
        return category

    async def _ensure_name_available(self, user_id: int, name: str, ignore_category_id: int | None = None) -> None:
        existing = await self.category_repository.get_by_name(user_id, name)
        if existing is not None and existing.id != ignore_category_id:
            raise AppException(
                status_code=409,
                error_code="CATEGORY_NAME_TAKEN",
                message="You already have a category with this name.",
                field_errors={"name": "This name is already in use."},
            )

    async def _block_if_has_transactions(self, category_id: int) -> None:
        if await self.transaction_repository.has_transactions_for_category(category_id):
            raise AppException(
                status_code=409,
                error_code="CATEGORY_HAS_TRANSACTIONS",
                message="This category has transactions linked to it, so it can't be archived or deleted.",
            )