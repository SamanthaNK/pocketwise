from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import AnalyticsRecommendationsResponse, AnalyticsSummaryResponse, AnalyticsTrendResponse, Granularity
from app.services.analytics_service import AnalyticsService


def _build_service(db: AsyncSession) -> AnalyticsService:
    return AnalyticsService(AnalyticsRepository(db))


async def get_summary(user_id: int, start_date: date, end_date: date, db: AsyncSession) -> AnalyticsSummaryResponse:
    return await _build_service(db).get_summary(user_id, start_date, end_date)


async def get_trend(user_id: int, granularity: Granularity, periods: int, db: AsyncSession) -> AnalyticsTrendResponse:
    return await _build_service(db).get_trend(user_id, granularity, periods)


async def get_recommendations(user_id: int, db: AsyncSession) -> AnalyticsRecommendationsResponse:
    return await _build_service(db).get_recommendations(user_id)