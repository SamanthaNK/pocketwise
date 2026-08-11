import enum
from pydantic import BaseModel, Field


class PrivacyModeUpdateRequest(BaseModel):
    enabled: bool


class ProfileUpdateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)


class Currency(str, enum.Enum):
    XAF = "XAF"


class CurrencyUpdateRequest(BaseModel):
    currency: Currency