from fastapi import APIRouter

from app.api.v1 import risk_score

# ---------------- Router Aggregation ----------------
# Individual endpoint modules (risk_score.py, committees.py, members.py, ...)
# stay thin and single-purpose; this file just wires them together under /api/v1.
router = APIRouter()

router.include_router(risk_score.router, prefix="/risk-score", tags=["risk-score"])
