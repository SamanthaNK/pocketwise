import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.transaction import TransactionResponse


class TransactionSyncItem(BaseModel):
    client_generated_id: uuid.UUID
    category_id: int
    payment_method_id: int | None = None
    amount: Decimal = Field(gt=0)
    description: str | None = Field(default=None, max_length=255)
    transaction_date: date
    updated_at: datetime


class SyncBatchRequest(BaseModel):
    transactions: list[TransactionSyncItem] = Field(default_factory=list)


class TransactionSyncResult(BaseModel):
    client_generated_id: uuid.UUID
    status: Literal["created", "updated", "conflict"]
    # "created"  — didn't exist on the server yet; inserted as-is.
    # "updated"  — existed already, and the DEVICE's copy was newer, so it was applied.
    # "conflict" — existed already, and the SERVER's copy was newer (or tied);
    #              the device's write was rejected. `transaction` below is the
    #              server's current version — the device should overwrite its
    #              local copy with it rather than retrying the write.
    transaction: TransactionResponse


class SyncBatchResponse(BaseModel):
    transactions: list[TransactionSyncResult] = Field(default_factory=list)