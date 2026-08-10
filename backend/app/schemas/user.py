from pydantic import BaseModel


class PrivacyModeUpdateRequest(BaseModel):
    enabled: bool