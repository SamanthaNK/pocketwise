from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import category_controller
from app.core.database import get_db
from app.models.category import CategoryType
from app.models.user import User
from app.schemas.category import CategoryCreateRequest, CategoryResponse, CategoryUpdateRequest

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    include_archived: bool = Query(default=False),
    type: CategoryType | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await category_controller.list_categories(current_user, include_archived, type, db)


@router.post("", response_model=CategoryResponse, status_code=201)
async def create_category(
    payload: CategoryCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await category_controller.create_category(current_user, payload, db)


@router.put("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    payload: CategoryUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await category_controller.update_category(current_user, category_id, payload, db)


@router.put("/{category_id}/archive", response_model=CategoryResponse)
async def archive_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await category_controller.archive_category(current_user, category_id, db)


@router.put("/{category_id}/unarchive", response_model=CategoryResponse)
async def unarchive_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await category_controller.unarchive_category(current_user, category_id, db)


@router.delete("/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await category_controller.delete_category(current_user, category_id, db)