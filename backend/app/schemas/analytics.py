from datetime import date
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel

Granularity = Literal["weekly", "monthly"]


class CategoryBreakdownItem(BaseModel):
    category_id: int
    category_name: str
    icon: str
    amount: Decimal
    percent_of_total: float


class AnalyticsSummaryResponse(BaseModel):
    start_date: date
    end_date: date
    total_income: Decimal
    total_expense: Decimal
    net: Decimal
    category_breakdown: list[CategoryBreakdownItem]
    top_categories: list[CategoryBreakdownItem]


class TrendPeriodItem(BaseModel):
    period_label: str
    period_start: date
    period_end: date
    total_income: Decimal
    total_expense: Decimal


class AnalyticsTrendResponse(BaseModel):
    granularity: Granularity
    periods: list[TrendPeriodItem]


class RecommendationItem(BaseModel):
    category_id: int
    category_name: str
    message: str
    current_amount: Decimal
    historical_average: Decimal
    percent_above_average: float


class AnalyticsRecommendationsResponse(BaseModel):
    recommendations: list[RecommendationItem]