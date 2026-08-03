from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.core.exceptions import AppException

app = FastAPI(title="PocketWise API", version="0.1.0")

app.include_router(api_router, prefix="/v1")


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "status": "error",
            "errorCode": exc.error_code,
            "message": exc.message,
            "fieldErrors": exc.field_errors,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    field_errors: dict[str, str] = {}
    for error in exc.errors():
        field_name = str(error["loc"][-1])
        field_errors[field_name] = error["msg"]

    return JSONResponse(
        status_code=422,
        content={
            "status": "error",
            "errorCode": "VALIDATION_ERROR",
            "message": "Some fields need your attention.",
            "fieldErrors": field_errors,
        },
    )


@app.get("/health")
async def health_check():
    return {"status": "ok"}