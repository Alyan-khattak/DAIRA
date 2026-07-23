from app.schemas.risk_score import RiskScoreRequest, RiskScoreResponse

# ---------------- Risk Score Service ----------------
# This is the seam where backend meets ML. Once the ML service exposes its
# own /predict endpoint, this function will call it over HTTP via
# app.core.config.settings.ML_SERVICE_URL instead of returning a stub value.
# Keeping this indirection from day one means the API route and schema never
# have to change when the model moves from stub -> GBM -> GNN.


def compute_risk_score(payload: RiskScoreRequest) -> RiskScoreResponse:
    # TODO: replace stub with a real HTTP call to the ML service once
    # Phase 1 (GBM default model) is trained and served.
    return RiskScoreResponse(
        member_id=payload.member_id,
        default_probability=0.0,
        risk_tier="unscored",
    )
