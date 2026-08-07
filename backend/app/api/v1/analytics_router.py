from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.controllers import analytics_controller
from app.core.database import get_db
from app.models.user import User
from app.schemas.analytics import AnalyticsRecommendationsResponse, AnalyticsSummaryResponse, AnalyticsTrendResponse, Granularity

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/summary", response_model=AnalyticsSummaryResponse)
async def get_summary(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    resolved_start = start_date or today.replace(day=1)
    resolved_end = end_date or today
    return await analytics_controller.get_summary(current_user.id, resolved_start, resolved_end, db)


@router.get("/trend", response_model=AnalyticsTrendResponse)
async def get_trend(
    granularity: Granularity = Query(default="monthly"),
    periods: int = Query(default=6, ge=1, le=24),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await analytics_controller.get_trend(current_user.id, granularity, periods, db)


@router.get("/recommendations", response_model=AnalyticsRecommendationsResponse)
async def get_recommendations(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    return await analytics_controller.get_recommendations(current_user.id, db)