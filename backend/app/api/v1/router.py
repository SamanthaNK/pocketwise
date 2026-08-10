from fastapi import APIRouter

from app.api.v1.auth_router import router as auth_router
from app.api.v1.auth_router import users_router
from app.api.v1.category_router import router as category_router
from app.api.v1.payment_method_router import router as payment_method_router
from app.api.v1.transaction_router import router as transaction_router
from app.api.v1.budget_router import router as budget_router
from app.api.v1.savings_goal_router import router as savings_goal_router
from app.api.v1.debt_router import router as debt_router
from app.api.v1.analytics_router import router as analytics_router
from app.api.v1.sync_router import router as sync_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(category_router)
api_router.include_router(payment_method_router)
api_router.include_router(transaction_router)
api_router.include_router(budget_router)
api_router.include_router(savings_goal_router)
api_router.include_router(debt_router)
api_router.include_router(analytics_router)
api_router.include_router(sync_router)