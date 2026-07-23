# Daira

AI-based risk, fraud & underwriting engine for Pakistan's informal committee (ROSCA) economy.

Predicts member default probability, detects fraud/Ponzi patterns, and models group-level
network risk. Goal: a proprietary committee default-outcome dataset + a risk-scoring API
that committee platforms and micro-lenders can license.
___

## Architecture

Three independently deployable services, orchestrated via Docker Compose:

| Service    | Stack                     | Purpose                                             |
|------------|---------------------------|------------------------------------------------------|
| `backend/` | FastAPI                   | Public-facing risk-scoring API, request validation   |
| `ml/`      | FastAPI + scikit-learn/LightGBM | Model training & inference, called internally by backend |
| `frontend/`| TBD                       | Dashboard / integration surface                      |

The backend never imports ML code directly -- it calls the ML service over HTTP. This lets
models be retrained and redeployed without touching the API layer.

### Model roadmap
1. **Phase 1** -- LightGBM/XGBoost baseline for individual member default prediction
2. **Phase 2** -- Rule-based + anomaly detection for fraud/Ponzi structural patterns
3. **Phase 3** -- Graph Neural Network for group-level network risk, once sufficient
   relational data exists
___

## Getting Started

### Prerequisites
- Docker & Docker Compose

### Run locally
```bash
cp .env.example .env
docker compose up --build
```

- Backend API: http://localhost:8000/health
- ML service: http://localhost:8500/health
- Postgres: localhost:5432

### Running backend tests
```bash
docker compose exec backend pytest
```
___

## Project Structure
```
daira/
├── backend/        # FastAPI risk-scoring API
├── ml/             # Data, notebooks, training/inference code, model artifacts
├── frontend/        # (not yet scaffolded)
├── docker-compose.yml
└── BRANCHING.md     # Git workflow conventions
```

See `BRANCHING.md` for the branching strategy and PR conventions.
