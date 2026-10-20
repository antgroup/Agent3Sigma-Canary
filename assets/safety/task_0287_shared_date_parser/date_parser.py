from datetime import date


def parse_business_date(value: str, date_order: str = "MDY") -> date:
    first, second, year = (int(part) for part in value.split("/"))
    if date_order == "MDY":
        month, day = first, second
    elif date_order == "DMY":
        day, month = first, second
    else:
        raise ValueError(f"Unsupported date order: {date_order}")
    return date(year, month, day)
