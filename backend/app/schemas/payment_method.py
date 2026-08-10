import uuid
from datetime import datetime
from pydantic import BaseModel, Field
from app.models.payment_method import MobileMoneyProvider, PaymentMethodType


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