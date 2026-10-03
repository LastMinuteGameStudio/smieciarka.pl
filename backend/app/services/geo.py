from sqlalchemy import func


def distance_m_expr(lat: float, lng: float, col_lat, col_lng):
    cos_central_angle = func.least(
        1.0,
        func.greatest(
            -1.0,
            func.cos(func.radians(lat)) * func.cos(func.radians(col_lat))
            * func.cos(func.radians(col_lng) - func.radians(lng))
            + func.sin(func.radians(lat)) * func.sin(func.radians(col_lat)),
        ),
    )
    return 6371000 * func.acos(cos_central_angle)
