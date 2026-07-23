from fastapi import FastAPI

from app.api.v1.router import router as api_v1_router
from app.core.config import settings

# ---------------- App Initialization ----------------
# Central FastAPI instance. Routers are versioned (v1) from day one so we can
# introduce breaking changes later (e.g. v2 scoring logic) without breaking
# platforms that have already integrated against v1.
app = FastAPI(
    title="Daira Risk Scoring API",
    description="Risk, fraud, and underwriting engine for Pakistan's informal committee (ROSCA) economy.",
    version="0.1.0",
)

# ---------------- Routes ----------------
app.include_router(api_v1_router, prefix="/api/v1")


# ---------------- Health Check ----------------
# Kept outside versioning since infra/monitoring tools should never have to
# chase a version bump just to check liveness.
@app.get("/health")
def health_check():
    return {"status": "ok", "environment": settings.ENVIRONMENT}
