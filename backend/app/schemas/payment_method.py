import uuid
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

from app.models.payment_method import MobileMoneyProvider, PaymentMethodType


class PaymentMethodCreateRequest(BaseModel):
    type: PaymentMethodType
    provider: MobileMoneyProvider | None = None
    label: str = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def provider_matches_type(self):
        if self.type == PaymentMethodType.MOBILE_MONEY and self.provider is None:
            raise ValueError("provider is required for mobile_money (MTN or Orange).")
        if self.type != PaymentMethodType.MOBILE_MONEY and self.provider is not None:
            raise ValueError("provider only applies to mobile_money payment methods.")
        return self


class PaymentMethodUpdateRequest(BaseModel):
    label: str = Field(min_length=1, max_length=100)


class PaymentMethodResponse(BaseModel):
    id: int
    type: PaymentMethodType
    provider: MobileMoneyProvider | None
    label: str
    is_default: bool
    is_archived: bool
    client_generated_id: uuid.UUID
    updated_at: datetime

    model_config = {"from_attributes": True}