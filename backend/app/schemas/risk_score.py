from pydantic import BaseModel


# ---------------- Risk Score Schemas ----------------
# Placeholder fields for now. This will expand once feature engineering for
# the GBM default model is finalized (Phase 1 of the model roadmap). Deliberately
# excludes any backend-only / PCA-style engineered features -- those never
# belong in a request contract that other platforms integrate against.
class RiskScoreRequest(BaseModel):
    member_id: str
    committee_id: str


class RiskScoreResponse(BaseModel):
    member_id: str
    default_probability: float
    risk_tier: str
