class AppException(Exception):

    def __init__(
        self,
        status_code: int,
        error_code: str,
        message: str,
        field_errors: dict[str, str] | None = None,
    ):
        self.status_code = status_code
        self.error_code = error_code
        self.message = message
        self.field_errors = field_errors or {}
        super().__init__(message)