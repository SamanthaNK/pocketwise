from calendar import monthrange
from datetime import date, timedelta
from decimal import Decimal

from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import (
    AnalyticsRecommendationsResponse,
    AnalyticsSummaryResponse,
    AnalyticsTrendResponse,
    CategoryBreakdownItem,
    Granularity,
    RecommendationItem,
    TrendPeriodItem,
)

RECOMMENDATION_THRESHOLD = Decimal("0.20")
MINIMUM_HISTORY_MONTHS = 1
LOOKBACK_MONTHS = 3


class AnalyticsService:
    def __init__(self, analytics_repository: AnalyticsRepository):
        self.analytics_repository = analytics_repository

    async def get_summary(self, user_id: int, start_date: date, end_date: date) -> AnalyticsSummaryResponse:
        total_income, total_expense = await self.analytics_repository.totals_for_range(user_id, start_date, end_date)
        rows = await self.analytics_repository.expense_breakdown_by_category(user_id, start_date, end_date)

        breakdown = [
            CategoryBreakdownItem(
                category_id=category_id,
                category_name=name,
                icon=icon,
                amount=amount,
                percent_of_total=self._percent(amount, total_expense),
            )
            for category_id, name, icon, amount in rows
        ]

        return AnalyticsSummaryResponse(
            start_date=start_date,
            end_date=end_date,
            total_income=total_income,
            total_expense=total_expense,
            net=total_income - total_expense,
            category_breakdown=breakdown,
            top_categories=breakdown[:5],
        )

    async def get_trend(self, user_id: int, granularity: Granularity, periods: int) -> AnalyticsTrendResponse:
        bounds = (
            self._monthly_period_bounds(periods)
            if granularity == "monthly"
            else self._weekly_period_bounds(periods)
        )

        trend_periods: list[TrendPeriodItem] = []
        for label, start, end in bounds:
            total_income, total_expense = await self.analytics_repository.totals_for_range(user_id, start, end)
            trend_periods.append(
                TrendPeriodItem(
                    period_label=label, period_start=start, period_end=end,
                    total_income=total_income, total_expense=total_expense,
                )
            )

        return AnalyticsTrendResponse(granularity=granularity, periods=trend_periods)

    async def get_recommendations(self, user_id: int) -> AnalyticsRecommendationsResponse:
        current_start, current_end = self._month_bounds(date.today())
        current_rows = await self.analytics_repository.expense_breakdown_by_category(
            user_id, current_start, current_end
        )

        monthly_breakdowns: list[dict[int, Decimal]] = []
        for i in range(1, LOOKBACK_MONTHS + 1):
            month_start, month_end = self._month_bounds(self._shift_month(date.today(), -i))
            rows = await self.analytics_repository.expense_breakdown_by_category(user_id, month_start, month_end)
            monthly_breakdowns.append({category_id: amount for category_id, _n, _ic, amount in rows})

        recommendations: list[RecommendationItem] = []
        for category_id, name, _icon, current_amount in current_rows:
            amounts = [breakdown[category_id] for breakdown in monthly_breakdowns if category_id in breakdown]
            if len(amounts) < MINIMUM_HISTORY_MONTHS:
                continue

            average = sum(amounts) / len(amounts)
            if average <= 0:
                continue

            threshold_amount = average * (Decimal("1") + RECOMMENDATION_THRESHOLD)
            if current_amount > threshold_amount:
                percent_above = float((current_amount - average) / average * 100)
                recommendations.append(
                    RecommendationItem(
                        category_id=category_id,
                        category_name=name,
                        message=f"Your {name} spending is running higher than usual this month.",
                        current_amount=current_amount,
                        historical_average=average,
                        percent_above_average=round(percent_above, 1),
                    )
                )

        return AnalyticsRecommendationsResponse(recommendations=recommendations)

    @staticmethod
    def _percent(part: Decimal, whole: Decimal) -> float:
        if whole <= 0:
            return 0.0
        return round(float(part / whole * 100), 1)

    @staticmethod
    def _shift_month(reference: date, offset: int) -> date:
        month_index = reference.month - 1 + offset
        year = reference.year + month_index // 12
        month = month_index % 12 + 1
        return date(year, month, 1)

    @staticmethod
    def _month_bounds(reference: date) -> tuple[date, date]:
        start = reference.replace(day=1)
        last_day = monthrange(reference.year, reference.month)[1]
        return start, reference.replace(day=last_day)

    def _monthly_period_bounds(self, periods: int) -> list[tuple[str, date, date]]:
        today = date.today()
        bounds = []
        for i in range(periods - 1, -1, -1):
            start, end = self._month_bounds(self._shift_month(today, -i))
            bounds.append((start.strftime("%Y-%m"), start, end))
        return bounds

    def _weekly_period_bounds(self, periods: int) -> list[tuple[str, date, date]]:
        today = date.today()
        current_week_start = today - timedelta(days=today.weekday())
        bounds = []
        for i in range(periods - 1, -1, -1):
            start = current_week_start - timedelta(weeks=i)
            end = start + timedelta(days=6)
            label = f"{start.isocalendar()[0]}-W{start.isocalendar()[1]:02d}"
            bounds.append((label, start, end))
        return bounds