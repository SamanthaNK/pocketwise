from fastapi import FastAPI

from app.api.v1.router import api_router

app = FastAPI(title="PocketWise API", version="0.1.0")

app.include_router(api_router, prefix="/v1")


@app.get("/health")
async def health_check():
    """Basic liveness check — confirms the API process is up."""
    return {"status": "ok"}
