import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.v1.router import api_router
from app.core.exceptions import AppException

logger = logging.getLogger("pocketwise")

app = FastAPI(title="PocketWise API", version="0.1.0")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/v1")


def _error_envelope(status_code: int, error_code: str, message: str, field_errors: dict | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "error",
            "errorCode": error_code,
            "message": message,
            "fieldErrors": field_errors or {},
        },
    )


@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return _error_envelope(exc.status_code, exc.error_code, exc.message, exc.field_errors)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    field_errors: dict[str, str] = {}
    for error in exc.errors():
        field_name = str(error["loc"][-1])
        field_errors[field_name] = error["msg"]

    return _error_envelope(422, "VALIDATION_ERROR", "Some fields need your attention.", field_errors)


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    error_codes = {401: "UNAUTHORIZED", 403: "FORBIDDEN", 404: "NOT_FOUND", 405: "METHOD_NOT_ALLOWED"}
    error_code = error_codes.get(exc.status_code, "HTTP_ERROR")
    message = exc.detail if isinstance(exc.detail, str) else "Something went wrong."
    return _error_envelope(exc.status_code, error_code, message)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return _error_envelope(500, "INTERNAL_SERVER_ERROR", "Something went wrong on our end. Please try again.")


@app.get("/health")
async def health_check():
    return {"status": "ok"}