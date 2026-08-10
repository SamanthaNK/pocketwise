from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import sync_controller
from app.core.database import get_db
from app.models.user import User
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse

router = APIRouter(prefix="/sync", tags=["Sync"])


@router.post("/batch", response_model=SyncBatchResponse)
async def sync_batch(
    payload: SyncBatchRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await sync_controller.sync_batch(current_user.id, payload, db)