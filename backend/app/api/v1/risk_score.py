from fastapi import APIRouter

from app.schemas.risk_score import RiskScoreRequest, RiskScoreResponse
from app.services.risk_score_service import compute_risk_score

# ---------------- Risk Score Endpoint ----------------
# This route stays thin on purpose: it validates the request via the Pydantic
# schema and delegates all logic to the service layer. The service layer is
# what will eventually call the ML container.
router = APIRouter()


@router.post("/", response_model=RiskScoreResponse)
def get_risk_score(payload: RiskScoreRequest):
    return compute_risk_score(payload)
