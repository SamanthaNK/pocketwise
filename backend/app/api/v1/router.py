from fastapi import APIRouter

from app.api.v1.auth_router import router as auth_router
from app.api.v1.auth_router import users_router
from app.api.v1.category_router import router as category_router
from app.api.v1.payment_method_router import router as payment_method_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(category_router)
api_router.include_router(payment_method_router)