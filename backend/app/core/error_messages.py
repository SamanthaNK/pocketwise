"""Translates raw Pydantic validation errors into the app's friendly copy tone."""


def _humanize_field(field: str) -> str:
    label = field.replace("_", " ").strip()
    return label[:1].upper() + label[1:] if label else "This field"


def friendly_field_error(field: str, error: dict) -> str:
    label = _humanize_field(field)
    error_type = error.get("type", "")
    ctx = error.get("ctx") or {}

    if error_type == "missing":
        return f"{label} is required."
    if error_type == "string_too_short":
        min_length = ctx.get("min_length")
        if min_length == 1:
            return f"{label} can't be empty."
        return f"{label} needs to be at least {min_length} characters."
    if error_type == "string_too_long":
        return f"{label} can't be longer than {ctx.get('max_length')} characters."
    if error_type == "greater_than":
        gt = ctx.get("gt")
        return f"{label} needs to be a positive number." if gt == 0 else f"{label} needs to be greater than {gt}."
    if error_type == "less_than":
        return f"{label} needs to be less than {ctx.get('lt')}."
    if error_type in ("int_parsing", "float_parsing", "decimal_parsing", "int_type", "float_type"):
        return f"{label} needs to be a number."
    if error_type == "string_type":
        return f"{label} needs to be text."
    if error_type == "value_error" and "email" in field.lower():
        return "Enter a valid email address."

    return error.get("msg") or f"{label} isn't valid."
