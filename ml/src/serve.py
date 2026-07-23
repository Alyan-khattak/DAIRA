from fastapi import FastAPI
from pydantic import BaseModel

# ---------------- ML Service ----------------
# Runs as its own container, independent from the backend. This is what lets
# us redeploy/retrain models without touching the API layer, and eventually
# scale ML inference separately from request handling.
app = FastAPI(title="Daira ML Service", version="0.1.0")


class PredictRequest(BaseModel):
    member_id: str
    committee_id: str


class PredictResponse(BaseModel):
    member_id: str
    default_probability: float


@app.get("/health")
def health_check():
    return {"status": "ok"}


# ---------------- Predict Endpoint ----------------
# Stub until Phase 1 (LightGBM/XGBoost default model) is trained and pickled
# into ml/models/. The backend's risk_score_service will call this route.
@app.post("/predict", response_model=PredictResponse)
def predict(payload: PredictRequest):
    # TODO: load trained model from ml/models/ and run real inference
    return PredictResponse(member_id=payload.member_id, default_probability=0.0)
